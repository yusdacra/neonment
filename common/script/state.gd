extends Node

var current_map_name: String = "node_that_will_never_exist_in_the_scene_hierarchy"
# Stores the "feature" of the game, ie. server or client
var feature: String

#---------------------------#

var players: Dictionary = {}
# This only contains stuff we need to send to a client
var server_info: Dictionary = {
	name = "Server",
	max_clients = 6,
	game = {
		team_count = 0,
		max_players = 0,
		map = "test",
	},
}

# Decides after how many seconds the game will start
const GAME_START_COOLDOWN: float = 10.0

#---------------------------#

var counter: float = 0.0
var frame: int = 0
const UDELTA: float = 1.0 / 60

signal new_frame

func _process(delta: float) -> void:
	counter += delta
	if counter < UDELTA:
		return
	counter -= UDELTA
	frame += 1
	emit_signal("new_frame")

func did_pass(start_frame: int, max_time: float) -> bool:
	return ((frame - start_frame) * UDELTA) >= max_time

#---------------------------#

func entity(name: String) -> String:
	return "res://common/entity/" + name + ".tscn"

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

#Some utilities to log stuff#

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

#Config file stuff#

func read_conf():
	var file := File.new()
	var open_err = file.open("user://" + feature + "_config.json", File.READ)
	if open_err == ERR_FILE_NOT_FOUND:
		return true
	elif open_err != OK:
		return false
	
	var content: String = file.get_as_text()
	file.close()
	if validate_json(content):
		return false
	return parse_json(content)

#---------------------------#
