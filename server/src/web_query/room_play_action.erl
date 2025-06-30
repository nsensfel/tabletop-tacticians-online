-module(room_play_action).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-include("yaws_api.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export([out/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% SECURITY CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec authenticate_user (room_action_request:type()) -> ('ok' | 'error').
authenticate_user (Request) ->
	UserID = room_action_request:get_user_id(Request),
	SessionToken = room_action_request:get_session_token(Request),
	LockJanitor = room_action_request:get_lock_janitor(Request),
	case shr_security:credentials_match(LockJanitor, SessionToken, UserID) of
		true -> ok;
		Error -> jiffy:encode([shr_disconnected:generate()])
	end.

-spec fetch_data
	(
		room_action_request:type()
	) -> ({'ok', room:type()} | ataxic_error:type()).
fetch_data (Request) ->
	RoomID = room_action_request:get_room_id(Request),
	% Would be nice to automatically release any still held lock on termination.
	% Should be doable, too. Let's call it the lock janitor
	LockJanitor = room_action_request:get_lock_janitor(Request),
	case ataxia_lock_client:request_write_lock(LockJanitor, room_db, RoomID) of
		{ok, Lock} ->
			case
				ataxia_client:fetch_if
				(
					room_db,
					RoomID,
					Lock,
					room:ataxic_is_user_in_room(UserID)
				)
			of
				{ok, RoomVersion, RoomData} ->
					{ok, ataxia_client_data:new(Lock, RoomVersion, RoomData)};

				Error -> {error, Error};
			end;

		Error ->
			{error, Error}
	end.

apply_action (Request, S0Data) ->
	UserID = room_action_request:get_user_id(Request),
	Action = room_action_request:get_action(Request),
	S0Room = ataxia_client_data:get_value(S0Data),
	UserData = room:get_user_data(S0Room, UserID),
	CurrentUserHistoryIX = room_user_data:get_current_history_index(UserData),
	case
		room_action:ataxia_apply_to
		(
			UserID,
			Action,
		)
	of
		{ok, AtaxicUpdate, S1Room} ->
			S1Data = ataxia_client_data:add_update(AtaxicUpdate, S1Room, S0Data),
			{ok, S1Data, CurrentUserHistoryIX};

		{error, Error} -> {error, Error}
	end.

update_database (ClientData) ->
	case
		ataxia_client:safe_update
		(
			ataxia_client_data:get_database(ClientData),
			ataxia_client_data:get_id(ClientData),
			ataxia_client_data:get_lock(ClientData),
			ataxia_client_data:get_ataxic(ClientData),
			ataxia_client_data:get_version(ClientData),
			ataxia_client_data:get_value(ClientData)
		)
	of
		{ok, _NewVersion} -> ok;
		{error, Error} -> {error, Error}
	end.

release_resources (Request) ->
	ataxia_lock_client:release_all
	(
		room_action_request:get_lock_janitor(Request)
	).

generate_reply (ClientData, PreviousUserHistoryIX) ->
	lists:map
	(
		fun encode_history_action/1 end,
		room:get_history_from(PreviousUserHistoryIX)
	).

%%%% MAIN LOGIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle (shr_query:type()) -> binary().
handle (Query) ->
	Request = decode_request(Query), % Add lockJanitor in this decode function.
	ok = authenticate_user(Request),
	{ok, S0Data} = fetch_data(Request),
	{ok, S1Data, PreviousUserHistoryIX} = apply_action(Request, S0Data),
	ok = update_database(S1Data),
	release_resources(Request),
	generate_reply(S1Data, PreviousUserHistoryIX).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
out(A) ->
	{
		content,
		"application/json; charset=UTF-8",
		handle(shr_query:new(A))
	}.
