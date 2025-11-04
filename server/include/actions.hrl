-type deck_source() :: 'top' | 'bottom' | 'random'.

-record
(
	move,
	{
		object_ids :: list(room_object:id()),
		x_offset :: integer(),
		y_offset :: integer(),
		z_offset :: integer(),
		angle_offset :: integer()
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
		object_ids :: list(room_object:id())
	}
).

-record
(
	set_face,
	{
		object_ids :: list(room_object:id()),
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
		object_ids :: list(room_object:id()),
		previous_faces :: list(non_neg_integer()),
		new_faces :: list(non_neg_integer())
	}
).

-record
(
	draw_from,
	{
		object_id :: room_object:id(),
		deck_source :: room_object:id(),
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
		deck_id :: room_object:id()
	}
).

-record
(
	create_deck,
	{
		deck_id :: room_object:id(),
		card_ids :: list(room_object:id()),
		previous_attitudes :: list(room_object:attitude())
	}
).

-record
(
	explode_deck,
	{
		deck_id :: room_object:id(),
		card_ids :: list(room_object:id()),
		new_attitudes :: list(room_object:attitude())
	}
).

-type act() ::
	#move{}
	| #ping{}
	| #chat{}
	| #flip{}
	| #set_face{}
	| #shuffle{}
	| #roll{}
	| #draw_from{}
	| #place_into{}
	| #look_inside{}
	| #create_deck{}
	| #explode_deck{}
.
