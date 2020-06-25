extends Node

var current_map_name: String = "node_that_will_never_exist_in_the_scene_hierarchy"
# Stores the "feature" of the game, ie. server or client
var feature: String
var config: Dictionary = {
	mouse_sens = 0.2,
} if feature == "client" else {
	port = 5000,
	name = "Server",
	max_clients = 6,
	map = "test",
}

var players: Dictionary = {}
var server_info: Dictionary = {
	name = "Server",
	max_clients = 6,
	game = {
		team_count = 0,
		max_players = 0,
		map = "test",
	},
}

# After how many seconds a game will start
const GAME_START_COOLDOWN: float = 10.0

var counter: float = 0.0
var frame: int = 0
const UDELTA: float = 1.0 / 60
var paused: bool = false

# This is used so that the game is more deterministic
# and is controlled from a single source
# (so we can "pause" the game easily)
signal new_frame

func _process(delta: float) -> void:
	if paused:
		return
	counter += delta
	if counter < UDELTA:
		return
	# This skips frames if the computer can't keep up
	# or when framerate is limited to some amount (VSync)
	while counter >= UDELTA:
		counter -= UDELTA
		frame += 1
	emit_signal("new_frame")

# Checks if the time that passed between start_frame and current frame is bigger than given max_time
func did_pass(start_frame: int, max_time: float) -> bool:
	return ((frame - start_frame) * UDELTA) > max_time

func toggle_pause() -> void:
	paused = !paused

func change_map_to(name: String, is_game_map: bool = true) -> void:
	pdbg("Map before change: " + current_map_name)
	if get_node("/root/root").has_node(current_map_name):
		pdbg("Removing map " + current_map_name)
		get_node("/root/root").get_node(current_map_name).queue_free()
	current_map_name = name
	
	plog("Loading map " + name)
	var map_node: Node
	if is_game_map:
		map_node = Spatial.new()
		map_node.set_script(load("res://" + feature + "/script/game_logic.gd"))
		if feature == "server":
			map_node.add_child(load("res://server/map_sp/" + name + ".tscn").instance())
		else:
			map_node.add_child(load("res://client/map_vis/" + name + ".tscn").instance())
			map_node.add_child(load("res://client/ui/hud.tscn").instance())
		map_node.add_child(load("res://common/map_col/" + name + ".tscn").instance())
	else:
		if feature == "client":
			map_node = load("res://client/ui/" + name + ".tscn").instance()
		else:
			map_node = load("res://server/" + name + ".tscn").instance()
	
	map_node.set_name(name)
	get_node("/root/root").call_deferred("add_child", map_node)

# Some utilities to pretty print stuff
func plog(text: String) -> void:
	print("[INFO] ", "[", time_formatted(), "] -> ", text)

func perr(text: String) -> void:
	printerr("[ERROR] ", "[", time_formatted(), "] -> ", text)

func pdbg(text: String) -> void:
	print_debug("[DEBUG] ", "[", time_formatted(), "] -> ", text)

func time_formatted() -> String:
	var datetime = OS.get_datetime()
	return parse_time(datetime.hour) + ":" + parse_time(datetime.minute) + ":" + parse_time(datetime.second)

func parse_time(time: int) -> String:
	var t := str(time)
	if t.length() == 1:
		t = "0" + t
	elif t.length() == 0:
		t = "00"
	return t

func read_conf():
	var file := File.new()
	var open_err := file.open("user://" + feature + "_config.json", File.READ)
	if open_err == ERR_FILE_NOT_FOUND:
		return true
	elif open_err != OK:
		return false
	
	var content: String = file.get_as_text()
	file.close()
	if validate_json(content):
		return false
	return parse_json(content)

func write_conf(conf: Dictionary) -> bool:
	var file := File.new()
	var open_err := file.open("user://" + feature + "_config.json", File.WRITE)
	if open_err != OK:
		return false
	
	var content: String = to_json(conf)
	file.store_string(content)
	file.close()
	return true
