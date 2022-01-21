extends YSort
class_name SubjectsContainer2D


var _EnemiesContainer : EnemiesContainer2D


########################################################
# Hooks                                                #
########################################################


func _init()->void:
	setup_subject_containers()


########################################################
# Setup                                                #
########################################################


# Setup the child containers for players, enemies and others.
func setup_subject_containers()->void:
	_EnemiesContainer = EnemiesContainer2D.new()


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
