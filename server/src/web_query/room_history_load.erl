-module(room_history_load).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-record
(
	request,
	{
		dragoman :: dgn_history_load_query:type(),
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
			dragoman = dgn_history_load_query:json_import(Map),
			ataxia_client = ataxia_client:type()
		}
	}.

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_request_ataxia_client (request()) -> ataxia_client:type().
get_request_ataxia_client (#request{ ataxia_client = Result }) -> Result.

-spec set_request_ataxia_client (ataxia_client:type(), request()) -> request().
set_request_ataxia_client (AtaxiaClient, Request) ->
	Request#request{ ataxia_client = AtaxiaClient}.

%%%% Request Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec authenticate_user (request()) ->
	{
		request(),
		({ok, web_reply:type()} | {error, web_reply:type()})
	}.
authenticate_user (Request) ->
	{AtaxiaClient, Result} =
		query_user_management:handle_session
		(
			get_request_ataxia_client(Request),
			dgn_history_load_query:get_credentials(Request#request.dragoman)
		),

	{set_request_ataxia_client(AtaxiaClient, Request), Result}.

-spec fetch_data
(
	{request(), ({ok, web_reply:type()} | {error, web_reply:type()})}
) ->
	{
		request(),
		(
			{ok, ataxia_client_data:type(room_db_entry:type()), web_reply:type()}
			| {error, web_reply:type()}
		)
	}.
fetch_data ({Request, {ok, CurrentReplies}}) ->
	Dragoman = Request#request.dragoman,
	RoomID = dgn_history_load_query:get_room_id(Dragoman),
	UserID =
		dgn_credentials:get_user_id
		(
			dgn_history_load_query:get_credentials(Dragoman)
		),

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
					web_reply:add_fragment
					(
						error_reply:new(ataxia_error:to_string(Error)),
						CurrentReplies
					)
				}
		end
	};
fetch_data (Other) -> Other.

-spec generate_reply
(
	{
		request(),
		(
			{
				ok,
				ataxia_client_data:type(room_db_entry:type()),
				web_reply:type()
			}
			| {error, web_reply:type()}
		)
	}
)
-> web_reply:type().
generate_reply ({Request, {ok, DBData, CurrentReplies}}) ->
	Dragoman = Request#request.dragoman,
	web_reply:add_fragment
	(
		% TODO: Dragoman version of this.
		history_update_reply:new
		(
			dgn_credentials:get_user_id
			(
				dgn_history_load_query:get_credentials
				(
					Dragoman
				)
			),
			dgn_history_load_query:get_history_index(Dragoman),
			ataxia_client_data:get_value(DBData)
		),
		CurrentReplies
	);
generate_reply ({_Request, {error, CurrentReplies}}) -> CurrentReplies.

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> web_reply:type().
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
		web_reply:encode(handle(web_query:new(A)))
	}.
