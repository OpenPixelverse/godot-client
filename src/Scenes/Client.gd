extends Node


########################################################
# Signals                                              #
########################################################


signal connection_succeeded()
signal client_loaded()


########################################################
# Hooks                                                #
########################################################


# Called when the node is "ready".
func _ready()->void:
	connect_to_server()
	# World is going to be setup through signal once the
	#  server has loaded.


# Called when the Server connection succeeded.
func _on_connection_succeeded()->void:
	# Load the client data from the server.
	Router.load_world_data(Config.get_value("World", "world", "default"))


# Called when we failed to connect to the server
func _on_connection_failed()->void:
	push_error("Failed to connect to game server!")


# Receive the inital world data from the server.
func _receive_world_data(world_data : Dictionary)->void:
	setup_world(world_data)


########################################################
# Setup                                                #
########################################################


# Setup the game world as child of the client node.
func setup_world(world_data : Dictionary)->void:
	# Validate type.
	assert(world_data.has("type"), "[Client] No type in world data.")
	
	# Create container variable for world node.
	var _World
	
	# Match the type.
	match world_data.type:
		"2D":
			_World = OpenPixelverseWorld2D.new(world_data)
		_:
			assert(false, "[Client] No valid type in world data.")
	
	
	# Set the name of the world node to "World".
	_World.name = "World"
	
	# Add the world node as child to the client.
	add_child(_World)


########################################################
# Methods                                              #
########################################################


# Connect to the game server.
func connect_to_server()->void:
	# Connect to the game server.
	var url = str(Config.get_value("Server", "url")) + ":" + str(Config.get_value("Server", "port"))
	var _WebSocketClient = WebSocketClient.new()
	_WebSocketClient.connect_to_url(url, PoolStringArray(["ludus"]), true)
	# Set _WebSocketClient as network peer in order to use the server.
	get_tree().set_network_peer(_WebSocketClient)
	
	# Connect the events for connection failed and succeeded.
	# warning-ignore:return_value_discarded
	_WebSocketClient.connect("connection_failed", self, "_on_connection_failed")
	# warning-ignore:return_value_discarded
	_WebSocketClient.connect("connection_succeeded", self, "_on_connection_succeeded")
