-module(room_action).

-type deck_source() :: 'top' | 'bottom' | 'random'.

-record
(
	move,
	{
		objects_id :: list(room_object:id()),
		offset_x :: integer(),
		offset_y :: integer(),
		offset_z :: integer()
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
		objects_id :: list(room_object:id())
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
		object_id :: room_object:id(), % Can only be applied to
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-record
(
	draw_from,
	{
		object_id :: room_object:id(), % Can only be applied to
		deck_source :: deck_source(),
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-record
(
	place_into,
	{
		object_id :: room_object:id(), % Can only be applied to
		deck_source :: deck_source(),
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-record
(
	look_inside,
	{
		object_id :: room_object:id(), % Can only be applied to
		previous_top :: room_object:id(),
		new_top :: room_object:id()
	}
).

-type act() ::
	#move{}
	| #ping{}
	| #chat{}
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

-export_type([type/0, id/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Accessors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
