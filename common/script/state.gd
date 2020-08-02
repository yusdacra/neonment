extends Node

var current_map_name: String = "node_that_will_never_exist_in_the_scene_hierarchy"
# Stores the "feature" of the game, ie. server or client
var feature: String
# so we don't do string comparisons everywhere
var is_server: bool
# Current configuration
var config: Dictionary
var config_path: String
var def_config_path: String

var players: Dictionary = {}
var server_info: Dictionary = {
	name = "Server",
	max_clients = 6,
	game = {
		team_count = 0, # depends on the map, cached here
		max_players = 0, # depends on the map, cached here
		map = "test",
		start_max_time = 10.0,
	},
}

var counter: float = 0.0
var frame: int = 0
const UDELTA: float = 1.0 / 60
var paused := false

# This is used so that the game is more deterministic
# and is controlled from a single source
# (and so we can "pause" the game easily)
signal new_frame

func _process(delta: float) -> void:
	if paused:
		return
	counter += delta
	if counter < UDELTA:
		return
	# This skips frames if the computer can't keep up
	# or when framerate is limited to some amount (VSync)
	# or just acts as normal one frame continue if everything is alright
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
		if is_server:
			map_node.add_child(load("res://server/map_sp/" + name + ".tscn").instance())
		else:
			map_node.add_child(load("res://client/map_vis/" + name + ".tscn").instance())
			map_node.add_child(load("res://client/ui/hud.tscn").instance())
		map_node.add_child(load("res://common/map_col/" + name + ".tscn").instance())
	else:
		if !is_server:
			map_node = load("res://client/ui/" + name + ".tscn").instance()
		else:
			map_node = load("res://server/" + name + ".tscn").instance()
	
	map_node.set_name(name)
	get_node("/root/root").call_deferred("add_child", map_node)

# Some utilities to pretty print stuff
func plog(text: String) -> void:
	print(construct_log(text))

func perr(text: String) -> void:
	print(construct_log(text, "ERROR"))

func pdbg(text: String) -> void:
	print(construct_log(text, "DEBUG"))

func construct_log(text: String, level: String = "INFO ") -> String:
	return "[" + level + "] " + "[frame: " + str(frame) + "] " + "[" + time_formatted() + "] -> " + text

func time_formatted() -> String:
	var time = OS.get_time()
	return parse_time(time.hour) + ":" + parse_time(time.minute) + ":" + parse_time(time.second)

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
	var file_content: String = file.get_as_text()
	file.close()
	
	if validate_json(file_content):
		perr("Could not parse config file! Using default settings.")
		read_def_conf()
		return
	
	var parsed: Dictionary = parse_json(file_content)
	
	# Set current config with the newly parsed config
	# Only set the stuff the parsed config has
	for key in parsed.keys():
		if key is String && config.has(key):
			pdbg("Setting config key \"" + key + "\" to \"" + str(parsed[key]) + "\" was \"" + str(config[key]) + "\"")
			config[key] = parsed[key]

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
