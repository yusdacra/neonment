extends Control

func _on_back_pressed() -> void:
	state.change_map_to("main_menu", false)
