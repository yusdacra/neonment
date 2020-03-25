extends Node

func _ready() -> void:
	if OS.has_feature("server"):
		get_tree().change_scene("res://server/entrypoint.tscn")
	# NOTE: Replace with the commented lines on release builds
	else:
		get_tree().change_scene("res://client/entrypoint.tscn")
	#else:
	#	printerr("This can't happen (unless i am dumb)")
	#	get_tree().quit(1)
