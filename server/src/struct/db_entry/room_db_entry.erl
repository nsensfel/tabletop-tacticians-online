-module(room_db_entry).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type id() :: ataxia_id:type().

-record
(
	user,
	{
		color :: binary(),
		id :: user_db_entry:id(),
		name :: binary(),
		current_history_ix :: non_neg_integer(),
		is_active :: boolean()
	}
).

-opaque user_data() :: #user{}.

-record
(
	room,
	{
		allowed_users :: ordsets:ordset(user_db_entry:id()),
		objects :: orddict:orddict(non_neg_integer(), room_object:type()),
		history :: list(room_action:type()), % It would be better for the list to be recent to old
		history_last_ix :: non_neg_integer(),
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
		ataxic_is_user_in_room/1,

		ataxia_update_objects/3,
		ataxia_add_to_history/2,
		ataxia_update_user_history_index/2,

		get_user_index/2,
		get_objects/1,
		get_history_for/2,

		get_allowed_users_field/0,
		get_objects_field/0,
		get_history_field/0,
		get_history_last_ix_field/0,
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
		ataxic:apply_function
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

-spec ataxia_add_to_history
	(
		room_action:type(),
		type()
	)
	-> {ataxic:type(), type()}.
ataxia_add_to_history (Action, Room) ->
	NewFinalIX = Room#room.history_last_ix + 1,
	{
		ataxic:sequence
		(
			[
				ataxic:update_field
				(
					get_history_field(),
					ataxic:apply_function
					(
						lists,
						append,
						[ataxic:constant([Action]), ataxic:current_value()]
					)
				),
				ataxic:update_field
				(
					get_history_last_ix_field(),
					ataxic:constant(NewFinalIX)
				)
			]
		),
		Room#room
		{
			history = [Action | Room#room.history]
		}
	}.

-spec ataxia_update_user_history_index
	(
		non_neg_integer(),
		type()
	)
	-> {ataxic:type(), type()}.
ataxia_update_user_history_index (UserIX, S0Room) ->
	S0UserData = get_user_data(UserIX, S0Room),
	LastHistoryIX = S0Room#room.history_last_ix,
	AtaxicUpdate0 =
		ataxic:update_field
		(
			get_user_data_field(),
			ataxic_sugar:update_orddict_element
			(
				UserIX,
				ataxic:update_field
				(
					#user.current_history_ix,
					ataxic:constant(LastHistoryIX)
				)
			)
		),
	S1Room =
		S0Room#room
		{
			user_data =
				orddict:store
				(
					UserIX,
					S0UserData#user{ current_history_ix = LastHistoryIX }
				)
		},
	LowestHistoryIX =
		orddict:fold
		(
			fun (_Key, #user{ current_history_ix = IX }, MinIX) ->
				case MinIX =< IX of
					true -> MinIX;
					_ -> IX
				end
			end,
			LastHistoryIX,
			S1Room#room.user_data
		),
	NewHistoryLength = LastHistoryIX - LowestHistoryIX,
	History = S1Room#room.history,
	case NewHistoryLength /= length(History) of
		false -> {AtaxicUpdate0, S1Room};
		_ ->
			{
				ataxic:sequence
				(
					[
						AtaxicUpdate0,
						ataxic:update_field
						(
							get_history_field(),
							ataxic:apply_function
							(
								lists,
								sublist,
								[
									ataxic:current_value(),
									ataxic:constant(NewHistoryLength)
								]
							)
						)
					]
				),
				S1Room#room
				{
					history = lists:sublist(History, NewHistoryLength)
				}
			}
	end.

-spec get_user_index (ataxia_id:type(), type()) -> non_neg_integer().
get_user_index (UserID, Room) ->
	orddict:fetch(UserID, Room#room.user_id_to_user_ix).

-spec get_user_data (non_neg_integer(), type()) -> user_data().
get_user_data (UserIX, Room) -> orddict:fetch(UserIX, Room#room.user_data).

-spec get_objects (type()) -> user_data().
get_objects (Room) -> Room#room.objects.

-spec get_history_for (non_neg_integer(), type()) -> list(room_action:type()).
get_history_for (UserIX, Room) ->
	UserData = get_user_data(UserIX, Room),
	CurrentHistoryIX = UserData#user.current_history_ix,
	LastHistoryIX = Room#room.history_last_ix,
	History = Room#room.history,
	lists:sublist(History, LastHistoryIX - CurrentHistoryIX).

%%%% FIELDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_allowed_users_field () -> non_neg_integer().
get_allowed_users_field () -> #room.allowed_users.

-spec get_objects_field () -> non_neg_integer().
get_objects_field () -> #room.objects.

-spec get_history_field () -> non_neg_integer().
get_history_field () -> #room.history.

-spec get_history_last_ix_field () -> non_neg_integer().
get_history_last_ix_field () -> #room.history_last_ix.

-spec get_user_id_to_user_ix_field () -> non_neg_integer().
get_user_id_to_user_ix_field () -> #room.user_id_to_user_ix.

-spec get_user_data_field () -> non_neg_integer().
get_user_data_field () -> #room.user_data.
