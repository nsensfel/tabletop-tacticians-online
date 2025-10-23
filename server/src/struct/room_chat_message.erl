-module(room_chat_message).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record
(
	room_chat_message,
	{
		username :: user_db_entry:id(),
		message :: binary()
	}
).

-type type() :: #room_chat_message{}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export_type([type/0]).

%%%% Accessors
-export
(
	[
		new/2,

		get_username/1,
		get_message/1,

		set_username/2,
		set_message/2,

		get_username_field/0,
		get_message_field/0
	]
).

-export
(
	[
		ataxia_set_username/2,
		ataxia_set_message/2
	]
).

-export([encode/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec new (user_db_entry:id(), binary()) -> type().
new (Username, Message) ->
	#room_chat_message
	{
		username = Username,
		message = Message
	}.

%%%% GET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_username (type()) -> user_db_entry:id().
get_username (#room_chat_message{ username = Result }) -> Result.

-spec get_message (type()) -> binary().
get_message (#room_chat_message{ message = Result }) -> Result.

%%%% SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec set_username (user_db_entry:id(), type()) -> type().
set_username (Username, Msg) -> Msg#room_chat_message{ username = Username }.

-spec set_message (binary(), type()) -> type().
set_message (DisplayedName, Msg) ->
	Msg#room_chat_message{ message = DisplayedName }.

%%%% ATAXIA SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxia_set_username
(
	user_db_entry:id(),
	type()
)
-> {ataxic:type(), type()}.
ataxia_set_username (Username, Msg) ->
	{
		ataxic:update_field(get_username_field(), ataxic:constant(Username)),
		Msg#room_chat_message{ username = Username }
	}.

-spec ataxia_set_message (binary(), type()) -> {ataxic:type(), type()}.
ataxia_set_message (DisplayedName, Msg) ->
	{
		ataxic:update_field
		(
			get_message_field(),
			ataxic:constant(DisplayedName)
		),
		Msg#room_chat_message{ message = DisplayedName }
	}.

%%%% Field Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_username_field () -> non_neg_integer().
get_username_field () -> #room_chat_message.username.

-spec get_message_field () -> non_neg_integer().
get_message_field () -> #room_chat_message.message.

%%%% Encoders %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec encode (type()) -> {list({binary(), any()})}.
encode (Object) ->
	{
		[
			{?USERNAME_FIELD, Object#room_chat_message.username},
			{?MESSAGE_FIELD, Object#room_chat_message.message}
		]
	}.
