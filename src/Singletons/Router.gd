extends Node


########################################################
# Member Variables                                     #
########################################################


# The Server singleton will connect to the game environment through the
#  Client node so it makes sense to load it right away.
onready var _Client = get_node("/root/Client")


########################################################
# Helpers                                              #
########################################################


# Called whenever we need to verify that the incoming request or response
#  was sent from our game server.
func security_check()->void:
	assert(get_tree().get_rpc_sender_id() == 1, "Request was not sent by server!!!")


########################################################
# Routes                                               #
########################################################


########################################################
# Clock


# Called when we load the latency.
func determine_latency()->void:
	# we simply send the current client time to the server, who
	#  will send the client time back. The difference is our
	#  current latency (for a 2 way connection; to the server and back).
	rpc_id(1, "determine_latency", OS.get_system_time_msecs())


# Called when we receive the data we need to calculate the
#  latency. The data in this case is the client time that
#  we sent out in `determineLatency()`
remote func receive_latency(client_time)->void:
	security_check()
	# Udate the latency on the Clock.
	Clock.receive_latency(client_time)


# Called in order to fetch the server time.
func fetch_server_time()->void:
	# load the server time
	rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())


# Called when the server returns the the server time.
remote func receive_server_time(server_time, client_time):
	security_check()
	Clock.receive_server_time(server_time, client_time)


########################################################
# Client


## Fetch client data from the server.
#func load_client_data(world: String)->void:
#	rpc_id(1, "load_client_data", world)


## Receive client data from server.
#remote func receive_client_data(data: Dictionary)->void:
#	security_check()
##	_Client.receive_client_data(data)


########################################################
# World


# Load initial world data from the server.
func load_world_data(world : String = "default")->void:
	rpc_id(1, "load_world_data", world)


# Receive the initial world data from the server.
remote func receive_world_data(world_data : Dictionary)->void:
	security_check()
	_Client._receive_world_data(world_data)


# Receive the world state from the server.
remote func receive_world_state(world_state : Dictionary)->void:
	security_check()
	_Client._receive_world_state(world_state)
