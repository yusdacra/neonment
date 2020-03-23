extends Node

func _ready() -> void:
	utils.feature = "server"
	OS.set_window_title("Neonment Server")
	get_tree().change_scene("res://server/main.tscn")
