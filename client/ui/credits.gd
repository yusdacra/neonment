extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	state.change_map_to("main_menu", false)
