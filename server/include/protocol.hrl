%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROTOCOL TAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make sure all tags _within a category_ are unique.

%%%% MAIN FIELDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(ACTION_FIELD, <<"act">>).
-define(ACTION_ID_FIELD, <<"aid">>).
-define(AVATAR_FIELD, <<"avt">>).
-define(CATEGORY_FIELD, <<"cat">>).
-define(CONTENT_FIELD, <<"txt">>).
-define(DISPLAYED_NAME_FIELD, <<"dnm">>).
-define(EMAIL_FIELD, <<"eml">>).
-define(HISTORY_INDEX_FIELD, <<"hix">>).
-define(MESSAGE_FIELD, <<"msg">>).
-define(PASSWORD_FIELD, <<"pwd">>).
-define(REPLY_ID_FIELD, <<"rep">>).
-define(ROOM_ID_FIELD, <<"rid">>).
-define(SESSION_TOKEN_FIELD, <<"sto">>).
-define(TARGETS_FIELD, <<"tar">>).
-define(USER_ID_FIELD, <<"uid">>).
-define(USER_VERSION_FIELD, <<"uvr">>).

%%%% ACTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(FLIP_ACTION_ID, <<"fli">>).

%%%% REPLY TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(DISCONNECT_REPLY_ID, <<"dis">>).
-define(ERROR_ID, <<"err">>).
-define(FAILED_REPLY_ID, <<"fai">>).
-define(HISTORY_UPDATE_REPLY_ID, <<"hup">>).
-define(ROOM_DATA_REPLY_ID, <<"rda">>).
-define(SET_SESSION_ID, <<"sst">>).

%%%% ERROR CATEGORIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(WARNING_ERROR_ID, <<"wrn">>).
-define(ERROR_ERROR_ID, <<"err">>).
-define(NETWORK_ERROR_ID, <<"net">>).
-define(PROGRAMMING_ERROR_ID, <<"pog">>).
-define(MISSING_INPUT_ERROR_ID, <<"msi">>).
