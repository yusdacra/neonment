extends Spatial

var from_to: Dictionary = {} # Interpolation entries
var last_ss_timestamp: int = -1 # Timestamp of the last received snapshot
var last_pi_timestamp: int = 0 # Timestamp of the input the server last processed
var input_timestamp: int = 0 # Timestamp of the last input sent
var sent_inputs: Dictionary = {} # Holds sent inputs that the server hasn't processed & sent back to us yet
var current_time: float = 0.0
var player_node: KinematicBody
onready var networking: Node = get_node("/root/root")

func _ready() -> void:
	networking.connect("disconnected", self, "_on_disconnect")
	networking.connect("new_player", self, "spawn_player")
	networking.connect("player_left", self, "remove_player")
	networking.connect("received_snapshot", self, "apply_snapshot")

	# Spawn local player (position doesnt matter as it will be updated by the server)
	spawn_player(networking.player)
	# For convenience, store the player node inside a variable
	player_node = get_node(str(networking.player.id))
	# Spawn other players
	spawn_players()

func _input(event) -> void:
	# TODO: Replace this with a "pause" menu
	if event.is_action_pressed("quit"):
		get_tree().set_network_peer(null)
		_on_disconnect()

func _process(delta: float) -> void:
	current_time += delta
	if current_time < networking.udelta:
		return
	# Substract update delta from the counter, this is to minimize deviations
	current_time -= networking.udelta

	var idata = {
		pinput = input.gather_input(),
		timestamp = input_timestamp,
	}
	input_timestamp += 1
	networking.send_input_data(idata)
	# Cache the input for later use
	sent_inputs[idata.timestamp] = idata
	
	# Predict server state using the inputs that hasn't been recognized by the server
	for itimestamp in sent_inputs:
		if itimestamp <= last_pi_timestamp:
			# If recognized, delete this input entry
			sent_inputs.erase(itimestamp)
		else:
			# If not, process it
			player_node.process_input(sent_inputs[itimestamp].pinput)
	
	#print("These are the inputs that aren't processed yet: ", sent_inputs)

func _on_disconnect() -> void:
	utils.plog("Disconnected from server")
	utils.change_map_to("main_menu", false)

##### SPAWN CODE #####

func remove_player(id: int) -> void:
	get_node(str(id)).queue_free()
	utils.pdbg("Removed player with id " + str(id))

func spawn_players() -> void:
	for p in networking.players.values():
		spawn_player(p)

func spawn_player(pinfo: Dictionary, spawn_point: Vector3 = Vector3(0, 20, 0)) -> void:
	var new_player: KinematicBody = load(utils.entity(pinfo.classname)).instance()
	new_player.set_name(str(pinfo.id))
	if pinfo.id != networking.player.id:
		# If not local player, add the body (so that the local player can see others)
		new_player.add_child(load("res://client/entity_vis/" + pinfo.classname + ".tscn").instance())
	else:
		# If local player, add the camera
		new_player.get_node("head").add_child(Camera.new())
		# NOTE: Viewmodel should be spawned here
	new_player.set_translation(spawn_point)
	add_child(new_player)

##### SPAWN CODE #####

func apply_snapshot(ss: Dictionary) -> void:
	if ss.timestamp <= last_ss_timestamp:
		return
	last_ss_timestamp = ss.timestamp
	last_pi_timestamp = ss.player_states[networking.player.id].timestamp
	
	for id in ss.player_states:
		var pnode = get_node(str(id))
		 
		if !pnode:
			return
		
		if from_to.has(id):
			from_to[id].from = from_to[id].to
			from_to[id].to = ss.player_states[id].pstate
			from_to[id].time = 0.0
		else:
			from_to[id] = {
				from = ss.player_states[id].pstate,
				to = ss.player_states[id].pstate,
				time = networking.udelta,
			}
		
		if from_to[id].time < networking.udelta:
			from_to[id].time += get_process_delta_time()
		else:
			return
		
		pnode.apply_state(from_to[id])
