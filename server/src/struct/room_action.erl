-module(room_action).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type deck_source() :: 'top' | 'bottom' | 'random'.

-record
(
	move,
	{
		objects_id :: list(room_object:id()),
		offset_x :: integer(),
		offset_y :: integer(),
		offset_z :: integer(),
		offset_angle :: integer()
	}
).

-record
(
	ping,
	{
		x :: non_neg_integer(),
		y :: non_neg_integer()
	}
).

-record
(
	chat,
	{
		text :: binary()
	}
).

-record
(
	flip,
	{
		objects_id :: list(room_object:id())
	}
).

-record
(
	rotate,
	{
		objects_id :: list(room_object:id()),
		angle_offset :: integer()
	}
).

-record
(
	set_face,
	{
		objects_id :: list(room_object:id()),
		previous_faces :: list(non_neg_integer()),
		new_face :: non_neg_integer()
	}
).

-record
(
	shuffle,
	{
		object_id :: room_object:id(),
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-record
(
	roll,
	{
		objects_id :: list(room_object:id()),
		previous_faces :: list(non_neg_integer()),
		new_faces :: list(non_neg_integer())
	}
).

-record
(
	draw_from,
	{
		object_id :: room_object:id(),
		deck_source :: deck_source(),
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-record
(
	place_into,
	{
		object_id :: room_object:id(),
		deck_source :: deck_source(),
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-record
(
	look_inside,
	{
		object_id :: room_object:id(),
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-type act() ::
	#move{}
	| #ping{}
	| #chat{}
	| #flip{}
	| #rotate{}
	| #set_face{}
	| #shuffle{}
	| #roll{}
	| #draw_from{}
	| #place_into{}
	| #look_inside{}
.

-record
(
	action,
	{
		actor_ix :: non_neg_integer(),
		act :: act()
	}
).

-opaque type() :: #action{}.

-export_type([type/0, act/0]).

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
