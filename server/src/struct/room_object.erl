-module(room_object).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-record
(
	image,
	{
		front_url :: binary(),
		back_url :: binary(),
		is_on_front :: boolean(),
	}
).

-record
(
	dice,
	{
		faces :: list(binary())
		active_face :: non_neg_integer()
	}
).

-record
(
	finite_bag,
	{
		url :: binary(),
		contains :: list(non_neg_integer())
	}
).

-record
(
	open_bag,
	{
		url :: binary(),
		contains :: ordsets:ordset(non_neg_integer())
	}
).

-record
(
	magic_bag,
	{
		url :: binary(),
		spawns :: non_neg_integer()
	}
).

-record
(
	hidden_area_tab,
	{
		contains :: ordsets:ordset(non_neg_integer()),
		name :: binary()
	}
).

-record
(
	hidden_area,
	{
		color :: binary(),
		name :: binary(),
		contains :: list(non_neg_integer()),
		active_tab :: non_neg_integer(),
		can_see_inside_ix :: ordsets:ordset(non_neg_integer())
	}
).

-type properties() ::
	#image{},
	| #dice,
	| #finite_bag,
	| #open_bag,
	| #magic_bag,
	| #hidden_area_tab{},
	| #hidden_area{}
.
-record
(
	object,
	{
		visible_to_ix :: 'none' | 'all' | ordsets:ordset(non_neg_integer()),
		can_interact_ix :: 'none' | 'all' | ordsets:ordset(non_neg_integer()),
		width :: non_neg_integer(),
		height :: non_neg_integer(),
		x :: non_neg_integer(),
		y :: non_neg_integer(),
		z :: non_neg_integer(),
		angle :: integer(),
		properties :: properties()
	}
).
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
