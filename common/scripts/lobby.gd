extends Node

func _ready():
	if OS.has_feature("server"):
		get_tree().change_scene("res://server/entrypoint.tscn")
	else:
		get_tree().change_scene("res://client/entrypoint.tscn")
	#else:
	#	printerr("This can't happen (unless i am dumb)")
	#	get_tree().quit(1)
