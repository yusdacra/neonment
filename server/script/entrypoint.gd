extends Node

func _ready() -> void:
	state.feature = "server"
	OS.set_window_title("Neonment Server")
	get_tree().change_scene("res://server/main.tscn")
