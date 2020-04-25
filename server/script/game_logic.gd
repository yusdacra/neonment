extends Spatial

var ss_timestamp: int = 1 # Last sent snapshot's timestamp
var inputs: Dictionary = {} # Holds received inputs (that haven't been processed yet)
var pi_input_timestamp: Dictionary = {} # Caches last processed inputs' timestamp sent by clients, so we can send it back
onready var networking: Node = get_node("/root/root")

func _ready() -> void:
	state.connect("new_frame", self, "update_state")
	networking.connect("player_joined", self, "spawn_player")
	networking.connect("player_left", self, "remove_player")
	networking.connect("input_received", self, "cache_input")
	
	networking.send_start_game_map()
	spawn_players()

func update_state() -> void:
	# Replace this with better code to handle client quit support?
	# You know what i mean
	if state.players.empty():
		state.change_map_to("lobby", false)
		return
	
	var ss: Dictionary = {
		player_states = {},
		timestamp = ss_timestamp,
	}
	
	for id in state.players:
		var inode: KinematicBody = get_node(str(id))
		if inputs[id].empty():
			inode.process_input(
				{
					forward = false,
					backward = false,
					left = false,
					right = false,
					jump = false,
					sprint = false,
					mouse_axis = Vector2(),
					ability = [false, false, false, false],
				}
			)
		else:
			for input in inputs[id]:
				inode.process_input(input.pinput)
			pi_input_timestamp[id] = inputs[id].back().timestamp
			
		var state = {
			pstate = inode.get_state(),
			timestamp = pi_input_timestamp[id],
		}
		inputs[id].clear()
		ss.player_states[id] = state
	
	if state.players.size() > 0:
		networking.send_snapshot(ss)
		ss_timestamp += 1

func spawn_player(pinfo: Dictionary) -> void:
	inputs[pinfo.id] = []
	pi_input_timestamp[pinfo.id] = 0
	var new_player: KinematicBody = load(state.entity(pinfo.classname)).instance()
	new_player.set_translation(get_node("spawn_points").get_children()[randi() % int(state.server_info.max_players)].get_translation())
	new_player.set_name(str(pinfo.id))
	add_child(new_player)
	state.plog("Spawned player " + str(pinfo.id))

func spawn_players() -> void:
	for p in state.players.values():
		spawn_player(p)

func remove_player(id: int) -> void:
	get_node(str(id)).queue_free()
	pi_input_timestamp.erase(id)
	inputs.erase(id)
	state.plog("Removed player " + str(id))

func cache_input(idata: Dictionary, id: int) -> void:
	inputs[id].append(idata)
