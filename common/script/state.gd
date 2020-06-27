extends Node

var current_map_name: String = "node_that_will_never_exist_in_the_scene_hierarchy"
# Stores the "feature" of the game, ie. server or client
var feature: String
var config: Dictionary
var config_path: String
var def_config_path: String

var players: Dictionary = {}
var server_info: Dictionary = {
	name = "Server",
	max_clients = 6,
	game = {
		team_count = 0,
		max_players = 0,
		map = "test",
		start_max_time = 10.0,
	},
}

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

func read_conf() -> void:
	var file := File.new()
	plog("Loading config file from " + config_path + ".")
	var open_err := file.open(config_path, File.READ)
	if open_err != OK:
		perr("Could not read config file! Using default settings.")
		read_def_conf()
		return
	var content: String = file.get_as_text()
	file.close()
	
	if validate_json(content):
		perr("Could not parse config file! Using default settings.")
		read_def_conf()
		return
	
	var parsed = parse_json(content)
	if feature == "client":
		if parsed.has("nickname"):
			config.nickname = parsed.nickname
		if parsed.has("mouse_sens"):
			config.mouse_sens = parsed.mouse_sens
	else:
		if parsed.has("port"):
			config.port = parsed.port
		if parsed.has("name"):
			config.name = parsed.name
		if parsed.has("max_clients"):
			config.max_clients = parsed.max_clients
		if parsed.has("game"):
			if parsed.game.has("map"):
				config.game.map = parsed.game.map
			if parsed.game.has("start_max_time"):
				config.game.start_max_time = parsed.game.start_max_time

func write_conf() -> void:
	var file := File.new()
	var open_err := file.open(config_path, File.WRITE)
	if open_err != OK:
		perr("Could not write config file!")
		return
	var content: String = to_json(config)
	file.store_string(content)
	file.close()

func read_def_conf() -> void:
	var file := File.new()
	file.open(def_config_path, File.READ)
	config = parse_json(file.get_as_text())
	file.close()
