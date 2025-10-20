-module(room_user).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record
(
	room_user,
	{
		color :: binary(),
		username :: user_db_entry:id(),
		displayed_name :: binary(),
		avatar :: binary(),
		current_history_ix :: non_neg_integer(),
		is_pinged :: boolean()
	}
).

-type type() :: #room_user{}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export_type([type/0]).

%%%% Accessors
-export
(
	[
		new/6,

		get_color/1,
		get_username/1,
		get_displayed_name/1,
		get_avatar/1,
		get_current_history_index/1,
		get_is_pinged/1,

		set_color/2,
		set_username/2,
		set_displayed_name/2,
		set_avatar/2,
		set_current_history_index/2,
		set_is_pinged/2,

		get_color_field/0,
		get_username_field/0,
		get_displayed_name_field/0,
		get_avatar_field/0,
		get_current_history_index_field/0,
		get_is_pinged_field/0
	]
).

-export
(
	[
		ataxia_set_color/2,
		ataxia_set_username/2,
		ataxia_set_displayed_name/2,
		ataxia_set_avatar/2,
		ataxia_set_current_history_index/2,
		ataxia_set_is_pinged/2
	]
).

-export([encode/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec new
	(
		binary(),
		user_db_entry:id(),
		binary(),
		binary(),
		non_neg_integer(),
		boolean()
	) -> type().
new
(
	Color,
	Username,
	DisplayedName,
	Avatar,
	CurrentHistoryIX,
	IsPinged
) ->
	#room_user
	{
		color = Color,
		username = Username,
		displayed_name = DisplayedName,
		avatar = Avatar,
		current_history_ix = CurrentHistoryIX,
		is_pinged = IsPinged
	}.

%%%% GET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_color (type()) -> binary().
get_color (#room_user{ color = Result }) -> Result.

-spec get_username (type()) -> user_db_entry:id().
get_username (#room_user{ username = Result }) -> Result.

-spec get_displayed_name (type()) -> binary().
get_displayed_name (#room_user{ displayed_name = Result }) -> Result.

-spec get_avatar (type()) -> binary().
get_avatar (#room_user{ avatar = Result }) -> Result.

-spec get_current_history_index (type()) -> non_neg_integer().
get_current_history_index (#room_user{ current_history_ix = Result }) -> Result.

-spec get_is_pinged (type()) -> boolean().
get_is_pinged (#room_user{ is_pinged = Result }) -> Result.

%%%% SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec set_color (binary(), type()) -> type().
set_color (Color, User) -> User#room_user{ color = Color }.

-spec set_username (user_db_entry:id(), type()) -> type().
set_username (Username, User) -> User#room_user{ username = Username }.

-spec set_displayed_name (binary(), type()) -> type().
set_displayed_name (DisplayedName, User) ->
	User#room_user{ displayed_name = DisplayedName }.

-spec set_avatar (binary(), type()) -> type().
set_avatar (Avatar, User) -> User#room_user{ avatar = Avatar }.

-spec set_current_history_index (non_neg_integer(), type()) -> type().
set_current_history_index (CurrentHistoryIX, User) ->
	User#room_user{ current_history_ix = CurrentHistoryIX }.

-spec set_is_pinged (boolean(), type()) -> type().
set_is_pinged (IsPinged, User) -> User#room_user{ is_pinged = IsPinged }.

%%%% ATAXIA SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxia_set_color (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_color (Color, User) ->
	{
		ataxic:update_field(get_color_field(), ataxic:constant(Color)),
		User#room_user{ color = Color }
	}.

-spec ataxia_set_username (user_db_entry:id(), type()) -> {ataxic:type(), type()}.
ataxia_set_username (Username, User) ->
	{
		ataxic:update_field(get_username_field(), ataxic:constant(Username)),
		User#room_user{ username = Username }
	}.

-spec ataxia_set_displayed_name (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_displayed_name (DisplayedName, User) ->
	{
		ataxic:update_field
		(
			get_displayed_name_field(),
			ataxic:constant(DisplayedName)
		),
		User#room_user{ displayed_name = DisplayedName }
	}.

-spec ataxia_set_avatar (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_avatar (Avatar, User) ->
	{
		ataxic:update_field(get_avatar_field(), ataxic:constant(Avatar)),
		User#room_user{ avatar = Avatar }
	}.

-spec ataxia_set_current_history_index
	(
		non_neg_integer(),
		type()
	)
	-> {ataxic:type(), type()}.
ataxia_set_current_history_index (CurrentHistoryIX, User) ->
	{
		ataxic:update_field
		(
			get_current_history_index_field(),
			ataxic:constant(CurrentHistoryIX)
		),
		User#room_user{ current_history_ix = CurrentHistoryIX }
	}.

-spec ataxia_set_is_pinged (boolean(), type()) -> {ataxic:type(), type()}.
ataxia_set_is_pinged (IsPinged, User) ->
	{
		ataxic:update_field(get_is_pinged_field(), ataxic:constant(IsPinged)),
		User#room_user{ is_pinged = IsPinged }
	}.

%%%% Field Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_color_field () -> non_neg_integer().
get_color_field () -> #room_user.color.

-spec get_username_field () -> non_neg_integer().
get_username_field () -> #room_user.username.

-spec get_displayed_name_field () -> non_neg_integer().
get_displayed_name_field () -> #room_user.displayed_name.

-spec get_avatar_field () -> non_neg_integer().
get_avatar_field () -> #room_user.avatar.

-spec get_current_history_index_field () -> non_neg_integer().
get_current_history_index_field () -> #room_user.current_history_ix.

-spec get_is_pinged_field () -> non_neg_integer().
get_is_pinged_field () -> #room_user.is_pinged.

%%%% Encoders %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec encode (type()) -> {list({binary(), any()})}.
encode (Object) ->
	{
		[
			{?COLOR_FIELD, Object#room_user.color},
			{?USERNAME_FIELD, Object#room_user.username},
			{?DISPLAYED_NAME_FIELD, Object#room_user.displayed_name},
			{?AVATAR_FIELD, Object#room_user.avatar},
			{?USER_HISTORY_INDEX_FIELD, Object#room_user.current_history_ix},
			{?IS_PINGED_FIELD, Object#room_user.is_pinged}
		]
	}.
