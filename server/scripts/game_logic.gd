extends Spatial

var current_time: float = 0.0
var ss_timestamp: int = 1
var networking: Node
var inputs: Dictionary = {}
var pi_input_timestamp: Dictionary = {}

func _ready() -> void:
	networking = utils.networking()
	networking.connect("player_joined", self, "spawn_player")
	networking.connect("player_left", self, "remove_player")
	networking.connect("input_received", self, "cache_input")

func _process(delta) -> void:
	current_time += delta
	if current_time < networking.udelta:
		return
	current_time -= networking.udelta
	
	update_state()

func update_state() -> void:
	var ss: Dictionary = {
		player_states = {},
		timestamp = ss_timestamp,
	}
	
	for id in networking.players:
		var inode: KinematicBody = get_node(str(id))
		if inputs[id].empty():
			inode.process_state(
				{
					forward = false,
					backward = false,
					left = false,
					right = false,
					jump = false,
					sprint = false,
					mouse_axis = Vector2(),
				}
			)
		else:
			for input in inputs[id]:
				inode.process_state(input.pinput)
			pi_input_timestamp[id] = inputs[id].back().timestamp
			
		var state = {
			pstate = inode.get_state(),
			timestamp = pi_input_timestamp[id],
		}
		inputs[id].clear()
		ss.player_states[id] = state
	
	if networking.players.size() > 0:
		networking.send_snapshot(ss)
		ss_timestamp += 1

func spawn_player(pinfo: Dictionary) -> void:
	inputs[pinfo.id] = []
	pi_input_timestamp[pinfo.id] = 0
	var new_player: KinematicBody = load(utils.entity(pinfo.classname)).instance()
	new_player.set_translation(get_node("spawn_points").get_children()[randi() % networking.server_info.max_players].get_translation())
	new_player.set_name(str(pinfo.id))
	new_player.get_node("head").get_node("camera").queue_free()
	add_child(new_player)
	utils.plog("Spawned player " + str(pinfo.id))

func remove_player(id: int) -> void:
	get_node(str(id)).queue_free()
	pi_input_timestamp.erase(id)
	inputs.erase(id)
	utils.plog("Removed player " + str(id))

func cache_input(idata: Dictionary, id: int) -> void:
	inputs[id].append(idata)
