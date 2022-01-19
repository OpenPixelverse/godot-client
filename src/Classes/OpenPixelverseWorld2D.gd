extends Node2D
class_name OpenPixelverseWorld2D


########################################################
# Variables                                            #
########################################################


var _ObjectsContainer : ObjectsContainer2D
#var _SubjectsContainer : SubjectsContainer2D


var render_time : int = 0
var last_world_state_time : int = 0
var world_state_buffer : Array = []
var interpolation_offset : int = Config.get_value("World State Buffer", "interpolation_offset", null)
var elements_to_parse = { # TODO
	"objects": _ObjectsContainer
}


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
	# If we have less than 3 entries we can simply skip the processing.
	if world_state_buffer.size() > 3:
		handle_world_state_buffer()


# Update the render_time so it can be used in the other calculations.
func update_render_time()->void:
	render_time = Clock.client_clock - interpolation_offset


# Called through the physics process in order to handle the world state buffer.
func handle_world_state_buffer():
	# Reduce the world state buffer to the relevant elements.
	reduce_buffer()
	# If the time of the world state buffer 1 (0,1,2) is past the render_time,
	#  we know, that we do not have a future world state, so we need to 
	#  extrapolate.
	if world_state_buffer[1].time < render_time:
		print("extrapolate")
		extrapolate()
	elif world_state_buffer:
		print("interpolate")
		interpolate()


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
		if elements_to_parse.has(buffer_key):
			var parent_node = elements_to_parse[buffer_key]
			parent_node.interpolate_elements(interpolation_factor, world_state_buffer)
#		interpolate_elements(buffer_key, interpolation_factor, parent_node)


# Called whenever we need to interpolate some elements on the world state buffer.
func interpolate_elements(buffer_key: String, interpolation_factor: float, parent_node, exclude: Array = []):
	# Loop through the elements in order to change their position.
	for element in world_state_buffer[2][buffer_key].keys():
		# Exclude the elements we want to exclude.
		if exclude.has(element):
			continue
		# We also skip if the element is not yet on our _current_ world state
		if not world_state_buffer[1][buffer_key].has(element):
			continue
		# If the element is already on the map we should move it.
		if parent_node.has_node(str(element)):
			# Get the subject.
			var _Subject = parent_node.get_node(str(element))
			# Get subject data out of the world state.
			var subject_data = world_state_buffer[2][buffer_key][element]
			# Set the state and states of the object.
			_Subject.stats = subject_data.stats
			# we calculate the new position with the lerp function
			var new_position = lerp(world_state_buffer[1][buffer_key][element]["position"], world_state_buffer[2][buffer_key][element]["position"], interpolation_factor)
			# If we receive the position of the player, we need to do a smooth correction.
			if element == str(Config.get_value("Network", "player_id")):
				var corrected_position = (new_position + _Subject.position) / 2
				print("start")
				print(new_position)
				print(_Subject.position)
				print(corrected_position)
#				_Subject.set_global_position(corrected_position)
			else:
				# Pass the new position to the subject.
				_Subject.new_position = new_position
				# Update the state of the subject.
				_Subject.state = subject_data.state
		# If the element is not yet on the map we need to spawn it.
		else:
			var subject_data = world_state_buffer[1][buffer_key][element]
			parent_node.spawn_subject(element, subject_data)


# Called whenever we need to interpolate some elements on the world state buffer.
func extrapolate():
	# In order to extrapolate we need the extrapolation factor. This factor will 
	#  let us know how far away the render time, the last world state and
	#  the nearest future buffer entries are.
	var extrapolation_factor = float(render_time - world_state_buffer[1]["time"]) / float(world_state_buffer[2]["time"] - world_state_buffer[1]["time"]) - 1.00
	# Now we can do the actual extrapolation of the elements.
	for buffer_key in elements_to_parse.keys():
		if elements_to_parse.has(buffer_key):
			var parent_node = elements_to_parse[buffer_key]
			parent_node.extrapolate_elements(extrapolation_factor, world_state_buffer)
#		extrapolate_elements(buffer_key, extrapolation_factor, parent_node, [Config.get_value("Network", "player_id")])


# Called whenever we need to interpolate some elements on the world state buffer.
func extrapolate_elements(buffer_key: String, extrapolation_factor: float, parent_node, exclude: Array = []):
	# Loop through the elements in order to change their position.
	for element in world_state_buffer[2][buffer_key].keys():
		# Exclude the elements we want to exclude.
		if exclude.has(element):
			continue
		# We also skip if the element is not yet on our _current_ world state
		if not world_state_buffer[1][buffer_key].has(element):
			continue
		# If the element is already on the map we should move it.
		if parent_node.has_node(str(element)):
			# Get the subject.
			var _Subject = parent_node.get_node(str(element))
			# we calculate the new position with the lerp function
			# Get subject data out of the world state.
			var subject_data = world_state_buffer[1][buffer_key][element]
			# Set the state and states of the object.
			_Subject.stats = subject_data.stats
			# Steps that should not affect the player.
			if element != str(Config.get_value("Network", "player_id")):
				var position_delta = (world_state_buffer[1][buffer_key][element]["position"] - world_state_buffer[0][buffer_key][element]["position"])
				var new_position = world_state_buffer[1][buffer_key][element]["position"] + (position_delta * extrapolation_factor)
				# Pass the new position to the subject.
				_Subject.new_position = new_position
				# Update the state of the subject.
				_Subject.state = subject_data.state
		# If the element is not yet on the map we need to spawn it.
		else:
			var subject_data = world_state_buffer[1][buffer_key][element]
			parent_node.spawn_subject(element, subject_data)
