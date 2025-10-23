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
	{
		ok,
		#request
		{
			user_id = maps:get(?USER_ID_FIELD, Map),
			session_token = maps:get(?SESSION_TOKEN_FIELD, Map),
			user_version = maps:get(?USER_VERSION_FIELD, Map),
			ataxia_client = ataxia_client:new(),
			room_id = maps:get(?ROOM_ID_FIELD, Map)
		}
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
fetch_data ({Request, {ok, ServerCmdList}}) ->
	RoomID = get_request_room_id(Request),
	UserID = get_request_user_id(Request),
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

			Error ->
				{
					error,
					web_reply:add_fragment
					(
						error_reply:new(ataxia_error:to_string(Error)),
						ServerCmdList
					)
				}
		end
	};
fetch_data (Error) -> Error.

-spec generate_reply
	(
		{
			request(),
			(
				{
					ok,
					web_reply:type(),
					ataxia_client_data:type(room_db_entry:type())
				}
				| {error, web_reply:type()}
			)
		}
	)
	-> web_reply:type().
generate_reply ({Request, {ok, CurrentReplies, DBEntry}}) ->
	web_reply:add_fragment
	(
		set_room_reply:new
		(
			ataxia_client_data:get_value(DBEntry),
			get_request_user_id(Request)
		),
		CurrentReplies
	);
generate_reply ({_Request, {error, CurrentReplies}}) -> CurrentReplies.


%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> web_reply:type().
handle (Query) ->
	{ok, Request} = decode_request(Query), % Add lockJanitor in this decode function.
	PostUserManagement =	user_management(Request),
	PostFetchData = fetch_data(PostUserManagement),
	generate_reply(PostFetchData).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		web_reply:encode(handle(web_query:new(A)))
	}.
