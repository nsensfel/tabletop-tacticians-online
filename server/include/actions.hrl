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

-record
(
	create_deck,
	{
		deck_id :: room_object:id(),
		previous_attitudes :: list(room_object:attitude())
	}
).

-record
(
	explode_deck,
	{
		as_line :: boolean()
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
	| #create_deck{}
	| #explode_deck{}
.

-record
(
	action,
	{
		actor_ix :: non_neg_integer(),
		act :: act()
	}
).

