-module(register_create_account).

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
		displayed_name :: binary(),
		avatar :: binary(),
		email :: binary(),
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
		'ok',
		#request
		{
			username = maps:get(?USER_ID_FIELD, Map),
			password = maps:get(?PASSWORD_FIELD, Map),
			displayed_name = maps:get(?DISPLAYED_NAME_FIELD, Map),
			avatar = maps:get(?AVATAR_FIELD, Map),
			email = maps:get(?EMAIL_FIELD, Map),
			ataxia_client = ataxia_client:new()
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

-spec set_request_displayed_name (binary(), request()) -> binary().
set_request_displayed_name (Name, Request) ->
	Request#request{ displayed_name = Name}.

%%%% Request Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec validate
	(
		atom(),
		({'ok', request()} | {'error', binary()})
	)
	->
	({'ok', request()} | {'error', binary()}).
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
		{true, true, true} -> {ok, Request};
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
		{_, false, _} -> {error, <<"Email too long (128 char max).">>};
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

-spec validate_request (request()) -> ({'ok', request()} | {'error', binary()}).
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
			request()
	)
	->
	(
		{'ok', non_neg_integer(), binary(), binary()}
		| {'error', binary()}
	).
create_new_user (Request) ->
	S0AtaxiaClient = get_request_ataxia_client(Request),
	Username = get_request_username(Request),
	S0User =
		user_db_entry:new
		(
			Username,
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
			S1User
		),

	case AddAtResult of
		{ok, Version} -> {ok, Version, Username, SessionToken};
		{error, _} -> {error, ataxia_error:to_string(AddAtResult)}
	end.

-spec generate_reply
	(
		{'ok', non_neg_integer(), binary(), binary()}
		| {'error', binary()}
	)
	-> list(any()).
generate_reply ({ok, Version, Username, SessionToken}) ->
	[
		set_session_reply:new
		(
			Version,
			Username,
			SessionToken,
			[] % No rooms yet.
		)
	];
generate_reply ({error, ErrorMessage}) ->
	[
		error_reply:new(ErrorMessage)
	].

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (web_query:type()) -> binary().
handle (Query) ->
	{ok, Request} = decode_request(Query),
	ValidateRequestResult = validate_request(Request),
	FetchResult = fetch_data(ValidateRequestResult),
	CreateNewUserResult = create_new_user(FetchResult),
	generate_reply(CreateNewUserResult).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		jiffy:encode(handle(web_query:new(A)))
	}.
