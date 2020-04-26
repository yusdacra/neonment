extends Node

var last_check_frame: int = 0

var ready_list: Dictionary = {}
onready var networking: Node = get_node("/root/root")

func _ready() -> void:
	state.connect("new_frame", self, "update")
	networking.connect("ready_received", self, "toggle_ready")
	networking.connect("player_joined", self, "add_ready")
	networking.connect("player_left", self, "remove_ready")
	
	for p in state.players:
		ready_list[p] = false

func update() -> void:
	if last_check_frame > 0 && state.did_pass(last_check_frame, state.GAME_START_COOLDOWN):
		state.change_map_to(state.server_info.gamemode.map)

func toggle_ready(ready: bool, id: int) -> void:
	state.pdbg("Ready received: " + str(ready) + " " + str(id))
	last_check_frame = 0
	ready_list[id] = ready
	try_start_game_timer()

func remove_ready(id: int) -> void:
	state.pdbg("Remove ready: " + str(id))
	last_check_frame = 0
	ready_list.erase(id)
	try_start_game_timer()

func add_ready(p: Dictionary) -> void:
	state.pdbg("Add ready: " + str(p.id))
	last_check_frame = 0
	ready_list[p.id] = false
	try_start_game_timer()

func try_start_game_timer() -> void:
	state.pdbg("Ready list: " + str(ready_list))
	networking.send_rdict(ready_list)
	state.pdbg("lcf test: " + str(last_check_frame > 0) + " players max test: " + str(ready_list.size() < state.server_info.gamemode.max_players))
	if last_check_frame > 0:
		return
	if ready_list.size() < state.server_info.gamemode.max_players:
		return
	for r in ready_list.values():
		if !r:
			return
	last_check_frame = state.frame
	state.pdbg("Last check frame: " + str(last_check_frame))
