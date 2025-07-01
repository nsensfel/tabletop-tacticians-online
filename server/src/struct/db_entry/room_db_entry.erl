-module(room_db_entry).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type id() :: ataxia_id:type().

-record
(
	user_data,
	{
		color :: binary(),
		id :: user_db_entry:id(),
		name :: binary(),
		current_history_index :: non_neg_integer(),
		is_active :: boolean()
	}
).

-opaque user_data() :: #user_data{}.

-record
(
	room,
	{
		allowed_users :: ordsets:ordset(user_db_entry:id()),
		objects :: orddict:orddict(non_neg_integer(), room_object:type()),
		history :: list(room_action:type()),
		history_start_index :: non_neg_integer(),
		user_id_to_user_ix :: orddict:orddict(user_db_entry:id(), non_neg_integer()),
		user_data :: orddict:orddict(non_neg_integer(), user_data())
	}
).

-opaque type() :: #room{}.

-export_type([user_data/0, type/0, id/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Accessors
-export
(
	[
		ataxic_room_allows_user/1,

		ataxia_update_objects/3,

		get_allowed_users_field/0,
		get_objects_field/0,
		get_history_field/0,
		get_history_start_index_field/0,
		get_user_id_to_user_ix_field/0,
		get_user_data_field/0
	]
).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxic_is_user_in_room (user_db_entry:id()) -> ataxic:basic().
ataxic_is_user_in_room (PlayerID) ->
	ataxic:field
	(
		get_allowed_users_field(),
		apply_function
		(
			ordsets,
			is_element,
			ataxic:constant(PlayerID),
			ataxic:current_value()
		)
	).

-spec ataxia_update_objects
	(
		ataxic:type(),
		orddict:orddict(non_neg_integer(), room_object:type()),
		type()
	)
	-> {ataxic:type(), type()}.
ataxia_update_objects (Update, Objects, Room) ->
	{
		ataxic:update_field(get_objects_field(), Update),
		Room#room{ objects = Objects }
	}.

-spec get_allowed_users_field () -> non_neg_integer().
get_allowed_users_field () -> #room.allowed_users.

-spec get_objects_field () -> non_neg_integer().
get_objects_field () -> #room.objects.

-spec get_history_field () -> non_neg_integer().
get_history_field () -> #room.history.

-spec get_history_start_index_field () -> non_neg_integer().
get_history_start_index_field () -> #room.history_start_index.

-spec get_user_id_to_user_ix_field () -> non_neg_integer().
get_user_id_to_user_ix_field () -> #room.user_id_to_user_ix.

-spec get_user_data_field () -> non_neg_integer().
get_user_data_field () -> #room.user_data.
