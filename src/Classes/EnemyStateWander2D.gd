extends State2D
class_name EnemyStateWander2D


########################################################
# Variables                                            #
########################################################


var WANDER_RANGE : int = 200

var target_position : Vector2


########################################################
# Hooks                                                #
########################################################


func _init(target: Node2D).(target):
	name = "Wander"


########################################################
# Setup                                                #
########################################################

func setup_target_position()->void:
	randomize()
	var target_vector = Vector2(
		rand_range(-WANDER_RANGE, WANDER_RANGE),
		rand_range(-WANDER_RANGE, WANDER_RANGE)
	)
	target_position = _Target.global_position + target_vector


########################################################
# Methods                                              #
########################################################


func enter():
	emit_signal("change_animation", "move")
