-module(room_load).

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
		ataxia_client :: ataxia_client:type(),
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
		user_version = maps:get(?USER_VERSION_FIELD, Map),
		ataxia_client = ataxia_client:new(),
		room_id = maps:get(?ROOM_ID_FIELD, Map),
	}.

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_request_user_id (request()) -> ataxia_id:type().
get_request_user_id (#request{ user_id = Result }) -> Result.

-spec get_request_session_token (request()) -> binary().
get_request_session_token (#request{ session_token = Result }) -> Result.

-spec get_request_user_version (request()) -> non_neg_integer().
get_request_user_version (#request{ user_version = Result }) -> Result.

-spec get_request_room_id (request()) -> ataxia_id:type().
get_request_room_id (#request{ room_id = Result }) -> Result.

-spec get_request_ataxia_client (request()) -> ataxia_client:type().
get_request_ataxia_client (#request{ ataxia_client = Result }) -> Result.

-spec set_request_ataxia_client
	(
		ataxia_client:type(),
		request()
	)
	-> ataxia_client:type().
set_request_ataxia_client (AtaxiaClient, Request) ->
	Request#request{ ataxia_client = AtaxiaClient }.

-spec user_management (request()) ->
	{
		request(),
		({ok, list(any())} | {error, binary()})
	}.
user_management (Request) ->
	{AtaxiaClient, QueryResult} =
		query_user_management
		(
			get_request_ataxia_client(Request),
			get_request_user_version(Request),
			get_request_user_id(Request),
			get_request_session_token(Request)
		),
	{set_request_ataxia_client(AtaxiaClient, Request, QueryResult}.

-spec fetch_data
	(
		{
			request(),
			({ok, list(any())} | {error, binary()})
		}
	)
	->
	{
		request(),
		({ok, list(any()), ataxia_client_data:type()} | {error, binary()})
	}.
fetch_data ({Request, {ok, ServerCmdList}}) ->
	RoomID = get_request_room_id(Request),
	UserID = get_request_user_id(Request),
	LockJanitor = get_request_lock_janitor(Request),
	% We need a write lock, to update the user's history index (and potentially
	% the history itself).
	% Nevermind: just load here. They can trigger an action to update their
	% history index (let's add a special action for this).
	{AtaxiaClient, FetchResult} =
		ataxia_client:fetch_if
		(
			get_request_ataxia_client(Request),
			room_db,
			RoomID,
			{temp, read},
			room_db_entry:ataxic_is_user_in_room(UserID)
		),

	{
		set_request_ataxia_client(AtaxiaClient, Request),
		case FetchResult of
			{ok, RoomVersion, RoomData} ->
				{
					ok,
					ServerCmdList,
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
	};
fetch_data (Error) -> Error.

-spec process
	(
		{
			request(),
			({ok, list(any()), ataxia_client_data:type()} | {error, binary()}),
		}
	)
	->
	{
		request(),
		({ok, list(any())} | {error, binary()})
	}.
process ({Request, {ok, CmdList, ClientData}}) ->
	Room = ataxia_client_data:get_value(ClientData),
	HistoryList =
		room_db_entry:get_history_for
		(
			get_request_username(Request),
			Room
		),

	{
		[
			{?MESSAGE_FIELD, ?ROOM_DATA_REPLY_ID},
			{?ROOM_NAME_FIELD, room_db_entry:get_name(Room)},
			{?ROOM_GAME_ID_FIELD, room_db_entry:get_game_id(Room)},
			{
				?OBJECTS_FIELD,
				lists:map
				(
					fun encode_object/1,
					maps:to_list(room_db_entry:get_objects(Room))
				),
			},
			{
				?HISTORY_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_history(Room)
				)
			},
			{
				% We need a way to easily update this. Is that an action?
				?LOBBY_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_history(Room)
				)
			},
			{
				?CHAT_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_history(Room)
				)
			},
			{
				?USERS_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_history(Room)
				)
			}
		]
	};
process (Error) -> Error.

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
	PostUserManagement =	user_management(Request),
	PostFetchData = fetch_data(PostUserManagement),
	PostProcessing = process(PostFetchData),
	generate_reply(PostProcessing).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		handle(web_query:new(A))
	}.
