-module(room_play_action).

-include("protocol.hrl").
-include("actions.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record
(
	request,
	{
		user_id :: ataxia_id:type(),
		session_token :: binary(),
		user_version :: non_neg_integer(),
		lock_janitor :: ataxia_lock_client:janitor(),
		room_id :: ataxia_id:type(),
		act :: act(),
		client_history_ix :: non_neg_integer(),
		ataxia_client :: ataxia_client:type()
	}
).

-type request() :: #request{}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export([out/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec decode_action (map()) -> ('error' | {'ok', act()}).
decode_action (Map) ->
	case maps:get(?ACTION_ID_FIELD, Map) of
		?MOVE_ACTION_ID ->
			{
				ok,
				#move
				{
					object_ids = maps:get(?TARGETS_FIELD, Map),
					offset_x = maps:get(?X_FIELD, Map),
					offset_y = maps:get(?Y_FIELD, Map),
					offset_z = maps:get(?Z_FIELD, Map),
					offset_angle = maps:get(?ANGLE_FIELD, Map)
				}
			};

		?PING_ACTION_ID ->
			{
				ok,
				#ping
				{
					x = maps:get(?X_FIELD, Map),
					y = maps:get(?Y_FIELD, Map)
				}
			};

		?FLIP_ACTION_ID ->
			{
				ok,
				#flip
				{
					object_ids = maps:get(?TARGETS_FIELD, Map)
				}
			};

		_ -> error
	end.

-spec decode_request (web_query:type()) -> ('error' | {'ok', request()}).
decode_request (Query) ->
	Map = web_query:get_params(Query),
	{ok, DecodedAct} = decode_action(maps:get(?ACTION_FIELD, Map)),
	{
		ok,
		#request
		{
			user_id = maps:get(?USER_ID_FIELD, Map),
			session_token = maps:get(?SESSION_TOKEN_FIELD, Map),
			user_version = maps:get(?USER_VERSION_FIELD, Map),
			room_id = maps:get(?ROOM_ID_FIELD, Map),
			act = DecodedAct,
			lock_janitor = ataxia_lock_client:new_janitor(),
			client_history_ix = maps:get(?HISTORY_INDEX_FIELD, Map),
			ataxia_client = ataxia_client:new()
		}
	}.

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_request_user_id (request()) -> ataxia_id:type().
get_request_user_id (#request{ user_id = Result }) -> Result.

-spec get_request_session_token (request()) -> binary().
get_request_session_token (#request{ session_token = Result }) -> Result.

-spec get_request_user_version (request()) -> non_neg_integer().
get_request_user_version (#request{ user_version = Result }) -> Result.

-spec get_request_client_history_ix (request()) -> non_neg_integer().
get_request_client_history_ix (#request{ client_history_ix = Result }) ->
	Result.

-spec get_request_lock_janitor (request()) -> ataxia_lock_client:janitor().
get_request_lock_janitor (#request{ lock_janitor = Result }) -> Result.

-spec get_request_room_id (request()) -> ataxia_id:type().
get_request_room_id (#request{ room_id = Result }) -> Result.

-spec get_request_act (request()) -> act().
get_request_act (#request{ act = Result }) -> Result.

-spec get_request_ataxia_client (request()) -> ataxia_client:type().
get_request_ataxia_client (#request{ ataxia_client = Result }) -> Result.

-spec set_request_ataxia_client (ataxia_client:type(), request()) -> request().
set_request_ataxia_client (Client, Request) ->
	Request#request{ ataxia_client = Client}.

%%%% Request Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec user_management (request()) ->
	{
		request(),
		({ok, web_reply:type()} | {error, web_reply:type()})
	}.
user_management (Request) ->
	{AtaxiaClient, QueryResult} =
		query_user_management:handle_session
		(
			get_request_ataxia_client(Request),
			get_request_user_version(Request),
			get_request_user_id(Request),
			get_request_session_token(Request)
		),
	{set_request_ataxia_client(AtaxiaClient, Request), QueryResult}.

-spec fetch_data
	(
		{
			request(),
			({ok, web_reply:type()} | {error, web_reply:type()})
		}
	)
	->
	{
		request(),
		(
			{ok, web_reply:type(), ataxia_client_data:type(room_db_entry:type())}
			| {error, web_reply:type()}
		)
	}.
fetch_data ({Request, {ok, CurrentReplies}}) ->
	RoomID = get_request_room_id(Request),
	UserID = get_request_user_id(Request),
	LockJanitor = get_request_lock_janitor(Request),
	{AtaxiaClient, FetchResult} =
		ataxia_client:fetch_if
		(
			get_request_ataxia_client(Request),
			room_db,
			RoomID,
			write,
			room_db_entry:ataxic_is_user_in_room(UserID)
		),

	{
		set_request_ataxia_client(AtaxiaClient, Request),
		case FetchResult of
			{ok, Lock, Version, Value} ->
				ataxia_lock_janitor:store_lock(Lock, LockJanitor),
				{
					ok,
					CurrentReplies,
					ataxia_client_data:new(room_db, RoomID, Lock, Version, Value)
				};

			{error, Error} ->
				{
					error,
					[
						error_reply:new(ataxia_error:to_string(Error))
						| CurrentReplies
					]
				}
		end
	};
fetch_data (Other) -> Other.

-spec update_room_db
	(
		request(),
		ataxia_client_data:type(room_db_entry:type())
	)
	->
		{
			request(),
			(
				{ok, ataxia_client_data:type(room_db_entry:type())}
				| {error, web_reply:type()}
			)
		}.
update_room_db (Request, Data) ->
	{ AtaxiaClient, RequestResult } =
		ataxia_client:safe_update(get_request_ataxia_client(Request), Data),

	{
		set_request_ataxia_client(AtaxiaClient, Request),
		case RequestResult of
			{ok, NewVersion} ->
				{
					ok,
					ataxia_client_data:clear_updates
					(
						ataxia_client_data:set_version
						(
							NewVersion,
							Data
						)
					)
				};

			{ok, _NewLock, _NewVersion} ->
				% That should _not_ happen.
				{
					error,
					[
						error_reply:new
						(
							?PROGRAMMING_ERROR_ID,
							<<"Unexpected new lock while playing room action.">>
						)
					]
				};

			{error, Error} ->
				{
					error,
					[ error_reply:new(ataxia_error:to_string(Error)) ]
				}
		end
	}.

% Apply the action... but we don't want to return from this with the Room lock
% still held. Indeed, the action may involve some other DB entry being modified
% (e.g. user ping, lobby modification, end of game), which would mean a second
% write lock (needless risk of interlock).
% So instead, this function handles everything up to the reply (calling other
% functions as needed).
-spec apply_action
	(
		{
			request(),
			(
				{ok, web_reply:type(), ataxia_client_data:type(room_db_entry:type())}
				| {error, web_reply:type()}
			)
		},
		act()
	)
	->
	{
		request(),
		web_reply:type()
	}.
apply_action
(
	{
		Request,
		{error, List}
	},
	_Act
) ->
	{Request, List};
apply_action
(
	{
		S0Request,
		{ ok, CurrentReplies, S0Data }
	},
	Move =
		#move
		{
			object_ids = Targets,
			offset_x = X,
			offset_y = Y,
			offset_z = Z,
			offset_angle = Angle
		}
) ->
	% TODO: check that list is not empty.
	% TODO: check that offset is not nil.
	% TODO: check that objects are still in valid locations.
	S0Room = ataxia_client_data:get_value(S0Data),
	S0Objects = room_db_entry:get_objects(S0Room),
	{ActionStatus, ObjectUpdates, S1Objects} =
		lists:foldl
		(
			fun (ObjectID, {Status, Updates, Objects}) ->
				case maps:find(ObjectID, Objects) of
					{ok, S0Object} ->
						S0Attitude = room_object:get_attitude(S0Object),
						{S0UpdatesList, S1Attitude} =
							case X of
								0 -> {[], S0Attitude};
								_ ->
									NewX = X + room_object:attitude_get_x(S0Attitude),
									{U0, V0} = room_object:ataxia_attitude_set_x(NewX, S0Attitude),
									{[U0], V0}
							end,

						{S1UpdatesList, S2Attitude} =
							case Y of
								0 -> {S0UpdatesList, S1Attitude};
								_ ->
									NewY = Y + room_object:attitude_get_y(S1Attitude),
									{U1, V1} = room_object:ataxia_attitude_set_y(NewY, S1Attitude),
									{[U1|S0UpdatesList], V1}
							end,

						{S2UpdatesList, S3Attitude} =
							case Z of
								0 -> {S1UpdatesList, S2Attitude};
								_ ->
									NewZ = Z + room_object:attitude_get_z(S2Attitude),
									{U2, V2} = room_object:ataxia_attitude_set_z(NewZ, S2Attitude),
									{[U2|S1UpdatesList], V2}
							end,

						{S3UpdatesList, S4Attitude} =
							case Angle of
								0 -> {S2UpdatesList, S3Attitude};
								_ ->
									NewAngle = Angle + room_object:attitude_get_angle(S3Attitude),
									% That one needs to sanitize things...
									{U3, V3} = room_object:ataxia_attitude_set_angle(NewAngle, S3Attitude),
									{[U3|S2UpdatesList], V3}
							end,

						{ObjectUpdate, S1Object} =
							room_object:ataxia_update_attitude
							(
								ataxic:sequence(S3UpdatesList),
								S4Attitude,
								S0Object
							),
						{
							Status,
							[
								ataxic_sugar:update_map_element(ObjectID, ObjectUpdate)
								| Updates
							],
							maps:put(ObjectID, S1Object, Objects)
						};

					_ -> {error, Updates, Objects}
				end
			end,
			{ok, [], S0Objects},
			Targets
		),
	case ActionStatus of
		ok ->
			UserID = get_request_user_id(S0Request),

			{AtaxicUpdate0, S1Room} =
				room_db_entry:ataxia_add_to_history
				(
					room_action:new(UserID, Move),
					ataxia_client_data:get_value(S0Data)
				),

			{AtaxicUpdate1, S2Room} =
				room_db_entry:ataxia_update_objects
				(
					ataxic:sequence(ObjectUpdates),
					S1Objects,
					S1Room
				),

			{AtaxicUpdate2, S3Room} =
				room_db_entry:ataxia_update_user_history_index(UserID, S2Room),

			S1Data =
				ataxia_client_data:add_update
				(
					ataxic:sequence([AtaxicUpdate0, AtaxicUpdate1, AtaxicUpdate2]),
					S3Room,
					S0Data
				),

			{S1Request, DBUpdateResult} = update_room_db(S0Request, S1Data),

			ataxia_lock_janitor:release_lock
			(
				ataxia_client_data:get_lock(S1Data),
				get_request_lock_janitor(S1Request)
			),

			{
				S1Request,
				case DBUpdateResult of
					{ok, _S2Data} ->
						web_reply:add_fragment
						(
							history_update_reply:new
							(
								get_request_user_id(S1Request),
								get_request_client_history_ix(S1Request),
								S3Room
							),
							CurrentReplies
						);

					{error, Errors} -> web_reply:merge(Errors, CurrentReplies)
				end
			};

		error ->
			{
				S0Request,
				web_reply:add_fragment
				(
					error_reply:new(<<"Action failed.">>),
					CurrentReplies
				)
			}
	end;
apply_action
(
	{
		S0Request,
		{ ok, CurrentReplies, S0Data }
	},
	Ping = #ping{}
) ->
	{AtaxicUpdate, UpdatedRoom} =
		room_db_entry:ataxia_add_to_history
		(
			room_action:new(get_request_user_id(S0Request), Ping),
			ataxia_client_data:get_value(S0Data)
		),

	S1Data =
		ataxia_client_data:add_update
		(
			AtaxicUpdate,
			UpdatedRoom,
			S0Data
		),

	{S1Request, DBUpdateResult} = update_room_db(S0Request, S1Data),

	ataxia_lock_janitor:release_lock
	(
		ataxia_client_data:get_lock(S1Data),
		get_request_lock_janitor(S1Request)
	),

	{
		S1Request,
		case DBUpdateResult of
			{ok, _S2Data} ->
				web_reply:add_fragment
				(
					history_update_reply:new
					(
						get_request_user_id(S1Request),
						get_request_client_history_ix(S1Request),
						UpdatedRoom
					),
					CurrentReplies
				);

			{error, Errors} -> (Errors ++ CurrentReplies)
		end
	}.

-spec release_resources ({ request(), web_reply:type() }) -> web_reply:type().
release_resources ({ Request, Replies }) ->
	ataxia_lock_client:release_all(get_request_lock_janitor(Request)),
	Replies.

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> web_reply:type().
handle (Query) ->
	{ok, S0Request} = decode_request(Query),
	release_resources
	(
		apply_action
		(
			fetch_data(user_management(S0Request)),
			get_request_act(S0Request)
		)
	).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		web_reply:encode(handle(web_query:new(A)))
	}.
