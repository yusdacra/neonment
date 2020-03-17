extends Spatial

var current_time: float = 0.0
var ss_timestamp: int = 1
var networking: Node
var inputs: Dictionary = {}

func _ready():
	networking = utils.networking()
	networking.connect("player_joined", self, "spawn_player")
	networking.connect("player_left", self, "remove_player")
	networking.connect("input_received", self, "cache_input")

func _process(delta):
	current_time += delta
	if current_time < networking.udelta:
		return
	current_time -= networking.udelta
	
	update_state()

func update_state():
	var ss: Dictionary = {
		player_states = {},
		timestamp = ss_timestamp,
	}
	
	for id in networking.players:
		var inode: KinematicBody = get_node(str(id))
		if inputs.has(id):
			inode.apply_input(inputs[id])
		inode.process_state()
		var state = inode.get_state()
		if inputs.has(id):
			state.pi_timestamp = inputs[id].timestamp
		ss.player_states[id] = state
	
	inputs.clear()
	if networking.players.size() > 0:
		networking.send_snapshot(ss)
		ss_timestamp += 1

func spawn_player(pinfo: Dictionary):
	var new_player: KinematicBody = load("res://common/entities/" + pinfo.classname + "/" + pinfo.classname + ".tscn").instance()
	new_player.set_translation(get_node("spawn_points").get_children()[randi() % networking.server_info.max_players].get_translation())
	new_player.set_name(str(pinfo.id))
	new_player.get_node("head").get_node("camera").queue_free()
	add_child(new_player)
	print_debug("Spawned player ", pinfo.id)

func remove_player(id: int):
	get_node(str(id)).queue_free()
	print_debug("Removed player ", id)

func cache_input(idata: Dictionary, pid: int):
	inputs[pid] = idata
