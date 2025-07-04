%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROTOCOL TAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make sure all tags _within a category_ are unique.

%%%% MAIN FIELDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(ACTION_FIELD, <<"act">>).
-define(ACTION_ID_FIELD, <<"aid">>).
-define(HISTORY_INDEX_FIELD, <<"hix">>).
-define(MESSAGE_FIELD, <<"msg">>).
-define(REPLY_ID_FIELD, <<"rep">>).
-define(ROOM_ID_FIELD, <<"rid">>).
-define(SESSION_TOKEN_FIELD, <<"sto">>).
-define(TARGETS_FIELD, <<"tar">>).
-define(USER_ID_FIELD, <<"uid">>).

%%%% ACTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(FLIP_ACTION_ID, <<"fli">>).

%%%% REPLY TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(DISCONNECT_REPLY_ID, <<"dis">>).
-define(FAILED_REPLY_ID, <<"fai">>).
-define(HISTORY_UPDATE_REPLY_ID, <<"hup">>).
-define(ROOM_DATA_REPLY_ID, <<"rda">>).
