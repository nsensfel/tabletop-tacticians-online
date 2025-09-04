-module(room_history_load).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-include("yaws_api.hrl").

-record
(
	request,
	{
		user_id :: ataxia_id:type(),
		session_token :: binary(),
		lock_janitor :: ataxia_lock_client:janitor(),
		room_id :: ataxia_id:type(),
		history_ix :: non_neg_integer()
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
-spec decode_request (web_query:type()) -> ('error' | {'ok', request()}).
decode_request (Query) ->
	Map = web_query:get_params(Query),
	#request
	{
		user_id = maps:get(?USER_ID_FIELD, Map),
		session_token = maps:get(?SESSION_TOKEN_FIELD, Map),
		user_version = maps:get(?USER_VERSION_FIELD, Map),
		room_id = maps:get(?ROOM_ID_FIELD, Map),
		history_ix = maps:get(?HISTORY_INDEX_FIELD, Map),
		lock_janitor = ataxia_lock_client:new_janitor()
	}.

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_request_user_id (request()) -> ataxia_id:type().
get_request_user_id (#request{ user_id = Result }) -> Result.

-spec get_request_session_token (request()) -> binary().
get_request_session_token (#request{ session_token = Result }) -> Result.

-spec get_request_lock_janitor (request()) -> ataxia_lock_client:janitor().
get_request_lock_janitor (#request{ lock_janitor = Result }) -> Result.

-spec get_request_room_id (request()) -> ataxia_id:type().
get_request_room_id (#request{ room_id = Result }) -> Result.

-spec get_request_history_index (request()) -> non_neg_integer().
get_request_history_index (#request{ history_ix = Result }) -> Result.

%%%% SECURITY CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec authenticate_user (room_action_request:type()) -> ('ok' | 'error').
authenticate_user (Request) ->
	query_user_management:handle_session
	(
		get_request_ataxia_client(Request),
		get_request_user_version(Request),
		get_request_username(Request),
		get_request_session_token(Request)
	);

-spec fetch_data
	(
		room_action_request:type()
	) -> ({'ok', room_db_entry:type()} | ataxic_error:type()).
fetch_data (Request) ->
	RoomID = get_request_room_id(Request),
	UserID = get_request_user_id(Request),
	LockJanitor = get_request_lock_janitor(Request),
	{S1AtaxiaClient, FetchResult} =
		ataxia_client:fetch_if
		(
			S0AtaxiaClient,
			room_db,
			RoomID,
			{temp, read},
			room_db_entry:ataxic_is_user_in_room(UserID)
		),

	{
		S1AtaxiaClient,
		case FetchResult of
			{ok, RoomVersion, RoomData} ->
				{
					ok,
					ataxia_client_data:new
					(
						room_db,
						RoomID,
						none,
						RoomVersion,
						RoomData
					)
				};

			Error -> {error, Error}
		end
	}.

apply_action (Request, S0Data) ->
	UserID = get_request_user_id(Request),
	CurrentHistoryIX = get_request_act(Request),
	S0Room = ataxia_client_data:get_value(S0Data),
	UserIX = room_db_entry:get_user_index(S0Room, UserID),
	UserData = room_db_entry:get_user_data(S0Room, UserIX),
	S0Objects = room_db_entry:get_objects(S0Room),
	CurrentUserHistoryIX = room_user_data:get_current_history_index(UserData),
	Action = room_action:new(UserIX, Act),
	case room_action:ataxia_apply_to(Action, S0Objects) of
			% TODO: update user history index.
			% TODO: trim history.
		{ok, S1Data, CurrentUserHistoryIX} ->
			S1Data =
				ataxia_client_data:add_update(RoomAtaxicUpdate, S1Room, S0Data);

		error -> error
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
		jiffy:encode(handle(web_query:new(A)))
	}.
