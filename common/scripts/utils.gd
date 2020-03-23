extends Node

const TIMEOUT: float = 10.0

var current_map_name: String = "node_that_will_never_exist_in_the_scene_hierarchy"
var feature: String

func entity(name: String) -> String:
	return "res://common/entities/" + name + ".tscn"

func networking() -> Node:
	return get_node("/root/root")

func plog(text: String) -> void:
	print("[INFO] ", "[", time_formatted(), "] -> ", text)

func perr(text: String) -> void:
	printerr("[ERROR] ", "[", time_formatted(), "] -> ", text)

func pdbg(text: String) -> void:
	print_debug("[DEBUG] ", "[", time_formatted(), "] -> ", text)

func time_formatted() -> String:
	var datetime = OS.get_datetime()
	return str(datetime.hour) + ":" + str(datetime.minute) + ":" + str(datetime.second)

func change_map_to(name: String, is_game_map: bool = true) -> void:
	plog("Map before change: " + current_map_name)
	if has_node(current_map_name):
		plog("Removing map " + current_map_name)
		get_node(current_map_name).queue_free()
	current_map_name = name
	
	plog("Loading map " + name)
	var map_node: Node
	if is_game_map:
		map_node = Spatial.new()
		map_node.set_script(load("res://" + feature + "/scripts/game_logic.gd"))
		if feature == "server":
			map_node.add_child(load("res://server/map_sp/" + name + ".tscn").instance())
		elif feature == "client":
			map_node.add_child(load("res://client/map_vis/" + name + ".tscn").instance())
			map_node.add_child(load("res://client/ui/hud.tscn").instance())
		map_node.add_child(load("res://common/map_col/" + name + ".tscn").instance())
	else:
		map_node = load("res://" + feature + "/ui/" + name + ".tscn").instance()
	
	map_node.set_name(name)
	call_deferred("add_child", map_node)
