extends Node

func _ready() -> void:
	state.feature = "client"
	state.is_server = false
	if OS.has_feature("server") || OS.get_executable_path().ends_with("godot-server"):
		state.feature = "server"
		state.is_server = true
	state.config_path = "user://" + state.feature + "_config.json"
	state.def_config_path = "res://" + state.feature + "/config.json"
	OS.set_window_title("Neonment " + state.feature)
	state.read_def_conf()
	state.read_conf()
	get_tree().change_scene("res://" + state.feature + "/main.tscn")
