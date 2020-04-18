extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_multi_pressed():
	state.change_map_to("multiplayer", false)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_credits_pressed() -> void:
	state.change_map_to("credits", false)

func _on_settings_pressed() -> void:
	state.change_map_to("settings", false)
