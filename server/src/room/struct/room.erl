-module(room).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type id() :: ataxia_id:type().

-record
(
	room,
	{
		player_ids :: list(shr_player:id()),
		objects :: list(room_object:type()),
		history :: list(room_action:type()),
		history_start_index :: non_neg_integer(),
		player_data :: orddict:orddict(non_neg_integer(), room_player_data:type())
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
		ataxic_is_player_in_room/1,

		get_player_ids_field/0,
		get_objects_field/0,
		get_history_field/0,
		get_history_start_index_field/0,
		get_player_data_field/0,
	]
).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxic_is_player_in_room (shr_player:id()) -> ataxic:basic().
ataxic_is_player_in_room (PlayerID) ->
	ataxic_sugar:is_in_set(ataxic:constant(PlayerID), get_player_ids_field()).

-spec get_player_ids_field () -> non_neg_integer().
get_player_ids_field () -> #room.player_ids.

-spec get_objects_field () -> non_neg_integer().
get_objects_field () -> #room.objects.

-spec get_history_field () -> non_neg_integer().
get_history_field () -> #room.history.

-spec get_history_start_index_field () -> non_neg_integer().
get_history_start_index_field () -> #room.history_start_index.

-spec get_player_data_field () -> non_neg_integer().
get_player_data_field () -> #room.player_data.
