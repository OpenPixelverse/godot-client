extends Node2D
class_name OpenPixelverseWorld2D


########################################################
# Variables                                            #
########################################################


var _ObjectsContainer : ObjectsContainer2D
var _SubjectsContainer : SubjectsContainer2D


var render_time : int = 0
var last_world_state_time : int = 0
var world_state_buffer : Array = []
var interpolation_offset : int = Config.get_value("World State Buffer", "interpolation_offset", null)
var elements_to_parse : Dictionary = {}


########################################################
# Hooks                                                #
########################################################


func _init(data: Dictionary)->void:
	setup_world(data)


func _ready()->void:
	update_render_time()


func _physics_process(delta)->void:
	handle_world_state()


func _receive_world_state(world_state : Dictionary)->void:
	update_world_state(world_state)


func _receive_subject_data(type : String, name, data : Dictionary)->void:
	if _SubjectsContainer:
		_SubjectsContainer._receive_subject_data(type, name, data)

########################################################
# Setup                                                #
########################################################


# Setup the world instance.
func setup_world(data: Dictionary)->void:
	setup_environment(data) # child index 0
	setup_background(data) # child index 1
	setup_limits(data)
	
	setup_objects(data)
	setup_subjects_container()


# Setup the environment.
func setup_environment(data: Dictionary)->void:
	if data.has("environment"):
		var _Environment = Builder2D.build_environment(data.environment)
		var _WorldEnvironment = WorldEnvironment.new()
		_WorldEnvironment.set_environment(_Environment)
		_WorldEnvironment.name = "WorldEnvironment"
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
		elements_to_parse["objects"] = _ObjectsContainer


# Setup the subjects node. No subjects are spawned yet.
func setup_subjects_container()->void:
	_SubjectsContainer = SubjectsContainer2D.new()
	_SubjectsContainer.name = "Subjects"
	add_child(_SubjectsContainer)
	elements_to_parse["subjects"] = _SubjectsContainer


########################################################
# World State Buffer                                   #
########################################################

# I decided to make the world state buffer part of the 
#  world class itself in this project.


# Add to the world state.
func update_world_state(world_state : Dictionary)->void:
	# Only update the world state if the creation time of the world state
	#  is more current than the one we we already have
	if world_state["time"] > last_world_state_time:
		# Save the last timestamp.
		last_world_state_time = world_state["time"]
		# Add the received worldstate to the worldstate buffer.
		world_state_buffer.append(world_state)


# Handle world state.
func handle_world_state()->void:
	# Calculate the render time for this loop.
	update_render_time()
	# Reduce the world state buffer to the relevant elements.
	reduce_buffer()
	# Assert that all entries in the world state have a timestamp.
	for world_state in world_state_buffer:
		assert(world_state.has("time"), "[OpenPixelverseWorld2D] A given state does not have a timestamp attached.")
	# If there are more than 2 states left after reducing them,
	#  we know that there is a future world state that we can interpoate to.
	if world_state_buffer.size() > 2:
		interpolate()
	# Otherwise we want to be extrapolating.
	elif world_state_buffer.size() > 1 and render_time > world_state_buffer[1]["time"]:
		extrapolate()


# Update the render_time so it can be used in the other calculations.
func update_render_time()->void:
	render_time = Clock.client_clock - interpolation_offset


# Called whenever whe need to reduce the world state buffer to the relevant elements.
func reduce_buffer():
	# Clean up the world_state_buffer to not waste memory.
	while world_state_buffer.size() > 3 and render_time > world_state_buffer[2]['time']:
		world_state_buffer.remove(0)


# Called whenever we need to interpolate the world state buffer.
func interpolate():
	# Calculate the interpolation factor. This factor will let us know 
	#  how far away the render time, the last world state and
	#  the nearest future buffer entries are.
	var interpolation_factor = float(render_time - world_state_buffer[1]["time"]) / float(world_state_buffer[2]["time"] - world_state_buffer[1]["time"])
	# Now we can do the actual interpolation.
	for buffer_key in elements_to_parse.keys():
		if elements_to_parse.has(buffer_key) and elements_to_parse[buffer_key]:
			var parent_node = elements_to_parse[buffer_key]
			parent_node.interpolate_elements(interpolation_factor, world_state_buffer)


# Called whenever we need to interpolate some elements on the world state buffer.
func extrapolate():
	# In order to extrapolate we need the extrapolation factor. This factor will 
	#  let us know how far away the render time, the last world state and
	#  the nearest future buffer entries are.
#	var extrapolation_factor = float(render_time - world_state_buffer[1]["time"]) / float(world_state_buffer[2]["time"] - world_state_buffer[1]["time"]) - 1.00
	# FIXME: I believe that this should be the following ...
	var extrapolation_factor = float(render_time - world_state_buffer[0]["time"]) / float(world_state_buffer[1]["time"] - world_state_buffer[0]["time"]) - 1.00
	# Now we can do the actual extrapolation of the elements.
	for buffer_key in elements_to_parse.keys():
		if elements_to_parse.has(buffer_key) and elements_to_parse[buffer_key]:
			print("extrapolate_elements")
			var parent_node = elements_to_parse[buffer_key]
			parent_node.extrapolate_elements(extrapolation_factor, world_state_buffer)
