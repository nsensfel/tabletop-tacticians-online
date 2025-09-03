-module(query_user_management).

-include("protocol.hrl").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export([handle_session/4]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec fetch_data
	(
		ataxia_client:type(),
		binary()
	)
	->
	{
		ataxia_client:type(),
		({ok, ataxia_client_data:type()} | {error, binary()})
	}.
fetch_data (S0AtaxiaClient, Username) ->
	{S1AtaxiaClient, FetchResult} =
		ataxia_client:fetch(S0AtaxiaClient, user_db, {temp, read}, Username),

	{
		S1AtaxiaClient,
		case FetchResult of
			{ok, Version, Value} ->
				{
					ok,
					ataxia_client_data:new(user_db, Username, none, Version, Value)
				};

			_ -> {error, <<"Could not retrieve user data.">>}
		end
	}.

-spec validate_session_token
	(
		binary(),
		({ok, ataxia_client_data:type()} | {error, binary()})
	)
	-> ({ok, ataxia_client_data:type()} | {error, binary()}).
validate_session_token (SessionToken, {ok, DBEntry}) ->
	case
		user_db_entry:has_session_token
		(
			SessionToken,
			ataxia_client_data:get_value(DBEntry)
		)
	of
		true -> {ok, DBEntry};
		_ -> {error, <<"Invalid session token.">>}
	end;
validate_session_token (_SessionToken, Other) -> Other.

-spec generate_pending_room_list_update
	(
		non_neg_integer(),
		({ok, ataxia_client_data:type()} | {error, binary()})
	)
	-> (ok | {ok, list(any())} | {error, binary()}).
generate_pending_room_list_update (UserVersion, {ok, DBEntry}) ->
	Version = ataxia_client_data:get_version(DBEntry),
	User = ataxia_client_data:get_value(DBEntry),
	case UserVersion == Version of
		true -> {ok, []};
		_ ->
			{
				ok,
				[
					pending_rooms_update_reply:new
					(
						user_db_entry:get_pending_rooms(User)
					)
				]
			}
	end;
generate_pending_room_list_update (_UserVersion, {error, Message}) ->
	{
		error,
		[
			disconnect_reply:new(),
			error_reply:new(Message)
		]
	}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec handle_session
	(
		ataxia_client:type(),
		binary(),
		binary(),
		binary()
	)
	->
	{
		ataxia_client:type(),
		({ok, list(any())} | {error, list(any)})
	}.
handle_session (S0AtaxiaClient, UserVersion, Username, SessionToken) ->
	{S1AtaxiaClient, FetchResult} = fetch_data(S0AtaxiaClient, Username),
	ValidateResult = validate_session_token(SessionToken, FetchResult),
	RoomUpdateResult =
		generate_pending_room_list_update(UserVersion, ValidateResult),

	{S1AtaxiaClient, RoomUpdateResult}.
