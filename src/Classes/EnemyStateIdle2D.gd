extends State2D
class_name EnemyStateIdle2D


########################################################
# Variables                                            #
########################################################


########################################################
# Hooks                                                #
########################################################


func _init(target: Node2D).(target):
	name = "Idle"


func _on_action_timer_timeout():
	emit_signal("finished", "wander")


########################################################
# Methods                                              #
########################################################


func enter():
	emit_signal("change_animation", "idle")
