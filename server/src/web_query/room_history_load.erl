-module(room_history_load).

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
		history_ix :: non_neg_integer(),
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
			room_id = maps:get(?ROOM_ID_FIELD, Map),
			history_ix = maps:get(?HISTORY_INDEX_FIELD, Map),
			ataxia_client = ataxia_client:type()
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

-spec get_request_history_index (request()) -> non_neg_integer().
get_request_history_index (#request{ history_ix = Result }) -> Result.

-spec get_request_ataxia_client (request()) -> ataxia_client:type().
get_request_ataxia_client (#request{ ataxia_client = Result }) -> Result.

-spec set_request_ataxia_client (ataxia_client:type(), request()) -> request().
set_request_ataxia_client (AtaxiaClient, Request) ->
	Request#request{ ataxia_client = AtaxiaClient}.

%%%% Request Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec authenticate_user (room_action_request:type()) ->
	{
		request(),
		({ok, list(any())} | {error, list(any())})
	}.
authenticate_user (Request) ->
	{AtaxiaClient, Result} =
		query_user_management:handle_session
		(
			get_request_ataxia_client(Request),
			get_request_user_version(Request),
			get_request_user_id(Request),
			get_request_session_token(Request)
		),

	{set_request_ataxia_client(AtaxiaClient, Request), Result}.

-spec fetch_data ({request(), ({ok, list(any())} | {error, list(any())})}) ->
	{
		request(),
		(
			{ok, ataxia_client_data:type(room_db_entry:type()), list(any())}
			| {error, list(any())}
		)
	}.
fetch_data ({Request, {ok, CurrentReplies}}) ->
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
		room_db_entry:set_ataxia_client(AtaxiaClient, Request),
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
					),
					CurrentReplies
				};

			{error, Error} ->
				{
					error,
					[error_reply:new(ataxia_error:to_string(Error)) | CurrentReplies]
				}
		end
	};
fetch_data (Other) -> Other.

-spec generate_reply
	(
		{
			request(),
			(
				{ok, ataxia_client_data:type(room_db_entry:type()), list(any())}
				| {error, list(any())}
			)
		}
	)
	-> list(any()).
generate_reply ({Request, {ok, DBData, CurrentReplies}}) ->
	NewReplies =
		lists:map
		(
			fun add_history_item_reply:new/1,
			room_db_entry:get_history_since
			(
				get_request_history_index(Request),
				ataxia_client_data:get_value(DBData)
			)
		),
	NewReplies ++ CurrentReplies;
generate_reply ({_Request, {error, CurrentReplies}}) -> CurrentReplies.

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> list(any()).
handle (Query) ->
	{ok, Request} = decode_request(Query),
	PostAuthentication = authenticate_user(Request),
	PostDataFetch = fetch_data(PostAuthentication),
	generate_reply(PostDataFetch).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		jiffy:encode(handle(web_query:new(A)))
	}.
