extends Node

func _ready() -> void:
	utils.feature = "client"
	OS.set_window_title("Neonment Client")
	get_tree().change_scene("res://client/main.tscn")
