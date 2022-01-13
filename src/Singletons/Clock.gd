extends Node


########################################################
# Notes                                                #
########################################################


# Followed the YouTube tutorial of the Game Development Center.
# => https://www.youtube.com/watch?v=TwVT3Qx9xEM


########################################################
# Member Variables                                     #
########################################################

var latency : int = 0
var latency_array : Array = []
var delta_latency :  = 0
var decimal_collector : float = 0
var client_clock = 0

onready var _Client = get_node("/root/Client")


########################################################
# Hooks                                                #
########################################################


# Called when the node is "ready".
func _ready()->void:
	set_physics_process(false)
	# Connect to the Client signal "connection_succeeded".
	_Client.connect("connection_succeeded", self, "_on_Client_connection_succeeded")


# Called when the client connected to the server.
func _on_Client_connection_succeeded()->void:
	start()


# Called during the physics processing step of the main loop.
func _physics_process(delta): # delta = ~0.01667
	# we add the make milliseconds out of the current delta
	#  and add the delta_latency to the value as well (more accurate)
	client_clock += int(delta*1000) + delta_latency
	# after applying the delta_latency once, we don't need to
	#  apply it again until it changed the value. 
	#  therefore we can simply set it to 0 for now
	delta_latency = 0
	# since we made an integer value out of our delta previously
	#  we would loose 0.667 milliseconds on each each time we
	#  update our time. Therefore we need to collect the decimals
	#  that are left and handle them too.
	decimal_collector += (delta * 1000) - int(delta * 1000)
	# once we have collected at least one millisecond in the 
	#  decimal_collector, we add that millisecond to the
	#  client_clock and subtract it from the decimal_collector
	if decimal_collector >= 1.00:
		client_clock += 1
		decimal_collector -= 1.00


########################################################
# Methods                                              #
########################################################


# Called when we are connected to the server and the Clock
#  can start ticking.
func start():
	# start the physics process
	set_physics_process(true)
	# also we want to start to calculate the latency
	start_calculating_latency()
	# fetch initial server time
	Router.fetch_server_time()


# Called whenever we want to sync determine the (delta_)latency.
func start_calculating_latency():
	# we create a new time
	var timer = Timer.new()
	# the timer should timeout every 0.5 seconds
	timer.wait_time = 0.5
	# the timer should start as soon as it was added to the node tree
	timer.autostart = true
	# we connect the timeout event with the determine latency function
	timer.connect("timeout", self, "determine_latency")
	# now we can add the timer to the node tree
	self.add_child(timer)


# Called whenever timeout event on the timer is emitted.
func determine_latency():
	# we just have to call this on the server instance.
	Router.determine_latency()


# Callen when we get back the client time from the server.
func receive_latency(client_time):
	# we take the current system time, subtract the client time
	#  we sent through the server. Then we devide the differnce
	#  by 2 to get the average latency for a one way connection.
	latency_array.append((OS.get_system_time_msecs() - client_time) / 2)
	# as soon as we have 9 entries we can start averaging it out
	if latency_array.size() == 9:
		# we start with a total latency of 0
		var total_latency = 0
		# then we sort the array with the 9 entries by amount (ascending)
		latency_array.sort()
		# we then take the middle of these 9 entries (index 4, entry 5)
		var mid_point = latency_array[4]
		# now we loop over the latency array in reversed order of keys
		#  i = the current key of latency_array
		for i in range(latency_array.size()-1,-1,-1):
			# if the value of this entry is larger than the 2 times the
			#  mid_point, then we know it must be an extreme value.
			#  if it also is greater than 20 (milliseconds) we also know
			#  that this extreme is not just because of a super fast
			#  connection. So we can remove it since we don't care about
			#  the extremes when calculating our average latency.
			if latency_array[i] > (2 * mid_point) and latency_array[i] > 20:
				# we remove the extreme from the latency_array
				latency_array.remove(i)
			else:
				# if the entry is no extreme we sum it into the total_latency
				total_latency += latency_array[i]
		# now we calulate the latency since we latly created the latency
		delta_latency = (total_latency / latency_array.size()) - latency
		# and finally we can calculate the actual latency
		latency = total_latency / latency_array.size()
		# once our calculation is done we want to reset the latency array
		#  so we can start over our calculation
		latency_array.clear()


# Called whenever we receive the server time.
func receive_server_time(server_time, client_time):
	# set initial latency and client_clock time on the clock
	# calculate the latency
	latency = (OS.get_system_time_msecs() - client_time) / 2
	# save the calculated game time
	client_clock = server_time + latency
