extends YSort
class_name StaticObjectsContainer2D


########################################################
# Methods                                              #
########################################################


# Spawn a static object as a child node of this container.
func spawn_static_object(data : Dictionary)->void:
	var _StaticObject = StaticObject2D.new(data)
	add_child(_StaticObject)


########################################################
# World State Buffer                                   #
########################################################


########################################################
# Interpolation


func interpolate_elements(interpolation_factor : float, world_state_buffer : Array)->void:
	var current_world_state = world_state_buffer[1]["objects"]["static"]
	var future_world_state = world_state_buffer[2]["objects"]["static"]
	for element in future_world_state:
		# Do not proceed if the element is not yet present in the 
		#  current world state.
		if not current_world_state.has(element):
			continue
			
		# Get the object data from the world states.
		var current_data = current_world_state[element]
		var future_data = future_world_state[element]
		
		# If the object is present, we want to update it.
		if has_node(element):
			# Get the object to update.
			var _Object = get_node(element)
			# Update the object state if present.
			if future_data.has("state"):
				_Object.state = future_data.state
			# Update position if present.
			if current_data.has("position") and future_data.has("position"):
				# Only update if the position has changed.
				if current_data.position != future_data.position:
					var new_position = lerp(current_data.position, future_data.position, interpolation_factor)
					_Object.set_position(new_position)
		# Otherwise we want to spawn it.
		else:
			spawn_static_object(current_data)


########################################################
# Extrapolation


func extrapolate_elements(extrapolation_factor : float, world_state_buffer : Array)->void:
	var past_world_state = world_state_buffer[0]["objects"]["static"]
	var current_world_state = world_state_buffer[1]["objects"]["static"]
	
	for element in current_world_state:
		# Do not proceed if the element is not yet present in the 
		#  current world state.
		if not past_world_state.has(element):
			continue
			
		# Get the object data from the world states.
		var past_data = past_world_state[element]
		var current_data = current_world_state[element]
		
		# If the object is present, we want to update it.
		if has_node(element):
			# Get the object to update.
			var _Object = get_node(element)
			# Update the object state if present.
			if current_data.has("state"):
				_Object.state = current_data.state
			# Update position if present.
			if current_data.has("position") and past_data.has("position"):
				var position_delta = (current_data.position - past_data.position)
				var new_position = current_data.position + (position_delta * extrapolation_factor)
		# Otherwise we want to spawn it.
		else:
			spawn_static_object(current_data)
