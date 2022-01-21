extends Node2D
class_name ObjectsContainer2D


########################################################
# Variables                                            #
########################################################


var available_containers : Dictionary


########################################################
# Hooks                                                #
########################################################


func _init(objects: Array)->void:
	setup_objects(objects)


########################################################
# Setup                                                #
########################################################


# Add the objects as child nodes.
func setup_objects(objects: Array)->void:
	# add objects
	for object in objects:
		add_object(object)


# Add an object as child node.
func add_object(object: Dictionary)->void:
	assert(object.has("type"), "[ObjectsContainer2D] No type provided in object data.")
	
	match object.type:
		"flat":
			assert(false, "[ObjectsContainer2D] Object type 'flat' is not yet implemented.")
		"static":
			add_static_object(object)
		"dynamic":
			assert(false, "[ObjectsContainer2D] Object type 'dynamic' is not yet implemented.")
		_:
			assert(false, "[ObjectsContainer2D] Object type '" + str(object.type) + "' is not yet implemented.")


# Add static object as child node.
func add_static_object(object: Dictionary)->void:
	assert(object.has("type") and object.type == "static", "[ObjectsContainer2D] Object type provided is not 'static'.")
	
	var _Object = StaticObject2D.new(object)
	var _StaticObjectsContainer
	
	if has_node("StaticObjects"):
		_StaticObjectsContainer = get_node("StaticObjects")
	else:
		_StaticObjectsContainer = create_container("static")
		add_child(_StaticObjectsContainer)
	
	_StaticObjectsContainer.add_child(_Object)
	
	available_containers["static"] = _StaticObjectsContainer


func create_container(type : String):
	var _Container
	
	match type:
		"static":
			_Container = StaticObjectsContainer2D.new()
			_Container.name = "StaticObjects"
		_:
			assert(false, "[ObjectsContainer2D] Contianer type '" + str(type) + "' not implemented yet.")
	
	return _Container


########################################################
# World State Buffer                                   #
########################################################


func interpolate_elements(interpolation_factor : float, world_state_buffer : Array)->void:
	for element in world_state_buffer[2]["objects"]:
		if not available_containers.has(element):
			var _StaticObjectsContainer = create_container(element)
			add_child(_StaticObjectsContainer)
			available_containers[element] = _StaticObjectsContainer
		available_containers[element].interpolate_elements(interpolation_factor, world_state_buffer)


func extrapolate_elements(extrapolation_factor : float, world_state_buffer : Dictionary)->void:
	for element in world_state_buffer[2]["objects"]:
		if not available_containers.has(element):
			var _StaticObjectsContainer = create_container(element)
			add_child(_StaticObjectsContainer)
			available_containers[element] = _StaticObjectsContainer
		available_containers[element].extrapolate_elements(extrapolation_factor, world_state_buffer)
