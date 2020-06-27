extends Control

onready var last_check: int = state.frame
onready var networking: Node = get_node("/root/root")
onready var first_row: BoxContainer = get_node("m/h/v")
onready var sens_slider: HSlider = first_row.get_node("sens_slider")
onready var sens_label: Label = first_row.get_node("sens_label")
onready var nickname_ledit: LineEdit = first_row.get_node("nickname_ledit")

func _ready() -> void:
	state.connect("new_frame", self, "check")
	sens_slider.set_value(state.config.mouse_sens * 100)
	# TODO: find a better way to do this
	sens_label.set_text("                                                 \nMouse Sensitivity          " + str(state.config.mouse_sens))
	nickname_ledit.set_text(state.config.nickname)

func check() -> void:
	if state.did_pass(last_check, 5.0):
		state.write_conf()
		last_check = state.frame

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	state.write_conf()
	state.change_map_to("main_menu", false)

func _on_sens_slider_value_changed(new_mouse_sens: int) -> void:
	state.config.mouse_sens = new_mouse_sens / 100.0
	# TODO: find a better way to do this
	sens_label.set_text("                                                 \nMouse Sensitivity          " + str(state.config.mouse_sens))

func _on_nickname_ledit_text_changed(new_nickname: String) -> void:
	state.config.nickname = new_nickname
	networking.player.name = state.config.nickname
