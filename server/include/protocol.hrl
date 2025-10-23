%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROTOCOL TAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make sure all tags _within a category_ are unique.

%%%% MAIN FIELDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(ACTION_FIELD, <<"act">>).
-define(ACTION_ID_FIELD, <<"aid">>).
-define(ACTIVE_FACE_FIELD, <<"afa">>).
-define(ACTOR_ID_FIELD, <<"aci">>).
-define(ANGLE_FIELD, <<"a">>).
-define(AVATAR_FIELD, <<"avt">>).
-define(BACK_FIELD, <<"bac">>).
-define(CATEGORY_FIELD, <<"cat">>).
-define(CHAT_FIELD, <<"cha">>).
-define(COLOR_FIELD, <<"col">>).
-define(CONTAINS_FIELD, <<"con">>).
-define(CONTENT_FIELD, <<"ctn">>).
-define(DISPLAYED_NAME_FIELD, <<"dnm">>).
-define(DECLINED_FIELD, <<"dcl">>).
-define(EMAIL_FIELD, <<"eml">>).
-define(FACES_FIELD, <<"fac">>).
-define(FRONT_FIELD, <<"fro">>).
-define(HEIGHT_FIELD, <<"hei">>).
-define(HISTORY_FIELD, <<"hst">>).
-define(HISTORY_INDEX_FIELD, <<"hix">>).
-define(ID_FIELD, <<"id">>).
-define(IS_DISPLAYED_FIELD, <<"dis">>).
-define(IS_FLIPPED_FIELD, <<"fli">>).
-define(IS_LOCKED_FIELD, <<"lok">>).
-define(IS_PINGED_FIELD, <<"pin">>).
-define(LOBBY_FIELD, <<"lby">>).
-define(MESSAGE_FIELD, <<"msg">>).
-define(OBJECTS_FIELD, <<"obj">>).
-define(PASSWORD_FIELD, <<"pwd">>).
-define(PENDING_ROOMS_FIELD, <<"prs">>).
-define(PROPERTIES_FIELD, <<"pro">>).
-define(ROOM_GAME_ID_FIELD, <<"rgi">>).
-define(ROOM_ID_FIELD, <<"rid">>).
-define(ROOM_FIELD, <<"rom">>).
-define(ROOM_NAME_FIELD, <<"rnm">>).
-define(SESSION_TOKEN_FIELD, <<"sto">>).
-define(SHOWS_CARD_FIELD, <<"shc">>).
-define(TAGS_FIELD, <<"tag">>).
-define(TARGETS_FIELD, <<"tar">>).
-define(TYPE_FIELD, <<"typ">>).
-define(URL_FIELD, <<"url">>).
-define(USERNAME_FIELD, <<"urn">>).
-define(USERS_FIELD, <<"usr">>).
-define(USER_FIELD, <<"u">>).
-define(USER_HISTORY_INDEX_FIELD, <<"uhx">>).
-define(USER_ID_FIELD, <<"uid">>).
-define(USER_VERSION_FIELD, <<"uvr">>).
-define(WIDTH_FIELD, <<"wit">>).
-define(X_FIELD, <<"x">>).
-define(Y_FIELD, <<"y">>).
-define(Z_FIELD, <<"z">>).

%%%% ACTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(FLIP_ACTION_ID, <<"fli">>).
-define(MOVE_ACTION_ID, <<"mov">>).
-define(PING_ACTION_ID, <<"pin">>).

%%%% REPLY TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(DISCONNECT_REPLY_ID, <<"dis">>).
-define(ERROR_REPLY_ID, <<"err">>).
-define(HISTORY_UPDATE_REPLY_ID, <<"hup">>).
-define(PENDING_ROOMS_UPDATE_REPLY_ID, <<"pru">>).
-define(SET_ROOM_REPLY_ID, <<"sro">>).
-define(SET_SESSION_REPLY_ID, <<"sst">>).

%%%% ERROR CATEGORIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(ERROR_ERROR_ID, <<"err">>).
-define(MISSING_INPUT_ERROR_ID, <<"msi">>).
-define(NETWORK_ERROR_ID, <<"net">>).
-define(PROGRAMMING_ERROR_ID, <<"pog">>).
-define(WARNING_ERROR_ID, <<"wrn">>).

%%%% OBJECT TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(CARD_OBJECT_TYPE, <<"car">>).
-define(DECK_OBJECT_TYPE, <<"dec">>).
-define(DICE_OBJECT_TYPE, <<"die">>).
