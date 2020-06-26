extends Node

func _ready() -> void:
	state.feature = "server" if OS.has_feature("server") else "client"
	state.config_path = "user://" + state.feature + "_config.json"
	OS.set_window_title("Neonment " + state.feature)
	state.read_conf()
	get_tree().change_scene("res://" + state.feature + "/main.tscn")
