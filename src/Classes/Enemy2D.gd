extends Subject2D
class_name Enemy2D


########################################################
# Hooks                                                #
########################################################


func _init(name : String)->void:
	Router.load_subject_data("enemy", name)


########################################################
# Setup                                                #
########################################################


# Setup the available states of the subject.
func setup_states(data: Dictionary)->void:
	if data.has("states"):
		var start_state = "idle"
		if data.has("start_state"):
			start_state = data.start_state
		_States = EnemyStateMachine2D.new(self, data.states, start_state)
		_States.name = "States"
		add_child(_States)
		_States.connect("change_animation", self, "_on_change_animation")
