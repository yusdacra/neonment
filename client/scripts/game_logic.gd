extends Spatial

var from_to: Dictionary = {}
var last_ss_timestamp: int = -1
var last_pi_timestamp: int = 0
var networking: Node
var current_time: float = 0.0
var player_node: KinematicBody
var input_timestamp: int = 0
var sent_inputs: Dictionary = {}

func _ready() -> void:
	networking = utils.networking()
	networking.connect("disconnected", self, "_on_disconnect")
	networking.connect("new_player", self, "spawn_player")
	networking.connect("player_left", self, "remove_player")
	networking.connect("received_snapshot", self, "apply_snapshot")

	# Spawn local player (position doesnt matter as it will be updated by the server)
	spawn_player(networking.player)
	player_node = get_node(str(networking.player.id))
	# Spawn other players
	spawn_players()

func _input(event) -> void:
	if event.is_action_pressed("quit"):
		get_tree().set_network_peer(null)
		_on_disconnect()

func _process(delta: float) -> void:
	current_time += delta
	if current_time < networking.udelta:
		return
	current_time -= networking.udelta

	var idata = {
		pinput = player_node.gather_input(),
		timestamp = input_timestamp,
	}
	input_timestamp += 1
	networking.send_input_data(idata)
	sent_inputs[idata.timestamp] = idata
	
	for itimestamp in sent_inputs:
		if itimestamp <= last_pi_timestamp:
			sent_inputs.erase(itimestamp)
		else:
			player_node.process_state(sent_inputs[itimestamp].pinput)
	
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

func spawn_player(pinfo: Dictionary, spawn_point: Vector3 = Vector3(0, 5, 0)) -> void:
	var new_player = load(utils.entity(pinfo.classname)).instance()
	new_player.set_name(str(pinfo.id))
	# If not local player, then remove the camera
	if pinfo.id != networking.player.id:
		new_player.get_node("head").get_node("camera").queue_free()
		new_player.set_process(false)
	else:
		# If local player, make the head invisible
		new_player.get_node("body").set_visible(false)
	new_player.set_translation(spawn_point)
	add_child(new_player)

##### SPAWN CODE #####

##### SNAPSHOT CODE #####

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

##### SNAPSHOT CODE #####
