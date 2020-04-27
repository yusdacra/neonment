extends Spatial

var ss_timestamp: int = 1 # Last sent snapshot's timestamp
var inputs: Dictionary = {} # Holds received inputs (that haven't been processed yet)
var pi_input_timestamp: Dictionary = {} # Caches last processed inputs' timestamp sent by clients, so we can send it back
var player_ginfo: Dictionary = {}
onready var networking: Node = get_node("/root/root")

func _ready() -> void:
	state.connect("new_frame", self, "update_state")
	networking.connect("player_joined", self, "spawn_player")
	networking.connect("player_left", self, "remove_player")
	networking.connect("input_received", self, "cache_input")
	
	networking.send_change_map(state.server_info.game.map)
	spawn_players()

func update_state() -> void:
	# Replace this with better code to handle client quit support?
	# You know what i mean
	if state.players.size() < state.server_info.game.max_players:
		state.change_map_to("lobby", false)
		networking.send_change_map("lobby", false)
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
			
		var st = {
			pstate = inode.get_state(),
			timestamp = pi_input_timestamp[id],
		}
		inputs[id].clear()
		ss.player_states[id] = st
	
	if state.players.size() > 0:
		networking.send_snapshot(ss)
		ss_timestamp += 1 

func spawn_player(pinfo: Dictionary) -> void:
	inputs[pinfo.id] = []
	pi_input_timestamp[pinfo.id] = 0
	for i in range(get_node("spawn_points").get_child_count()):
		if get_node("spawn_points").get_child(i).get_child_count() > 0:
			player_ginfo[pinfo.id] = {
				team = i
			}
			break
	var tnode = get_node("spawn_points").get_child(player_ginfo[pinfo.id].team)
	var spawn_point = randi() % int(tnode.get_child_count())
	var new_player: KinematicBody = load(state.entity(pinfo.classname)).instance()
	new_player.set_translation(tnode.get_child(spawn_point).get_translation())
	new_player.set_name(str(pinfo.id))
	add_child(new_player)
	tnode.get_child(spawn_point).free()
	state.pdbg("Spawned player " + str(pinfo.id) + " in team " + str(player_ginfo[pinfo.id].team))

func spawn_players() -> void:
	for p in state.players.values():
		spawn_player(p)

func remove_player(id: int) -> void:
	get_node(str(id)).free()
	pi_input_timestamp.erase(id)
	inputs.erase(id)
	state.pdbg("Removed player " + str(id))

func cache_input(idata: Dictionary, id: int) -> void:
	inputs[id].append(idata)
