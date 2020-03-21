extends Node

func _ready():
	if OS.has_feature("server"):
		utils.feature = "server"
		OS.set_window_title("Neonment Server")
		get_tree().change_scene("res://server/entrypoint.tscn")
	else:
		utils.feature = "client"
		OS.set_window_title("Neonment Client")
		get_tree().change_scene("res://client/entrypoint.tscn")
	#else:
	#	printerr("This can't happen (unless i am dumb)")
	#	get_tree().quit(1)
