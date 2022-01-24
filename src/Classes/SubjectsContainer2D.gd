extends YSort
class_name SubjectsContainer2D


var _EnemiesContainer : EnemiesContainer2D


########################################################
# Hooks                                                #
########################################################


func _init()->void:
	setup_subject_containers()


func _receive_subject_data(type : String, name : String, data : Dictionary)->void:
	receive_subject_data(type, name, data)


########################################################
# Setup                                                #
########################################################


# Setup the child containers for players, enemies and others.
func setup_subject_containers()->void:
	_EnemiesContainer = EnemiesContainer2D.new()
	_EnemiesContainer.name = "Enemies"
	add_child(_EnemiesContainer)


func receive_subject_data(type : String, name : String, data : Dictionary)->void:
	match type:
		"player": 
			assert(false, "[SubjectsContainer2D] Subjects of type 'player' are not yet implemented.")
		"enemy":
			_EnemiesContainer._receive_subject_data(name, data)
		_:
			assert(false, "[SubjectsContainer2D] Subjects of type '" + type + "' are not yet implemented.")


########################################################
# World State Buffer                                   #
########################################################


########################################################
# Interpolation


func interpolate_elements(interpolation_factor : float, world_state_buffer : Array)->void:
	for element in world_state_buffer[2]["subjects"]:
		match element:
			"enemies":
				_EnemiesContainer.interpolate_elements(interpolation_factor, world_state_buffer)
			_:
				assert(false, "[SubjectsContainer2D] Container node for '" + str(element) + "' not yet implemented.")
