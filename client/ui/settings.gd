extends Control

func _ready():
	get_node("m/h/v/sens_slider").set_value(state.config.mouse_sens * 100)
	# TODO: find a better way to do this
	get_node("m/h/v/sens_label").set_text("                                                 \nMouse Sensitivity          " + str(state.config.mouse_sens))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	state.write_conf(state.config)
	state.change_map_to("main_menu", false)

func _on_sens_slider_value_changed(value: int):
	state.config.mouse_sens = value / 100.0
	# TODO: find a better way to do this
	get_node("m/h/v/sens_label").set_text("                                                 \nMouse Sensitivity          " + str(state.config.mouse_sens))
