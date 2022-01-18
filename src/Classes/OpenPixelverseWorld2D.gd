extends Node2D
class_name OpenPixelverseWorld2D


########################################################
# Variables                                            #
########################################################


var _ObjectsContainer : ObjectsContainer2D
#var _SubjectsContainer : SubjectsContainer2D


########################################################
# Hooks                                                #
########################################################


func _init(data: Dictionary)->void:
	setup_world(data)


########################################################
# Setup                                                #
########################################################


# Setup the world instance.
func setup_world(data: Dictionary)->void:
	setup_environment(data) # child index 0
	setup_background(data) # child index 1
	setup_limits(data)
	
	setup_objects(data)
#	setup_subjects(data) # This will be handled through the world state handling.


# Setup the environment.
func setup_environment(data: Dictionary)->void:
	if data.has("environment"):
		var _Environment = Builder2D.build_environment(data.environment)
		var _WorldEnvironment = WorldEnvironment.new()
		_WorldEnvironment.set_environment(_Environment)
		add_child(_WorldEnvironment)
		move_child(_WorldEnvironment, 0)


# Setup the world limits from data.
func setup_limits(data: Dictionary)->void:
	# Only proceed if we got data for the limits.
	if data.has("limits"):
		# Validate world limits.
		assert(data.limits.has("top"), "[OpenPixelverseWorld2D] No top limit provided in world limits.")
		assert(data.limits.has("bottom"), "[OpenPixelverseWorld2D] No bottom limit provided in world limits.")
		assert(data.limits.has("left"), "[OpenPixelverseWorld2D] No left limit provided in world limits.")
		assert(data.limits.has("right"), "[OpenPixelverseWorld2D] No right limit provided in world limits.")
		# Create container node for limits.
		var _Limits = Node2D.new()
		_Limits.name = "Limits"
		# Setup the world limits.
		_Limits.add_child(build_border("Border Top", Vector2(data.limits.right, 1), Vector2(0, -2)))
		_Limits.add_child(build_border("Border Right", Vector2(1, data.limits.bottom), Vector2(data.limits.right + 2, 0)))
		_Limits.add_child(build_border("Border Bottom", Vector2(data.limits.right, 1), Vector2(0, data.limits.bottom + 2)))
		_Limits.add_child(build_border("Border Left", Vector2(1, data.limits.bottom), Vector2(-2, 0)))
		# Add the container node as child node of the world.
		add_child(_Limits)# Setup the background of the map.


func setup_background(data: Dictionary):
	# Only proceed if we got data for the background.
	if data.has("background"):
		var _SpriteImage = Helper.decode_base64(data.background.texture.data, data.background.texture.type)
		var _Background = Sprite.new()
		_Background.name = "Background"
		_Background.region_rect = Rect2(data.background.rect.x, data.background.rect.y, data.background.rect.w, data.background.rect.h)
		_Background.scale = Vector2(data.background.scale, data.background.scale)
		_Background.centered = data.background.centered
		_Background.region_enabled = data.background.region
		var _Texture = ImageTexture.new()
		_Texture.create_from_image(_SpriteImage, Texture.FLAG_REPEAT)
		_Background.set_texture(_Texture)
		
		add_child(_Background)
		move_child(_Background, 1)


# Build border from data.
func build_border(name: String, extents: Vector2, position: Vector2)->StaticBody2D:
	var _Border = StaticBody2D.new()
	_Border.name = name
	_Border.position = position
	var _CollisionShape = CollisionShape2D.new()
	_CollisionShape.name = "CollisionShape"
	var _Shape = RectangleShape2D.new()
	_Shape.set_extents(extents)
	_CollisionShape.set_shape(_Shape)
	_Border.add_child(_CollisionShape)
	return _Border


# Setup the objects node and all it's childs.
func setup_objects(data: Dictionary)->void:
	if data.has("objects") and data.objects.size():
		_ObjectsContainer = ObjectsContainer2D.new(data.objects)
		_ObjectsContainer.name = "Objects"
		add_child(_ObjectsContainer)
