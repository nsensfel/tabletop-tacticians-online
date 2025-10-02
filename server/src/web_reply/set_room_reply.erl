-module(set_room_reply).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export([new/2]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Request Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% SECURITY CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec new (room_db_entry:type(), ataxia_id:type()) -> {list({binary(), any()})}.
new (Room, Username) ->
	{
		[
			{?MESSAGE_FIELD, ?SET_ROOM_REPLY_ID},
			{?ROOM_NAME_FIELD, room_db_entry:get_name(Room)},
			{?ROOM_GAME_ID_FIELD, room_db_entry:get_game_id(Room)},
			{
				?OBJECTS_FIELD,
				lists:map
				(
					fun encode_object/1,
					maps:to_list(room_db_entry:get_objects(Room))
				)
			},
			{
				?HISTORY_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_history(Room)
				)
			},
			{
				?USER_HISTORY_INDEX_FIELD,
				room_db_entry:get_user_history_index(Username, Room)
			},
			{
				?HISTORY_INDEX_FIELD,
				room_db_entry:get_history_index(Username, Room)
			},
			{
				% We need a way to easily update this. Is that an action?
				?LOBBY_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_history(Room)
				)
			},
			{
				?CHAT_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_chat(Room)
				)
			},
			{
				?USERS_FIELD,
				lists:map
				(
					fun encode_room_action/1,
					room_db_entry:get_users(Room)
				)
			}
		]
	}.
