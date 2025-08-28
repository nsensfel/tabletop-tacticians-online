-module(register_create_account).

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
		displayed_name :: binary(),
		avatar :: binary(),
		email :: binary(),
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
			displayed_name = maps:get(?DISPLAYED_NAME_FIELD, Map),
			avatar = maps:get(?AVATAR_FIELD, Map),
			email = maps:get(?EMAIL_FIELD, Map),
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

-spec get_request_email (request()) -> binary().
get_request_email (#request{ email = Result }) -> Result.

-spec get_request_avatar (request()) -> binary().
get_request_avatar (#request{ avatar = Result }) -> Result.

-spec get_request_displayed_name (request()) -> binary().
get_request_displayed_name (#request{ displayed_name = Result }) -> Result.

-spec get_request_lock_janitor (request()) -> ataxia_lock_client:janitor().
get_request_lock_janitor (#request{ lock_janitor = Result }) -> Result.

%%%% SECURITY CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec validate
	(
		atom(),
		({'ok', request()} | {'error', binary()})
	)
	->
	({'ok', request()} | {'error', binary()})).
validate (username, {ok, Request}) ->
	Username = get_request_username(Request),
	Length = string:length(Username),
	case
		{
			Length > 0,
			Length < 33,
			lists:foldl
			(
				fun (Byte, Result) ->
					case Result of
						false -> false;
						_ ->
							(
								((Byte >= 48) and (Byte =< 57)) % it's a digit.
								or ((Byte >= 65) and (Byte =< 90)) % it's a capital letter.
								or ((Byte >= 97) and (Byte =< 122)) % it's a letter.
								or (Byte == 95) % it's a underscore.
							)
					end
				end,
				true,
				binary:bin_to_list(Username)
			)
		}
	of
		{true, true, true} -> {ok, Request}
		{false, _, _} -> {error, <<"Username missing.">>};
		{_, false, _} -> {error, <<"Username is too long (32 char max).">>};
		{_, _, false} ->
			{
				error,
				<<"Invalid letter in username. Only [a-zA-Z0-9_] characters are allowed.">>
			}
	end;
validate (password, {ok, Request}) ->
	Password = get_request_password(Request),
	Length = string:length(Password),
	case { Length > 0, Length < 257 } of
		{true, true} -> {ok, Request};
		{false, _} -> {error, <<"Password missing.">>};
		{_, false} -> {error, <<"Password too long (256 char max).">>}
	end;
validate (email, {ok, Request}) ->
	Email = get_request_email(Request),
	Length = string:length(Email),
	AtCharCount =
		lists:foldl
		(
			fun (Byte, Result) ->
				case (Byte == "@") of
					true -> (Result + 1);
					_ -> Result
				end
			end,
			0,
			binary:bin_to_list(Email)
		),
	case { Length > 0, Length < 129, AtCharCount == 1} of
		{true, true, true} -> {ok, Request};
		{false, _, _} -> {error, <<"Email missing.">>};
		{_, false, _} -> {error, <<"Email too long (128 char max).">>}
		{_, _, false} -> {error, <<"Email syntax invalid.">>}
	end;
validate (displayed_name, {ok, Request}) ->
	S0DisplayedName = get_request_displayed_name(Request),
	S1DisplayedName = string:trim(S0DisplayedName),
	Length = string:length(S1DisplayedName),
	case { Length > 0, Length < 65 } of
		{true, true} ->
			{ok, set_request_displayed_name(S1DisplayedName, Request)};
		{false, _} -> {error, <<"Missing Displayed Name.">>};
		{_, false} -> {error, <<"Displayed Name is too long (max 64 chars).">>}
	end;
validate (avatar, {ok, Request}) ->
	Avatar = get_request_avatar(Request),
	Length = string:length(Avatar),
	case {Length > 0, uri_string:parse(Avatar)} of
		{false, _} -> {error, <<"Avatar missing.">>};
		{_, {error, _, _}} -> {error, <<"Avatar URL invalid.">>};
		_ -> {ok, Request}
	end;
validate (_, Error) -> Error.

-spec validate_request (request()) -> {'ok', request()} | {'error', binary()}).
validate_request (Request) ->
	S0Status = validate(username, {ok, Request}),
	S1Status = validate(password, S0Status),
	S2Status = validate(email, S1Status),
	S3Status = validate(displayed_name, S2Status),
	S4Status = validate(avatar, S3Status),
	S4Status.

-spec fetch_data ({'ok', request()} | {'error', binary()}) ->
	(
		{'ok', request(), ataxia_client_data:type()}
		| {'error', binary()}
	).
fetch_data ({ok, Request}) ->
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
		{error, id} -> {ok, set_request_ataxia_client(S1AtaxiaClient, Request)};
		{error, _} -> {error, ataxia_error:to_string(FetchResult)};
		_ -> {error, <<"Username is already in use.">>}
	end;
fetch_data (Error) -> Error.

-spec create_new_user
	(
		ataxia_lock_janitor:type(),
		ataxia_client:type(),
		request()
	)
	->
	(
		{'ok', non_neg_integer(), binary(), binary()}
		| {'error', binary()}
	).
create_new_user (LockJanitor, S0AtaxiaClient, Request) ->
	S0User =
		user_db_entry:new
		(
			get_request_username(Request),
			get_request_password(Request),
			get_request_email(Request),
			get_request_displayed_name(Request),
			get_request_avatar(Request)
		),

	{S1User, SessionToken} = ataxia_client_data:add_token(S0User),

	{_S1AtaxiaClient, AddAtResult} =
		ataxia_client:add_at
		(
			S0AtaxiaClient,
			user_db,
			Username,
			{temp, write},
			AtaxicUpdate,
			S1User
		),

	case AddAtResult of
		{ok, Version} -> {ok, Version, Username, SessionToken};
		{error, _} -> {error, ataxia_error:to_string(AddAtResult)}
	end.

	ataxia_lock_janitor:release_lock(Lock, LockJanitor),

	case UpdateResult of
		{ok, _NewVersion} -> {ok, SessionToken};
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
update_data ({ok, Request, S0DBData}) ->
	Username = get_request_username(Request),
	LockJanitor = get_request_lock_janitor(Request),
	S0AtaxiaClient = get_request_ataxia_client(Request),
	S0User = ataxia_client_data:get_value(S0DBData),
	S0Version = ataxia_client_data:get_version(S0DBData),
	case user_db_entry:password_is(get_request_password(Request), S0User) of
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

			case FetchResult of
				{ok, Lock} ->
					ataxia_lock_janitor:store_lock(Lock, LockJanitor),
					S1DBData = ataxia_client_data:set_lock(Lock, S0DBData),
					generate_session_token(LockJanitor, S1AtaxiaClient, S1DBData);

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
					generate_session_token(LockJanitor, S1AtaxiaClient, S1DBData);

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
release_resources (_Other) -> ok.

-spec generate_reply
	(
		{'ok', request(), binary()}
		| {'error', binary()}
	)
	-> 'ok'.
generate_reply ({ok, Request, SessionToken}) ->
	{
		[
			{?MESSAGE_FIELD, ?SET_SESSION_ID},
			{?USER_VERSION_FIELD, Version},
			{?USER_ID_FIELD, get_request_username(Request)},
			{?SESSION_TOKEN_FIELD, SessionToken}
		]
	};
generate_reply ({error, ErrorMessage}) ->
	{
		[
			{?MESSAGE_FIELD, ?ERROR_ID},
			{?CATEGORY_FIELD, ?ERROR_ERROR_ID},
			{?CONTENT_FIELD, ErrorMessage}
		]
	}.

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> binary().
handle (Query) ->
	{ok, Request} = decode_request(Query),
	ValidateRequestResult = validate_request(Request),
	FetchResult = fetch_data(ValidateRequestResult),
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
