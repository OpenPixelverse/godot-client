extends Area2D
class_name SelectableArea2D


# Action that can be triggered.
var action_string: String


# Signals of this class.
signal trigger_action(action, data)


# Build up the selectable area.
func _init(data: Dictionary, scale_factor: float = 1):
	if data.has("name"):
		name = data.name
	if data.has("shape"):
		setup_shape(data.shape)
	if data.has("action"):
		setup_action(data.action)


# Setup the shape of the area.
func setup_shape(data: Dictionary):
	Builder2D.add_collision_shape(self, data)


# Setup the clickable action.
func setup_action(action: String)->void:
	# Save the action string for later use.
	action_string = action


# Catch the input event from the mouse.
func _input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("select") or (event is InputEventScreenTouch and event.pressed):
		emit_signal("trigger_action", action_string)
