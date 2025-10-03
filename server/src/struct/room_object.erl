-module(room_object).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record
(
	card,
	{
		front_url :: binary(),
		back_url :: binary(),
		is_flipped :: boolean(),
		is_displayed :: boolean()
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
	deck,
	{
		url :: binary(),
		shows_card :: boolean(),
		contains :: list(ataxia_id:type())
	}
).

-type properties() :: #card{} | #dice{} | #deck{} .

-record
(
	attitude,
	{
		x :: non_neg_integer(),
		y :: non_neg_integer(),
		z :: non_neg_integer(),
		angle :: integer()
	}
).

-type attitude() :: #attitude{}.

-record
(
	object,
	{
		id :: ataxia_id:type(),
		is_locked :: boolean(),
		tags :: ordset:ordset(binary()),
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
		new/5,

		get_id/1,
		get_width/1,
		get_height/1,
		get_attitude/1,
		get_properties/1,
		get_is_locked/1,
		get_tags/1,

		set_id/2,
		set_width/2,
		set_height/2,
		set_attitude/2,
		set_properties/2,
		set_is_locked/2,
		set_tags/2,

		ataxia_set_width/2,
		ataxia_set_height/2,
		ataxia_update_attitude/3,
		ataxia_update_properties/3,
		ataxia_update_tags/3,
		ataxia_set_is_locked/2,

		get_id_field/0,
		get_tags_field/0,
		get_width_field/0,
		get_height_field/0,
		get_attitude_field/0,
		get_properties_field/0,
		get_is_locked_field/0
	]
).

-export
(
	[
		attitude_get_x_field/0,
		attitude_get_y_field/0,
		attitude_get_z_field/0,
		attitude_get_angle_field/0
	]
).

-export([encode/2]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOCAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXPORTED FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec new
	(
		ataxia_id:type(),
		non_neg_integer(),
		non_neg_integer(),
		attitude(),
		properties()
	) -> type().
new (ID, Width, Height, Attitude, Properties) ->
	#object
	{
		id = ID,
		is_locked = false,
		tags = ordset:empty(),
		width = Width,
		height = Height,
		attitude = Attitude,
		properties = Properties
	}.

%%%% GET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec get_id (type()) -> ataxia_id:type().
get_id (#object{ id = Result }) -> Result.

-spec get_width (type()) -> non_neg_integer().
get_width (#object{ width = Result }) -> Result.

-spec get_height (type()) -> non_neg_integer().
get_height (#object{ height = Result }) -> Result.

-spec get_attitude (type()) -> attitude().
get_attitude (#object{ attitude = Result }) -> Result.

-spec get_properties (type()) -> properties().
get_properties (#object{ properties = Result }) -> Result.

-spec get_is_locked (type()) -> boolean().
get_is_locked (#object{ is_locked = Result }) -> Result.

-spec get_tags (type()) -> ordset:ordset(binary()).
get_tags (#object{ tags = Result }) -> Result.

%%%% SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec set_id (ataxia_id:type(), type()) -> type().
set_id (Value, Object) -> Object#object{ id = Value }.

-spec set_width (non_neg_integer(), type()) -> type().
set_width (Value, Object) -> Object#object{ width = Value }.

-spec set_height (non_neg_integer(), type()) -> type().
set_height (Value, Object) -> Object#object{ height = Value }.

-spec set_attitude (attitude(), type()) -> type().
set_attitude (Attitude, Object) -> Object#object{ attitude = Attitude }.

-spec set_properties (properties(), type()) -> type().
set_properties (Value, Object) -> Object#object{ properties = Value }.

-spec set_is_locked (boolean(), type()) -> type().
set_is_locked (Value, Object) -> Object#object{ is_locked = Value }.

-spec set_tags (ordset:ordset(binary()), type()) -> type().
set_tags (Value, Object) -> Object#object{ tags = Value }.

%%%% ATAXIA SET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec ataxia_set_is_locked (boolean(), type()) -> {ataxic:type(), type()}.
ataxia_set_is_locked (Value, S0Object) ->
	S1Object = set_is_locked(Value, S0Object),
	{
		ataxic:update_field
		(
			get_is_locked_field(),
			ataxic:constant(S1Object#object.is_locked)
		),
		S1Object
	}.

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

-spec ataxia_update_attitude
	(
		ataxic:type(),
		attitude(),
		type()
	)
	-> {ataxic:type(), type()}.
ataxia_update_attitude (AtaxicUpdate, Attitude, Object) ->
	{
		ataxic:update_field(get_attitude_field(), AtaxicUpdate),
		set_attitude(Attitude, Object)
	}.

-spec ataxia_update_tags
	(
		ataxic:type(),
		ordset:ordset(binary()),
		type()
	)
	-> {ataxic:type(), type()}.
ataxia_update_tags (AtaxicUpdate, Tags, Object) ->
	{
		ataxic:update_field(get_tags_field(), AtaxicUpdate),
		set_tags(Tags, Object)
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
-spec get_width_field () -> non_neg_integer().
get_width_field () -> #object.width.

-spec get_height_field () -> non_neg_integer().
get_height_field () -> #object.height.

-spec get_tags_field () -> non_neg_integer().
get_tags_field () -> #object.tags.

-spec get_is_locked_field () -> non_neg_integer().
get_is_locked_field () -> #object.is_locked.

-spec get_id_field () -> non_neg_integer().
get_id_field () -> #object.id.

-spec get_attitude_field () -> non_neg_integer().
get_attitude_field () -> #object.attitude.

-spec attitude_get_x_field () -> non_neg_integer().
attitude_get_x_field () -> #attitude.x.

-spec attitude_get_y_field () -> non_neg_integer().
attitude_get_y_field () -> #attitude.y.

-spec attitude_get_z_field () -> non_neg_integer().
attitude_get_z_field () -> #attitude.z.

-spec attitude_get_angle_field () -> non_neg_integer().
attitude_get_angle_field () -> #attitude.angle.

-spec get_properties_field () -> non_neg_integer().
get_properties_field () -> #object.properties.

%%%% Encoders %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-spec encode_properties (type()) -> {list({binary(), any()})}.
encode_properties
(
	#deck
	{
		url = Url,
		shows_card = ShowsCard,
		contains = Contains
	}
) ->
	{
		[
			{?TYPE_FIELD, ?DECK_OBJECT_TYPE},
			{?URL_FIELD, Url},
			{?SHOWS_CARD_FIELD, ShowsCard},
			{?CONTAINS_FIELD, Contains}
		]
	};
encode_properties
(
	#dice
	{
		faces = Faces,
		active_face = ActiveFace
	}
) ->
	{
		[
			{?TYPE_FIELD, ?DICE_OBJECT_TYPE},
			{?FACES_FIELD, Faces},
			{?ACTIVE_FACE_FIELD, ActiveFace}
		]
	};
encode_properties
(
	#card
	{
		front_url = FrontUrl,
		back_url = BackUrl,
		is_flipped = IsFlipped,
		is_displayed = IsDisplayed
	}
) ->
	{
		[
			{?TYPE_FIELD, ?CARD_OBJECT_TYPE},
			{?FRONT_FIELD, FrontUrl},
			{?BACK_FIELD, BackUrl},
			{?IS_FLIPPED_FIELD, IsFlipped},
			{?IS_DISPLAYED_FIELD, IsDisplayed}
		]
	}.

-spec encode (type()) -> {list({binary(), any()})}.
encode (Object) ->
	Attitude = Object#object.attitude,
	{
		[
			{?ID_FIELD, Object#object.id},
			{?IS_LOCKED_FIELD, Object#object.is_locked},
			{?TAGS_FIELD, Object#object.tags},
			{?WIDTH_FIELD, Object#object.width},
			{?HEIGHT_FIELD, Object#object.height},
			{?X_FIELD, Attitude#attitude.x},
			{?Y_FIELD, Attitude#attitude.y},
			{?Z_FIELD, Attitude#attitude.z},
			{?ANGLE_FIELD, Attitude#attitude.angle},
			{?PROPERTIES_FIELD, encode_properties(Object#object.properties)}
		]
	}.
