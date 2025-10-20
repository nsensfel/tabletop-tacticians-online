-module(room_action).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-include("actions.hrl").
-include("protocol.hrl").

-record
(
	action,
	{
		actor_ix :: non_neg_integer(),
		act :: act()
	}
).

-opaque type() :: #action{}.

-type id() :: ataxia_id:type().

-export_type([type/0, id/0, act/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Accessors

-export
(
	[
		ataxia_apply_to/2
	]
).

-export([encode/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxia_handle_flips
	(
		list(non_neg_integer()),
		list(ataxic:type()),
		orddict:orddict(non_neg_integer(), room_object:type())
	)
	->
	(
		'error'
		|
		{
			'ok',
			ataxic:type(),
			orddict:orddict(non_neg_integer(), room_object:type())
		}
	).
ataxia_handle_flips([], Updates, Objects) ->
	{ok, ataxic:sequence(Updates), Objects};
ataxia_handle_flips([FlipID|NextFlipIDs], Updates, Objects) ->
	case orddict:find(FlipID, Objects) of
		{ok, Object} ->
			case room_object:maybe_ataxia_flip(Object) of
				{Update, NewObject} ->
					ataxia_handle_flips
					(
						NextFlipIDs,
						[
							ataxic_sugar:update_orddict_element(FlipID, Update)
							|Updates
						],
						orddict:store(FlipID, NewObject, Objects)
					);

				error -> error
			end;

		error -> error
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxia_apply_to
	(
		type(),
		orddict:orddict(non_neg_integer(), room_object:type())
	)
	->
	(
		{
			'ok',
			ataxic:type(),
			orddict:orddict(non_neg_integer(), room_object:type())
		}
		| 'error'
	).
ataxia_apply_to (_Action = #move{}, _Objects) ->
	% TODO: implement
	error;
ataxia_apply_to (_Action = #ping{}, Objects) ->
	{ok, ataxic:current_value(), Objects};
ataxia_apply_to (_Action = #chat{}, Objects) ->
	{ok, ataxic:current_value(), Objects};
ataxia_apply_to (Action = #flip{}, Objects) ->
	ataxia_handle_flips(Action#flip.objects_id, [], Objects).

-spec encode (type()) -> {list({binary(), any()})}.
encode
(
	#action
	{
		actor_ix = ActorIX,
		act =
			#move
			{
				objects_id = IDs,
				offset_x = X,
				offset_y = Y,
				offset_z = Z,
				offset_angle = Angle
			}
	}
) ->
	{
		[
			{?ACTOR_IX_FIELD, ActorIX},
			{?ACTION_ID_FIELD, ?MOVE_ACTION_ID},
			{?OBJECTS_FIELD, IDs},
			{?X_FIELD, X},
			{?Y_FIELD, Y},
			{?Z_FIELD, Z},
			{?ANGLE_FIELD, Angle}
		]
	}.
