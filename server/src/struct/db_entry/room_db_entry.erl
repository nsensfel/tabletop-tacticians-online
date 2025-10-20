-module(room_db_entry).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type id() :: ataxia_id:type().

-record
(
	lobby_user,
	{
		user :: room_user:type(),
		message :: binary(),
		declined :: boolean()
	}
).

-type lobby_user_data() :: #lobby_user{}.

-record
(
	room,
	{
		name :: binary(),
		game_id :: ataxia_id:type(),
		objects :: #{ ataxia_id:type() => room_object:type() },
		% It would be better for the list to be recent to old
		history :: list(room_action:type()),
		history_last_ix :: non_neg_integer(),
		lobby :: #{ ataxia_id:type() => lobby_user_data() },
		chat :: list(chat_message:type()),
		user_data :: #{ ataxia_id:type() => room_user:type() }
	}
).

-opaque type() :: #room{}.

-export_type([type/0, id/0]).

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

		get_objects/1,
		get_history_for/2,

		get_objects_field/0,
		get_history_field/0,
		get_history_last_ix_field/0,
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
		get_user_data_field(),
		ataxic:apply_function
		(
			maps,
			is_key,
			ataxic:constant(PlayerID),
			ataxic:current_value()
		)
	).

-spec ataxia_update_objects
	(
		ataxic:type(),
		#{ ataxia_id:type() => room_object:type() },
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
		ataxia_id:type(),
		type()
	)
	-> {ataxic:type(), type()}.
ataxia_update_user_history_index (UserID, S0Room) ->
	S0UserData = get_user_data(UserID, S0Room),
	LastHistoryIX = S0Room#room.history_last_ix,
	{AtaxicUserUpdate, UpdatedUser} =
		room_user:ataxia_set_current_history_index(UserID, S0UserData),

	AtaxicUpdate0 =
		ataxic:update_field
		(
			get_user_data_field(),
			ataxic_sugar:update_map_element(UserID, AtaxicUserUpdate)
		),
	S1Room =
		S0Room#room
		{
			user_data =
				maps:put
				(
					UserID,
					UpdatedUser,
					S0Room#room.user_data
				)
		},
	LowestHistoryIX =
		maps:fold
		(
			fun (_Key, User, MinIX) ->
				IX = room_user:get_history_index(User),
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

-spec get_user_data (ataxia_id:type(), type()) -> room_user:type().
get_user_data (UserID, Room) -> maps:get(UserID, Room#room.user_data).

-spec get_objects (type()) -> #{ ataxia_id:type() => room_object:type() }.
get_objects (Room) -> Room#room.objects.

-spec get_history_for (ataxia_id:type(), type()) -> list(room_action:type()).
get_history_for (UserID, Room) ->
	UserData = get_user_data(UserID, Room),
	CurrentHistoryIX = room_user:get_history_index(UserData),
	LastHistoryIX = Room#room.history_last_ix,
	History = Room#room.history,
	lists:sublist(History, LastHistoryIX - CurrentHistoryIX).

%%%% FIELDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_objects_field () -> non_neg_integer().
get_objects_field () -> #room.objects.

-spec get_history_field () -> non_neg_integer().
get_history_field () -> #room.history.

-spec get_history_last_ix_field () -> non_neg_integer().
get_history_last_ix_field () -> #room.history_last_ix.

-spec get_user_data_field () -> non_neg_integer().
get_user_data_field () -> #room.user_data.
