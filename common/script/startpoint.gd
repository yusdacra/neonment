extends Node

func _ready() -> void:
	if OS.has_feature("server"):
		get_tree().change_scene("res://server/entrypoint.tscn")
	else:
		get_tree().change_scene("res://client/entrypoint.tscn")
