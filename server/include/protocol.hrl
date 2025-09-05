%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROTOCOL TAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make sure all tags _within a category_ are unique.

%%%% MAIN FIELDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(ACTION_FIELD, <<"act">>).
-define(ACTION_ID_FIELD, <<"aid">>).
-define(AVATAR_FIELD, <<"avt">>).
-define(CATEGORY_FIELD, <<"cat">>).
-define(CHAT_FIELD, <<"cha">>).
-define(CONTENT_FIELD, <<"ctn">>).
-define(DISPLAYED_NAME_FIELD, <<"dnm">>).
-define(EMAIL_FIELD, <<"eml">>).
-define(HISTORY_FIELD, <<"hst">>).
-define(HISTORY_INDEX_FIELD, <<"hix">>).
-define(USER_HISTORY_INDEX_FIELD, <<"uhx">>).
-define(LOBBY_FIELD, <<"lby">>).
-define(MESSAGE_FIELD, <<"msg">>).
-define(OBJECTS_FIELD, <<"obj">>).
-define(PASSWORD_FIELD, <<"pwd">>).
-define(PENDING_ROOMS_FIELD, <<"prs">>).
-define(ROOM_GAME_ID_FIELD, <<"rgi">>).
-define(ROOM_ID_FIELD, <<"rid">>).
-define(ROOM_NAME_FIELD, <<"rnm">>).
-define(SESSION_TOKEN_FIELD, <<"sto">>).
-define(TARGETS_FIELD, <<"tar">>).
-define(USER_ID_FIELD, <<"uid">>).
-define(USER_VERSION_FIELD, <<"uvr">>).

%%%% ACTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(FLIP_ACTION_ID, <<"fli">>).

%%%% REPLY TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(DISCONNECT_REPLY_ID, <<"dis">>).
-define(ERROR_REPLY_ID, <<"err">>).
-define(HISTORY_UPDATE_REPLY_ID, <<"hup">>).
-define(PENDING_ROOMS_UPDATE_REPLY_ID, <<"pru">>).
-define(SET_ROOM_REPLY_ID, <<"sro">>).
-define(SET_SESSION_REPLY_ID, <<"sst">>).

%%%% ERROR CATEGORIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(WARNING_ERROR_ID, <<"wrn">>).
-define(ERROR_ERROR_ID, <<"err">>).
-define(NETWORK_ERROR_ID, <<"net">>).
-define(PROGRAMMING_ERROR_ID, <<"pog">>).
-define(MISSING_INPUT_ERROR_ID, <<"msi">>).
