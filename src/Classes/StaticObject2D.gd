extends StaticBody2D
class_name StaticObject2D


########################################################
# Member Variables                                     #
########################################################


# States
const DEFAULT : String = "default"

# Default state
var state : String = DEFAULT

# Stats
var stats : Dictionary


# Events
var events = {}

# Dialogs
var dialogs = {}


########################################################
# Hooks                                                #
########################################################


func _init(object: Dictionary)->void:
	setup_object(object)


func _on_trigger_action(action : String)->void:
	if events.has(action):
		Helper.handle_dialog_event(events[action], self)


########################################################
# Setup                                                #
########################################################


# Setup the object instance.
func setup_object(object: Dictionary)->void:
	setup_name(object)
	setup_sprite(object)
	setup_collision_shape(object)
	setup_position(object)
	setup_clickable_areas(object)
	setup_scale_factor(object)
	setup_events(object)
	setup_dialogs(object)


# Setup the name of this object.
func setup_name(data: Dictionary)->void:
	if data.has("name"):
		name = data.name


# Setup the collision shape of this object.
func setup_collision_shape(data: Dictionary)->void:
	if data.has("collision_shape"):
		Builder2D.add_collision_shape(self, data.collision_shape)


# Setup the position of the object.
func setup_position(data: Dictionary)->void:
	if data.has("position"):
		set_position(data.position)


# Setup the scale_factor for the object.
func setup_scale_factor(data: Dictionary)->void:
	if data.has("scale_factor"):
		set_scale(Vector2(data.scale_factor, data.scale_factor))


# Setup sprite.
func setup_sprite(data: Dictionary)->void:
	# Check if we have data for the sprite.
	if data.has("sprite"):
		# Add sprite for animation to the subject.
		Builder2D.add_sprite(self, data.sprite)


# Setup clickable areas.
func setup_clickable_areas(data: Dictionary)->void:
	# Check if we have areas to setup.
	if data.has("areas"):
		# Loop through the areas and set them up.
		for area in data.areas:
			var _Area = SelectableArea2D.new(area)
			_Area.connect("trigger_action", self, "_on_trigger_action")
			add_child(_Area)


# Setup the events that we want to be able to trigger.
func setup_events(data: Dictionary)->void:
	# Check if we have event data.
	if data.has("events"):
		# Add the events to the events dictionary.
		events = data.events


# Setup the dialogs.
func setup_dialogs(data: Dictionary)->void:
	# check if we have dialog data.
	if data.has("dialogs"):
		dialogs = data.dialogs


########################################################
# Methods                                              #
########################################################


# Open dialog from the list of available dialogs.
func open_dialog(dialog: String)->void:
	var _Dialog = Builder2D.build_dialog(dialog, dialogs[dialog])
	add_child(_Dialog)
	_Dialog.connect("dialogic_signal", self, "_on_trigger_action")
