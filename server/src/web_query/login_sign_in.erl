-module(login_sign_in).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-include("yaws_api.hrl").

-record
(
	request,
	{
		username :: ataxia_id:type(),
		password :: binary(),
		ataxia_client :: ataxia_client:type(),
		lock_janitor :: ataxia_lock_client:janitor()
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
		username = maps:get(?USERNAME_FIELD, Map),
		password = maps:get(?PASSWORD_FIELD, Map),
		ataxia_client = ataxia_client:new(),
		lock_janitor = ataxia_lock_client:new_janitor()
	}.

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_ataxia_client (request()) -> ataxia_id:type().
get_ataxia_client (#request{ ataxia_client = Result }) -> Result.

-spec set_ataxia_client (ataxia_client:type(), request()) -> request().
set_ataxia_client (AtaxiaClient, Request) ->
	Request#request{ ataxia_client = AtaxiaClient }.

-spec get_request_username (request()) -> ataxia_id:type().
get_request_username (#request{ username = Result }) -> Result.

-spec get_request_password (request()) -> binary().
get_request_password (#request{ password = Result }) -> Result.

-spec get_request_lock_janitor (request()) -> ataxia_lock_client:janitor().
get_request_lock_janitor (#request{ lock_janitor = Result }) -> Result.

%%%% SECURITY CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec fetch_data (request()) ->
	(
		{'ok', request(), ataxia_client_data:type()}
		| {'error', binary()}
	).
fetch_data (Request) ->
	Username = get_request_username(Request),
	Password = get_request_password(Request),
	LockJanitor = get_request_lock_janitor(Request),
	S0AtaxiaClient = get_request_ataxia_client(Request),
	{S1AtaxiaClient, FetchResult} =
		ataxia_client:fetch
		(
			S0AtaxiaClient,
			user_db,
			Username,
			{temp, read}
		),
	case FetchResult of
		{error, _} -> {error, ataxia_error:to_string(FetchResult)};
		{ok, Version, User} ->
			{
				ok,
				set_ataxia_client(S1AtaxiaClient, Request),
				ataxia_client_data:new(user_db, Username, none, Version, User)
			}
	end.

-spec update_data (request(), ataxia_client_data:type()) ->
	(
		'ok',
		| {'error', binary()}
	).
update_data (Request, DBData) ->
	Username = get_request_username(Request),
	S0User = ataxia_client_data:get_value(DBData),
	S0AtaxiaClient = get_request_ataxia_client(Request),
	case user_db_entry:password_is(get_request_password(Request), S0User) of
		false -> {false, "Invalid password."}
		true ->
			{S1AtaxiaClient, FetchResult} =
				ataxia_client:fetch
				(
					S0AtaxiaClient,
					user_db,
					Username,
					write
				),
			
	end.

release_resources (Request) ->
	ataxia_lock_client:release_all
	(
		get_request_lock_janitor(Request)
	).

generate_reply (Username, ClientData) ->
	% TODO: implement,
	ok.

generate_error_reply (_Error) ->
	% TODO: implement,
	ok.

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> binary().
handle (Query) ->
	{ok, Request} = decode_request(Query),
	MaybeData = fetch_data(Request),
	case fetch_data(Request) of
		{ok, Data} ->
			update_data(Data, Request),
			release_resources(Request),
			generate_reply(Data);
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
