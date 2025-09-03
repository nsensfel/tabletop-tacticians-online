-module(user_db_entry).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type id() :: ataxia_id:type().

-define(TOKEN_COUNT_LIMIT, 10).

-record
(
	room,
	{
		id :: ataxia_id:type(),
		game_id :: ataxia_id:type(),
		name :: binary(),
		is_pending :: boolean()
	}
).

-type room() :: #room{}.

-record
(
	user,
	{
		username :: binary(), % This is also the ID.
		% {salt(crypto:strong_rand_bytes(128)), hash(sha384)}
		password :: {binary(), binary()},
		tokens :: ordsets:ordset(binary()), % salt(crypto:strong_rand_bytes(512))
		email :: binary(),
		displayed_name :: binary(),
		avatar :: binary(),
		room_list :: #{ataxia_id:type() => room()}
	}
).

-opaque type() :: #user{}.

-export_type([type/0, id/0, room/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export
(
	[
		new/5
	]
).

%%%% Accessors
-export
(
	[
		get_username/1,
		get_password/1,
		get_email/1,
		get_displayed_name/1,
		get_avatar/1,
		get_room_list/1,
		get_pending_room_list/1,

		add_token/1,

		ataxia_set_displayed_name/2,
		ataxia_set_avatar/2,
		ataxia_set_password/2,
		ataxia_add_token/1,
		ataxia_remove_token/2,
		ataxia_set_email/2
	]
).

-export
(
	[
		get_username_field/0,
		get_password_field/0,
		get_tokens_field/0,
		get_email_field/0,
		get_avatar_field/0,
		get_displayed_name_field/0,
		get_room_list_field/0
	]
).

-export
(
	[
		room_get_id/1,
		room_get_game_id/1,
		room_get_name/1,
		room_get_is_pending/1
	]
).

-export
(
	[
		room_get_id_field/0,
		room_get_game_id_field/0,
		room_get_name_field/0,
		room_get_is_pending_field/0
	]
).

-export
(
	[
		password_is/2,
		has_session_token/2
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
-spec new
	(
		binary(),
		binary(),
		binary(),
		binary(),
		binary()
	)
	-> type().
new (Username, Password, Email, DisplayedName, Avatar) ->
	Result =
		#user
		{
			username = Username,
			password = {<<"">>, <<"">>},
			tokens = ordsets:new(),
			email = Email,
			displayed_name = DisplayedName,
			avatar = Avatar
		},

	set_password(Password, Result).

%%%% Accessors
-spec get_username (type()) -> binary().
get_username (User) -> User#user.username.

-spec get_password (type()) -> {binary(), binary()}.
get_password (User) -> User#user.password.

-spec get_email (type()) -> binary().
get_email (User) -> User#user.email.

-spec get_displayed_name (type()) -> binary().
get_displayed_name (User) -> User#user.displayed_name.

-spec get_avatar (type()) -> binary().
get_avatar (User) -> User#user.avatar.

-spec get_room_list (type()) -> #{ ataxia_id:type() => room() }.
get_room_list (User) -> User#user.room_list.

-spec get_pending_room_list (type()) -> list(room()).
get_pending_room_list (User) ->
	lists:filter
	(
		fun (Room) -> Room#room.is_pending end,
		maps:values(User#user.room_list)
	).

-spec set_password (binary(), type()) -> type().
set_password (Val, User) ->
	NewSalt = crypto:strong_rand_bytes(128),
	HashedSaltedVal = secure_value(NewSalt, Val),

	User#user
	{
		password = {NewSalt, HashedSaltedVal}
	}.

-spec ataxia_set_password (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_password (Val, S0User) ->
	S1User = set_password(Val, S0User),
	{
		ataxic:update_field
		(
			get_tokens_field(),
			ataxic:constant(Val)
		),
		S1User
	}.

-spec add_token (type()) -> {type(), binary()}.
add_token (User) ->
	CurrentTokens = User#user.tokens,
	NewToken = base64:encode(crypto:strong_rand_bytes(512)),
	TokensList =
		case ordsets:size(CurrentTokens) == ?TOKEN_COUNT_LIMIT of
			false -> ordsets:add_element(NewToken, CurrentTokens);
			true ->
				ordsets:del_element
				(
					lists:last(ordsets:to_list(CurrentTokens)),
					CurrentTokens
				)
		end,
	{ User#user{ tokens = TokensList }, NewToken }.

-spec ataxia_add_token (type()) -> {ataxic:type(), type(), binary()}.
ataxia_add_token (S0User) ->
	{S1User, NewToken} = add_token(S0User),
	{
		ataxic:update_field
		(
			get_tokens_field(),
			ataxic:constant(S1User#user.tokens)
		),
		S1User,
		NewToken
	}.

-spec ataxia_remove_token (binary(), type()) -> {ataxic:type(), type()}.
ataxia_remove_token (Token, S0User) ->
	S1User =
		S0User#user{ tokens = ordset:del_element(Token, S0User#user.tokens) },
	{
		ataxic:update_field
		(
			get_tokens_field(),
			ataxic:apply_function
			(
				ordsets,
				del_element,
				[
					ataxic:constant(Token),
					ataxic:current_value()
				]
			)
		),
		S1User
	}.

-spec ataxia_set_email (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_email (Val, S0User) ->
	S1User = S0User#user{ email = Val},
	{
		ataxic:update_field
		(
			get_email_field(),
			ataxic:constant(Val)
		),
		S1User
	}.

-spec ataxia_set_displayed_name (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_displayed_name (Val, S0User) ->
	S1User = S0User#user{ displayed_name = Val},
	{
		ataxic:update_field
		(
			get_displayed_name_field(),
			ataxic:constant(Val)
		),
		S1User
	}.

-spec ataxia_set_avatar (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_avatar (Val, S0User) ->
	S1User = S0User#user{ avatar = Val},
	{
		ataxic:update_field
		(
			get_avatar_field(),
			ataxic:constant(Val)
		),
		S1User
	}.

-spec room_get_name (room()) -> binary().
room_get_name (#room{ name = Result }) -> Result.

-spec room_get_id (room()) -> ataxia_id:type().
room_get_id (#room{ id = Result }) -> Result.

-spec room_get_is_pending (room()) -> boolean().
room_get_is_pending (#room{ is_pending = Result }) -> Result.

-spec room_get_game_id (room()) -> ataxia_id:type().
room_get_game_id (#room{ game_id = Result }) -> Result.

-spec get_username_field () -> non_neg_integer().
get_username_field () -> #user.username.

-spec get_password_field () -> non_neg_integer().
get_password_field () -> #user.password.

-spec get_tokens_field () -> non_neg_integer().
get_tokens_field () -> #user.tokens.

-spec get_email_field () -> non_neg_integer().
get_email_field () -> #user.email.

-spec get_displayed_name_field () -> non_neg_integer().
get_displayed_name_field () -> #user.displayed_name.

-spec get_avatar_field () -> non_neg_integer().
get_avatar_field () -> #user.avatar.

-spec get_room_list_field () -> non_neg_integer().
get_room_list_field () -> #user.room_list.

-spec room_get_id_field () -> non_neg_integer().
room_get_id_field () -> #room.id.

-spec room_get_game_id_field () -> non_neg_integer().
room_get_game_id_field () -> #room.game_id.

-spec room_get_name_field () -> non_neg_integer().
room_get_name_field () -> #room.name.

-spec room_get_is_pending_field () -> non_neg_integer().
room_get_is_pending_field () -> #room.is_pending.

-spec password_is (binary(), type()) -> boolean().
password_is (Val, User) ->
	{Salt, HashedSaltedVal} = User#user.password,
	HashedSaltedCandidate = secure_value(Salt, Val),

	(HashedSaltedCandidate == HashedSaltedVal).

-spec has_session_token (binary(), type()) -> boolean().
has_session_token (Val, User) -> ordset:is_element(Val, User#user.tokens).
