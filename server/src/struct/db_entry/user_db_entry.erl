-module(user_db_entry).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type id() :: ataxia_id:type().

-record
(
	user,
	{
		username :: binary(),
		% {salt(crypto:strong_rand_bytes(128)), hash(sha384)}
		password :: {binary(), binary()},
		tokens :: ordsets:ordset(binary()), % salt(crypto:strong_rand_bytes(512))
		email :: binary()
	}
).

-opaque type() :: #user{}.

-export_type([type/0, id/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export
(
	[
		new/3
	]
).

%%%% Accessors
-export
(
	[
		get_username/1,
		get_password/1,
		get_token/1,
		get_email/1,

		set_username/2,
		set_password/2,
		add_token/1,
		remove_token/1,
		set_email/2,

		ataxia_set_username/2,
		ataxia_set_password/2,
		ataxia_add_token/1,
		ataxia_remove_token/1,
		ataxia_set_email/2,
	]
).

-export
(
	[
		get_username_field/0,
		get_password_field/0,
		get_tokens_field/0,
		get_email_field/0,
	]
).

-export
(
	[
		password_is/2
	]
).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec secure_value (binary(), binary()) -> binary().
secure_value (Salt, Val) ->
	SaltedVal = erlang:iolist_to_binary([Salt, Val]),
	HashedSaltedVal = crypto:hash(sha384, SaltedVal),

	HashedSaltedVal.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec new (binary(), binary(), binary()) -> type().
new (Username, Password, Email) ->
	Result =
		#user
		{
			username = Username,
			password = {<<"">>, <<"">>},
			tokens = ordsets:new(),
			email = Email
		},

	S0Result = set_password(Password, Result),
	S1Result = add_token(S0Result),
	S2Result = refresh_active(S1Result),

	S2Result.

%%%% Accessors
-spec get_username (type()) -> binary().
get_username (User) -> User#user.username.

-spec get_password (type()) -> {binary(), binary()}.
get_password (User) -> User#user.password.

-spec get_token (type()) -> binary().
get_token (User) -> User#user.token.

-spec get_email (type()) -> binary().
get_email (User) -> User#user.email.

-spec set_username (binary(), type()) -> type().
set_username (Val, User) -> User#user{ username = Val }.

-spec set_password (binary(), type()) -> type().
set_password (Val, User) ->
	NewSalt = crypto:strong_rand_bytes(128),
	HashedSaltedVal = secure_value(NewSalt, Val),

	User#user
	{
		password = {NewSalt, HashedSaltedVal}
	}.

-spec add_token (type()) -> {type(), binary(), boolean()}
add_token (User) ->
	CurrentTokens = User#user.tokens,
	NewToken = base64:encode(crypto:strong_rand_bytes(512)),
	case ordsets:size(User#user.tokens) > ?TOKEN_COUNT_LIMIT of
		true ->
			{
				User#user
				{
					tokens = ordsets:add_element(NewToken, ordsets:new())
				},
				NewToken,
				true
			};

		_ ->
			{
				User#user
				{
					tokens = ordsets:add_element(NewToken, CurrentTokens)
				},
				NewToken,
				false
			}
	end.

-spec ataxia_add_token (type()) -> {ataxic:type(), type(), binary(), boolean()}.
ataxia_add_token (S0User) ->
	{S1User, NewToken, Reset} = add_token(S0User),
	{
		ataxic:update_field
		(
			get_tokens_field(),
			case Reset of
				true -> ataxic:constant(S1User#user.tokens);
				_ ->
					ataxic:apply_function
					(
						ordsets,
						add_element,
						[
							ataxic:current_value(),
							ataxic:constant(NewToken)
						]
					)
			end
		),
		S1User,
		NewToken,
		Reset
	}.

-spec set_email (binary(), type()) -> type().
set_email (Val, User) -> User#user{ email = Val }.

-spec ataxia_set_email (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_email (Val, S0User) ->
	S1User = ataxia_set_email(Val, S0User),
	{
		ataxic:update_field
		(
			get_tokens_field(),
			ataxic:constant(Val)
		),
		S1User
	}.

-spec get_username_field () -> non_neg_integer().
get_username_field () -> #user.username.

-spec get_password_field () -> non_neg_integer().
get_password_field () -> #user.password.

-spec get_tokens_field () -> non_neg_integer().
get_tokens_field () -> #user.tokens.

-spec get_email_field () -> non_neg_integer().
get_email_field () -> #user.email.

-spec password_is (binary(), type()) -> boolean().
password_is (Val, User) ->
	{Salt, HashedSaltedVal} = User#user.password,
	HashedSaltedCandidate = secure_value(Salt, Val),

	(HashedSaltedCandidate == HashedSaltedVal).
