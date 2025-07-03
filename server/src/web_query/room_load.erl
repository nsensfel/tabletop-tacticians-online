-module(room_load).

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
		room_id :: ataxia_id:type()
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
		room_id = maps:get(?ROOM_ID_FIELD, Map),
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

%%%% SECURITY CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec authenticate_user (room_action_request:type()) -> ('ok' | 'error').
authenticate_user (Request) ->
	UserID = get_request_user_id(Request),
	SessionToken = get_request_session_token(Request),
	LockJanitor = get_request_lock_janitor(Request),
	case shr_security:credentials_match(LockJanitor, SessionToken, UserID) of
		true -> ok;
		_ -> jiffy:encode([shr_disconnected:generate()])
	end.

-spec fetch_data
	(
		room_action_request:type()
	) -> ({'ok', room_db_entry:type()} | ataxic_error:type()).
fetch_data (Request) ->
	RoomID = get_request_room_id(Request),
	UserID = get_request_user_id(Request),
	LockJanitor = get_request_lock_janitor(Request),
	% We need a write lock, to update the user's history index (and potentially
	% the history itself).
	case ataxia_lock_client:request_write_lock(LockJanitor, room_db, RoomID) of
		{ok, Lock} ->
			case
				ataxia_client:fetch_if
				(
					room_db,
					RoomID,
					Lock,
					room_db_entry:ataxic_is_user_in_room(UserID)
				)
			of
				{ok, RoomVersion, RoomData} ->
					{ok, ataxia_client_data:new(Lock, RoomVersion, RoomData)};

				Error -> {error, Error}
			end;

		Error -> {error, Error}
	end.

release_resources (Request) ->
	ataxia_lock_client:release_all
	(
		get_request_lock_janitor(Request)
	).

generate_reply (UserID, ClientData) ->
	Room = ataxia_client_data:get_value(ClientData),
	UserIX = room_db_entry:user_index_from_user_id(UserID, Room),
	room_db_entry:encode_limited_view(UserIX, Room).

generate_error_reply (_Error) ->
	% TODO: implement,
	ok.

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> binary().
handle (Query) ->
	{ok, Request} = decode_request(Query), % Add lockJanitor in this decode function.
	ok = authenticate_user(Request),
	MaybeData = fetch_data(Request),
	case fetch_data(Request) of
		{ok, Data} ->
			update_data(Data, Request),
			release_resources(Request),
			generate_reply(get_request_user_id(Request), Data);
		{error, Error} ->
			release_resources(Request),
			generate_error_reply(Error)
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
