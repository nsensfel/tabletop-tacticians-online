-module(room_play_action).

-include("protocol.hrl").

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
		act :: room_action:act(),
		client_history_ix :: non_neg_integer()
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
-spec decode_action (map()) -> ('error' | {'ok', room_action:act()}).
decode_action (Map) ->
	case maps:get(?ACTION_ID_FIELD, Map) of
		?FLIP_ACTION_ID -> {ok, room_action:new_flip(maps:get(?TARGETS_FIELD))};
		_ -> error
	end.

-spec decode_request (web_query:type()) -> ('error' | {'ok', request()}).
decode_request (Query) ->
	Map = web_query:get_params(Query),
	{ok, DecodedAct} = decode_action(maps:get(?ACTION_FIELD, Map)),
	#request
	{
		user_id = maps:get(?USER_ID_FIELD, Map),
		session_token = maps:get(?SESSION_TOKEN_FIELD, Map),
		user_version = maps:get(?USER_VERION_FIELD, Map),
		room_id = maps:get(?ROOM_ID_FIELD, Map),
		act = DecodedAct,
		lock_janitor = ataxia_lock_client:new_janitor()
	}.

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_request_user_id (request()) -> ataxia_id:type().
get_request_user_id (#request{ user_id = Result }) -> Result.

-spec get_request_session_token (request()) -> binary().
get_request_session_token (#request{ session_token = Result }) -> Result.

-spec get_request_user_version (request()) -> non_neg_integer().
get_request_user_version (#request{ user_version = Result }) -> Result.

-spec get_request_lock_janitor (request()) -> ataxia_lock_client:janitor().
get_request_lock_janitor (#request{ lock_janitor = Result }) -> Result.

-spec get_request_room_id (request()) -> ataxia_id:type().
get_request_room_id (#request{ room_id = Result }) -> Result.

-spec get_request_act (request()) -> room_action:act().
get_request_act (#request{ act = Result }) -> Result.

%%%% Request Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec user_management (request()) ->
	{
		request(),
		({ok, list(any())} | {error, list(any())})
	}.
user_management (Request) ->
	{AtaxiaClient, QueryResult} =
		query_user_management:handle
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
			({ok, list(any())} | {error, list(any())})
		}
	)
	->
	{
		request(),
		(
			{ok, list(any()), ataxia_client_data:type(room_db_entry:type())}
			| {error, list(any())}
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

-spec apply_action
	(
		{
			request(),
			(
				{ok, list(any()), ataxia_client_data:type(room_db_entry:type())}
				| {error, list(any())}
			)
		}
	)
	->
	{
		request(),
		(
			{ok, list(any()), ataxia_client_data:type(room_db_entry:type())}
			| {error, list(any())}
		)
	}.
apply_action ({error, List}) -> {error, List};
apply_action
(
	{
		ok,
		CurrentReplies,
		Request,
		S0Data,
		?PING_ACTION_ID
	}
) ->
	{error, List};
apply_action
(
	{
		ok,
		CurrentReplies,
		Request,
		S0Data,
		?PING_ACTION_ID
	}
) ->
	{error, List};

apply_action ({Request, {ok, ServerReplies, S0Data}}) ->
	UserID = get_request_user_id(Request),
	Act = get_request_act(Request),
	S0Room = ataxia_client_data:get_value(S0Data),
	UserIX = room_db_entry:get_user_index(S0Room, UserID),
	UserData = room_db_entry:get_user_data(S0Room, UserIX),
	Action = room_action:new(UserIX, Act),

	% Actions can affect Lobby, Users, Chat, and room objects.
	% How do you handle a ping? It affects more than just the room...
	% Where are we handling all the cases? This module? Another?
	case room_action:ataxia_apply_to(Action, S0Room) of
		{ok, RoomAtaxicUpdate, S1Room} ->
			HistoryView = room_db_entry:get_history_for(UserIX, S2Room),
			{RoomAtaxicUpdate1, S2Room} =
				room_db_entry:ataxia_update_user_history_index(UserIX, S2Room),

			S1Data =
				ataxia_client_data:add_update
				(
					ataxic:sequence
					(
						[RoomAtaxicUpdate0, RoomAtaxicUpdate1, RoomAtaxicUpdate2]
					),
					S3Room,
					S0Data
				),

			{Request, {ok, S1Data};

		{error, ErrorMsg} ->
			{
				Request,
				{error, [error_reply:new(ErrorMsg) | ServerReplies]}
			}
	end.

update_database (ClientData) ->
	case
		ataxia_client:safe_update
		(
			ataxia_client_data:get_database(ClientData),
			ataxia_client_data:get_id(ClientData),
			ataxia_client_data:get_lock(ClientData),
			ataxia_client_data:get_ataxic(ClientData),
			ataxia_client_data:get_version(ClientData),
			ataxia_client_data:get_value(ClientData)
		)
	of
		{ok, _NewVersion} -> ok;
		{error, Error} -> {error, Error}
	end.

release_resources (Request) ->
	ataxia_lock_client:release_all
	(
		get_request_lock_janitor(Request)
	).

generate_reply (_ClientData, PreviousUserHistoryIX) ->
	lists:map
	(
		fun room_action:encode/1,
		room_db_entry:get_history_from(PreviousUserHistoryIX)
	).

generate_error_reply (_Error) -> <<"Error.">>.

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> binary().
handle (Query) ->
	{ok, Request} = decode_request(Query), % Add lockJanitor in this decode function.
	ok = authenticate_user(Request),
	{ok, S0Data} = fetch_data(Request),
	case apply_action(Request, S0Data) of
		{ok, S1Data, PreviousUserHistoryIX} ->
			ok = update_database(S1Data),
			release_resources(Request),
			generate_reply(S1Data, PreviousUserHistoryIX);

		error ->
			release_resources(Request),
			generate_error_reply("Invalid action.")
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		handle(web_query:new(A))
	}.
