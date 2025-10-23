-module(login_sign_in).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
	{
		'ok',
		#request
		{
			username = maps:get(?USER_ID_FIELD, Map),
			password = maps:get(?PASSWORD_FIELD, Map),
			ataxia_client = ataxia_client:new(),
			lock_janitor = ataxia_lock_client:new_janitor()
		}
	}.

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_request_ataxia_client (request()) -> ataxia_id:type().
get_request_ataxia_client (#request{ ataxia_client = Result }) -> Result.

-spec set_request_ataxia_client (ataxia_client:type(), request()) -> request().
set_request_ataxia_client (AtaxiaClient, Request) ->
	Request#request{ ataxia_client = AtaxiaClient }.

-spec get_request_username (request()) -> ataxia_id:type().
get_request_username (#request{ username = Result }) -> Result.

-spec get_request_password (request()) -> binary().
get_request_password (#request{ password = Result }) -> Result.

-spec get_request_lock_janitor (request()) -> ataxia_lock_client:janitor().
get_request_lock_janitor (#request{ lock_janitor = Result }) -> Result.

%%%% Request Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec fetch_data (request()) ->
	(
		{'ok', request(), ataxia_client_data:type()}
		| {'error', binary()}
	).
fetch_data (Request) ->
	Username = get_request_username(Request),
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
				set_request_ataxia_client(S1AtaxiaClient, Request),
				ataxia_client_data:new(user_db, Username, none, Version, User)
			}
	end.

-spec generate_session_token
	(
		request(),
		ataxia_client_data:type()
	)
	->
	(
		{'ok', request(), binary()}
		| {'error', binary()}
	).
generate_session_token(S0Request, S0DBData) ->
	LockJanitor = get_request_lock_janitor(S0Request),
	S0AtaxiaClient = get_request_ataxia_client(S0Request),
	S0User = ataxia_client_data:get_value(S0DBData),
	{AtaxicUpdate, S1User, SessionToken} =
		user_db_entry:ataxia_add_token(S0User),

	S1DBData = ataxia_client_data:add_update(AtaxicUpdate, S1User, S0DBData),

	{S1AtaxiaClient, UpdateResult} =
		ataxia_client:safe_update(S0AtaxiaClient, S1DBData),

	S1Request = set_request_ataxia_client(S1AtaxiaClient, S0Request),

	ataxia_lock_janitor:release_lock
	(
		ataxia_client_data:get_lock(S1DBData),
		LockJanitor
	),

	case UpdateResult of
		{ok, _NewVersion} -> {ok, S1Request, SessionToken};
		{error, _} -> {error, ataxia_error:to_string(UpdateResult)}
	end.

-spec update_data
	(
		{'ok', request(), ataxia_client_data:type()}
		| {'error', binary()}
	)
	->
	(
		{'ok', request(), binary()}
		| {'error', binary()}
	).
update_data ({ok, S0Request, S0DBData}) ->
	Username = get_request_username(S0Request),
	LockJanitor = get_request_lock_janitor(S0Request),
	S0AtaxiaClient = get_request_ataxia_client(S0Request),
	S0User = ataxia_client_data:get_value(S0DBData),
	S0Version = ataxia_client_data:get_version(S0DBData),
	case user_db_entry:password_is(get_request_password(S0Request), S0User) of
		false -> {error, "Invalid password."};
		true ->
			{S1AtaxiaClient, FetchResult} =
				ataxia_client:fetch_if_new
				(
					S0AtaxiaClient,
					user_db,
					Username,
					write,
					S0Version,
					S0User
				),
			S1Request = set_request_ataxia_client(S1AtaxiaClient, S0Request),

			case FetchResult of
				{ok, Lock} ->
					ataxia_lock_janitor:store_lock(Lock, LockJanitor),
					S1DBData = ataxia_client_data:set_lock(Lock, S0DBData),
					generate_session_token(S1Request, S1DBData);

				{ok, Lock, S1Version, S1User} ->
					ataxia_lock_janitor:store_lock(Lock, LockJanitor),
					S1DBData =
						ataxia_client_data:update_to
						(
							Lock,
							S1Version,
							S1User,
							S0DBData
						),
					generate_session_token(S1Request, S1DBData);

				{error, _} ->
					ataxia_lock_janitor:release_all(LockJanitor),
					{error, ataxia_error:to_string(FetchResult)}
			end
	end;
update_data (Error) -> Error.

-spec release_resources
	(
		{'ok', request(), binary()}
		| {'error', binary()}
	)
	-> 'ok'.
release_resources ({ok, Request, _}) ->
	ataxia_lock_janitor:release_all(get_request_lock_janitor(Request)),
	ok;
release_resources ({error, _Other}) -> ok.

-spec generate_reply
	(
		{'ok', ataxia_client_data:type(), binary()}
		| {'error', binary()}
	)
	-> web_reply:type().
generate_reply ({ok, DBEntry, SessionToken}) ->
	User = ataxia_client_data:get_value(DBEntry),
	web_reply:new
	(
		set_session_reply:new
		(
			ataxia_client_data:get_version(DBEntry),
			user_db_entry:get_username(User),
			SessionToken,
			user_db_entry:get_pending_room_list(User)
		)
	);
generate_reply ({error, ErrorMessage}) ->
	web_reply:new(error_reply:new(ErrorMessage)).

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> web_reply:type().
handle (Query) ->
	{ok, Request} = decode_request(Query),
	FetchResult = fetch_data(Request),
	UpdateResult = update_data(FetchResult),
	release_resources(UpdateResult),
	generate_reply(UpdateResult).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		jiffy:encode(handle(web_query:new(A)))
	}.
