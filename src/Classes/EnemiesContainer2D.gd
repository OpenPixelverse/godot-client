extends Node2D
class_name EnemiesContainer2D


########################################################
# Methods                                              #
########################################################


# Spawn enemy as a child of this container.
func spawn_enemy(data : Dictionary)->void:
	var _Enemy = Enemy2D.new(data)
	add_child(_Enemy)


########################################################
# World State Buffer                                   #
########################################################


########################################################
# Interpolation


func interpolate_elements(interpolation_factor : float, world_state_buffer : Array)->void:
	var current_world_state = world_state_buffer[1]["subjects"]["enemies"]
	var future_world_state = world_state_buffer[2]["subjects"]["enemies"]
	
	for element in future_world_state:
		# Do not proceed if the element is not yet present in the 
		#  current world state.
		if not current_world_state.has(element):
			continue
			
		# Get the subject data from the world states.
		var current_data = current_world_state[element]
		var future_data = future_world_state[element]
		
		# If the subject is present, we want to update it.
		if has_node(element):
			# Get the subject to update.
			var _Subject = get_node(element)
			# Update the subject state if present.
			if future_data.has("state"):
				_Subject.state = future_data.state
			# Update position if present.
			if current_data.has("position") and future_data.has("position"):
				# Only update if the position has changed.
				if current_data.position != future_data.position:
					var new_position = lerp(current_data.position, future_data.position, interpolation_factor)
					_Subject.set_position(new_position)
		# Otherwise we want to spawn it.
		else:
			spawn_enemy(current_data)
