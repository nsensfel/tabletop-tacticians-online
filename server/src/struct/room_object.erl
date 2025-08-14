-module(room_object).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type permissions() ::
	'none'
	| 'all'
	| ordsets:ordset(non_neg_integer())
.

-record
(
	image,
	{
		front_url :: binary(),
		back_url :: binary(),
		is_on_front :: boolean()
	}
).

-record
(
	dice,
	{
		faces :: list(binary()),
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
	#image{}
	| #dice{}
	| #finite_bag{}
	| #open_bag{}
	| #magic_bag{}
	| #hidden_area_tab{}
	| #hidden_area{}
.

-record
(
	attitude,
	{
		x :: non_neg_integer(),
		y :: non_neg_integer(),
		z :: non_neg_integer(),
		angle :: integer(),
	}
).

-type attitude() :: #attitude{}.

-record
(
	object,
	{
		visible_to_ix :: permissions(),
		can_interact_ix :: permissions(),
		width :: non_neg_integer(),
		height :: non_neg_integer(),
		attitude :: attitude(),
		properties :: properties()
	}
).

-type type() :: #object{}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export_type([type/0, attitude/0]).
%%%% Accessors
-export
(
	[
		new/6,

		get_visible_to_ix/1,
		get_can_interact_ix/1,
		get_width/1,
		get_height/1,
		get_x/1,
		get_y/1,
		get_z/1,
		get_angle/1,
		get_properties/1,

		set_visible_to_ix/2,
		set_can_interact_ix/2,
		add_visible_to_ix/2,
		add_can_interact_ix/2,
		remove_visible_to_ix/2,
		remove_can_interact_ix/2,
		set_width/2,
		set_height/2,
		set_x/2,
		set_y/2,
		set_z/2,
		set_angle/2,
		set_properties/2,

		ataxia_set_visible_to_ix/2,
		ataxia_set_can_interact_ix/2,
		ataxia_add_visible_to_ix/2,
		ataxia_add_can_interact_ix/2,
		ataxia_remove_visible_to_ix/2,
		ataxia_remove_can_interact_ix/2,
		ataxia_set_width/2,
		ataxia_set_height/2,
		ataxia_set_x/2,
		ataxia_set_y/2,
		ataxia_set_z/2,
		ataxia_set_angle/2,
		ataxia_update_properties/3,

		get_visible_to_ix_field/0,
		get_can_interact_ix_field/0,
		get_width_field/0,
		get_height_field/0,
		get_x_field/0,
		get_y_field/0,
		get_z_field/0,
		get_angle_field/0,
		get_properties_field/0
	]
).

% Properties functions
-export
(
	[
		maybe_ataxia_flip/1
	]
).

% Web export functions
-export
(
	[
		encode_limited_view/2,
		encode_full_view/1
	]
).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec new
	(
		non_neg_integer(),
		non_neg_integer(),
		non_neg_integer(),
		non_neg_integer(),
		non_neg_integer(),
		properties()
	) -> type().
new (Width, Height, X, Y, Z, Properties) ->
	#object
	{
		visible_to_ix = none,
		can_interact_ix = none,
		width = Width,
		height = Height,
		x = X,
		y = Y,
		z = Z,
		angle = 0,
		properties = Properties
	}.

%%%% GET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_visible_to_ix (type()) -> permissions().
get_visible_to_ix (Object) -> Object#object.visible_to_ix.

-spec get_can_interact_ix (type()) -> permissions().
get_can_interact_ix (Object) -> Object#object.can_interact_ix.

-spec get_width (type()) -> non_neg_integer().
get_width (Object) -> Object#object.width.

-spec get_height (type()) -> non_neg_integer().
get_height (Object) -> Object#object.height.

-spec get_x (type()) -> non_neg_integer().
get_x (Object) -> Object#object.attitude#attitude.x.

-spec get_y (type()) -> non_neg_integer().
get_y (Object) -> Object#object.attitude#attitude.y.

-spec get_z (type()) -> non_neg_integer().
get_z (Object) -> Object#object.attitude#attitude.z.

-spec get_angle (type()) -> integer().
get_angle (Object) -> Object#object.attitude#attitude.angle.

-spec get_properties (type()) -> properties().
get_properties (Object) -> Object#object.properties.

%%%% SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec set_visible_to_ix (permissions(), type()) -> type().
set_visible_to_ix (Value, Object) -> Object#object{ visible_to_ix = Value }.

-spec set_can_interact_ix (permissions(), type()) -> type().
set_can_interact_ix (Value, Object) -> Object#object{ can_interact_ix = Value }.

-spec add_visible_to_ix (non_neg_integer(), type()) -> type().
add_visible_to_ix (Value, Object) ->
	case Object#object.visible_to_ix of
		all -> Object;
		none ->
			Object#object
			{
				visible_to_ix = ordsets:add_element(Value, ordsets:new())
			};

		Ordset -> Object#object{ visible_to_ix = ordsets:add_element(Value, Ordset) }
	end.

-spec add_can_interact_ix (non_neg_integer(), type()) -> type().
add_can_interact_ix (Value, Object) ->
	case Object#object.can_interact_ix of
		all -> Object;
		none ->
			Object#object
			{
				can_interact_ix = ordsets:add_element(Value, ordsets:new())
			};

		Ordset ->
			Object#object
			{
				can_interact_ix = ordsets:add_element(Value, Ordset)
			}
	end.

-spec remove_visible_to_ix (non_neg_integer(), type()) -> type().
remove_visible_to_ix (Value, Object) ->
	case Object#object.visible_to_ix of
		all -> Object;
		none -> Object;
		Ordset -> Object#object{ visible_to_ix = ordsets:del_element(Value, Ordset) }
	end.

-spec remove_can_interact_ix (non_neg_integer(), type()) -> type().
remove_can_interact_ix (Value, Object) ->
	case Object#object.can_interact_ix of
		all -> Object;
		none -> Object;
		Ordset ->
			Object#object{ can_interact_ix = ordsets:del_element(Value, Ordset) }
	end.

-spec set_width (non_neg_integer(), type()) -> type().
set_width (Value, Object) -> Object#object{ width = Value }.

-spec set_height (non_neg_integer(), type()) -> type().
set_height (Value, Object) -> Object#object{ height = Value }.

-spec set_x (non_neg_integer(), type()) -> type().
set_x (Value, Object) ->
	Object#object
	{
		attitude = Object#object.attitude#attitude{ x = Value }
	}.

-spec set_y (non_neg_integer(), type()) -> type().
set_y (Value, Object) ->
	Object#object
	{
		attitude = Object#object.attitude#attitude{ y = Value }
	}.

-spec set_z (non_neg_integer(), type()) -> type().
set_z (Value, Object) ->
	Object#object
	{
		attitude = Object#object.attitude#attitude{ z = Value }
	}.

-spec set_angle (integer(), type()) -> type().
set_angle (Value, Object) ->
	Object#object
	{
		attitude = Object#object.attitude#attitude{ angle = Value }
	}.

-spec set_properties (properties(), type()) -> type().
set_properties (Value, Object) -> Object#object{ properties = Value }.

%%%% ATAXIA SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxia_set_visible_to_ix (permissions(), type()) -> {ataxic:type(), type()}.
ataxia_set_visible_to_ix (Value, Object) ->
	{
		ataxic:update_field(get_visible_to_ix_field(), ataxic:constant(Value)),
		Object#object{ visible_to_ix = Value }
	}.

-spec ataxia_set_can_interact_ix
	(
		permissions(),
		type()
	) -> {ataxic:type(), type()}.
ataxia_set_can_interact_ix (Value, Object) ->
	{
		ataxic:update_field(get_can_interact_ix_field(), ataxic:constant(Value)),
		Object#object{ can_interact_ix = Value }
	}.

-spec ataxia_add_visible_to_ix
	(
		non_neg_integer(),
		type()
	) -> {ataxic:type(), type()}.
ataxia_add_visible_to_ix (Value, Object) ->
	case Object#object.visible_to_ix of
		all -> {ataxic:current_value(), Object};
		Other ->
			{AtaxicInitialSet, InitialSet} =
				case Other of
					none -> {ataxic:constant(ordsets:new()), ordsets:new()};
					Ordset -> {ataxic:field(get_visible_to_ix_field()), Ordset}
				end,
			{
				ataxic:update_field
				(
					get_visible_to_ix_field(),
					ataxic:apply_function
					(
						ordsets,
						add_element,
						[ataxic:constant(Value), AtaxicInitialSet]
					)
				),
				Object#object
				{
					visible_to_ix = ordsets:add_element(Value, InitialSet)
				}
			}
	end.

-spec ataxia_add_can_interact_ix
	(
		non_neg_integer(),
		type()
	) -> {ataxic:type(), type()}.
ataxia_add_can_interact_ix (Value, Object) ->
	case Object#object.can_interact_ix of
		all -> {ataxic:current_value(), Object};
		Other ->
			{AtaxicInitialSet, InitialSet} =
				case Other of
					none -> {ataxic:constant(ordsets:new()), ordsets:new()};
					Ordset -> {ataxic:field(get_can_interact_ix_field()), Ordset}
				end,
			{
				ataxic:update_field
				(
					get_can_interact_ix_field(),
					ataxic:apply_function
					(
						ordsets,
						add_element,
						[ataxic:constant(Value), AtaxicInitialSet]
					)
				),
				Object#object
				{
					can_interact_ix = ordsets:add_element(Value, InitialSet)
				}
			}
	end.

-spec ataxia_remove_visible_to_ix
	(
		non_neg_integer(),
		type()
	) -> {ataxic:type(), type()}.
ataxia_remove_visible_to_ix (Value, Object) ->
	case Object#object.visible_to_ix of
		all -> {ataxic:current_value(), Object};
		none -> {ataxic:current_value(), Object};
		Ordset ->
			{
				ataxic:update_field
				(
					get_visible_to_ix_field(),
					ataxic:apply_function
					(
						ordsets,
						del_element,
						[
							ataxic:constant(Value),
							ataxic:field
							(
								get_visible_to_ix_field(),
								ataxic:current_value()
							)
						]
					)
				),
				Object#object
				{
					visible_to_ix = ordsets:del_element(Value, Ordset)
				}
			}
	end.

-spec ataxia_remove_can_interact_ix
	(
		non_neg_integer(),
		type()
	) -> {ataxic:type(), type()}.
ataxia_remove_can_interact_ix (Value, Object) ->
	case Object#object.can_interact_ix of
		all -> {ataxic:current_value(), Object};
		none -> {ataxic:current_value(), Object};
		Ordset ->
			{
				ataxic:update_field
				(
					get_can_interact_ix_field(),
					ataxic:apply_function
					(
						ordsets,
						del_element,
						[
							ataxic:constant(Value),
							ataxic:field
							(
								get_can_interact_ix_field(),
								ataxic:current_value()
							)
						]
					)
				),
				Object#object
				{
					can_interact_ix = ordsets:del_element(Value, Ordset)
				}
			}
	end.

-spec ataxia_set_width (non_neg_integer(), type()) -> {ataxic:type(), type()}.
ataxia_set_width (Value, S0Object) ->
	S1Object = set_width(Value, S0Object),
	{
		ataxic:update_field
		(
			get_width_field(),
			ataxic:constant(S1Object#object.width)
		),
		S1Object
	}.

-spec ataxia_set_height (non_neg_integer(), type()) -> {ataxic:type(), type()}.
ataxia_set_height (Value, S0Object) ->
	S1Object = set_height(Value, S0Object),
	{
		ataxic:update_field
		(
			get_height_field(),
			ataxic:constant(S1Object#object.height)
		),
		S1Object
	}.

-spec ataxia_set_x (non_neg_integer(), type()) -> {ataxic:type(), type()}.
ataxia_set_x (Value, S0Object) ->
	S1Object = set_x(Value, S0Object),
	{
		ataxic:update_field
		(
			get_attitude_field(),
			ataxic:update_field
			(
				get_x_field(),
				ataxic:constant(Value)
			)
		)
		S1Object
	}.

-spec ataxia_set_y (non_neg_integer(), type()) -> {ataxic:type(), type()}.
ataxia_set_y (Value, S0Object) ->
	S1Object = set_y(Value, S0Object),
	{
		ataxic:update_field
		(
			get_attitude_field(),
			ataxic:update_field
			(
				get_y_field(),
				ataxic:constant(Value)
			)
		),
		S1Object
	}.

-spec ataxia_set_z (non_neg_integer(), type()) -> {ataxic:type(), type()}.
ataxia_set_z (Value, S0Object) ->
	S1Object = set_z(Value, S0Object),
	{
		ataxic:update_field
		(
			get_attitude_field(),
			ataxic:update_field
			(
				get_z_field(),
				ataxic:constant(Value)
			)
		),
		S1Object
	}.

-spec ataxia_set_angle (integer(), type()) -> {ataxic:type(), type()}.
ataxia_set_angle (Value, S0Object) ->
	S1Object = set_angle(Value, S0Object),
	{
		ataxic:update_field
		(
			get_attitude_field(),
			ataxic:update_field
			(
				get_angle_field(),
				ataxic:constant(Value)
			)
		),
		S1Object
	}.

-spec ataxia_update_properties
	(
		ataxic:type(),
		properties(),
		type()
	) -> {ataxic:type(), type()}.
ataxia_update_properties (Update, Value, Object) ->
	{
		ataxic:update_field(get_properties_field(), Update),
		set_properties(Value, Object)
	}.

%%%% Field Accessors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_visible_to_ix_field () -> non_neg_integer().
get_visible_to_ix_field () -> #object.visible_to_ix.

-spec get_can_interact_ix_field () -> non_neg_integer().
get_can_interact_ix_field () -> #object.can_interact_ix.

-spec get_width_field () -> non_neg_integer().
get_width_field () -> #object.width.

-spec get_height_field () -> non_neg_integer().
get_height_field () -> #object.height.

-spec get_attitude_field () -> non_neg_integer().
get_attitude_field () -> #object.attitude.

-spec get_x_field () -> non_neg_integer().
get_x_field () -> #attitude.x.

-spec get_y_field () -> non_neg_integer().
get_y_field () -> #attitude.y.

-spec get_z_field () -> non_neg_integer().
get_z_field () -> #attitude.z.

-spec get_angle_field () -> non_neg_integer().
get_angle_field () -> #attitude.angle.

-spec get_properties_field () -> non_neg_integer().
get_properties_field () -> #object.properties.

%%%% Property Modifiers %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec maybe_ataxia_flip (type()) -> ('error' | {ataxic:type(), type()}).
maybe_ataxia_flip (Object) ->
	case Object#object.properties of
		Image = #image{ is_on_front = IsOnFront } ->
			NewIsOnFront = not(IsOnFront),
			ataxia_update_properties
			(
				ataxic:update_field
				(
					#image.is_on_front,
					ataxic:constant(NewIsOnFront)
				),
				Image#image{ is_on_front = NewIsOnFront },
				Object
			);

		_ -> error
	end.

%%%% Encoders %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec encode_limited_view (non_neg_integer(), type()) -> {list(any())}.
encode_limited_view (_UserIX, _Object) ->
	% TODO: implement.
	{[ ]}.

-spec encode_full_view (type()) -> {list(any())}.
encode_full_view (_Object) ->
	% TODO: implement.
	{[ ]}.
