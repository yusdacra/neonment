extends Control

var last_check_frame: int = 0
onready var networking: Node = get_node("/root/root")

func _ready() -> void:
	state.connect("new_frame", self, "update_loop")
	networking.connect("disconnected", self, "on_disconnect")
	networking.connect("received_rdict", self, "update_ui")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_on_ready_toggled(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().emit_signal("server_disconnected", "Disconnect requested.")

func on_disconnect(reason: String) -> void:
	state.change_map_to("multiplayer", false)

func _on_ready_toggled(button_pressed: bool) -> void:
	get_node("back").set_disabled(button_pressed)
	networking.send_ready(button_pressed)

func update_loop() -> void:
	if last_check_frame > 0:
		get_node("m/h/v/timer").set_text("Players - All ready! - Starting in " + str(10 - int((state.frame - last_check_frame) * state.UDELTA)))

func update_ui(rdict: Dictionary) -> void:
	get_node("m/h/v/plist").clear()
	var all_true: bool = true
	for p in rdict:
		var text: String = networking.player.name
		if p != networking.player.id:
			text = state.players[p].name
		if rdict[p]:
			text += " - Ready"
		else:
			all_true = false
			text += " - Not Ready"
		get_node("m/h/v/plist").add_item(text, null, false)
	if rdict.size() == state.server_info.game.max_players:
		if all_true:
			last_check_frame = state.frame
			get_node("ready").set_disabled(true)
			get_node("back").set_disabled(true)
			get_node("m/h/v/timer").set_text("Players - All ready! - Starting in " + str(state.GAME_START_COOLDOWN))
			return
		else:
			get_node("m/h/v/timer").set_text("Players - Everyone isn't ready yet!")
	else:
		get_node("m/h/v/timer").set_text("Players - Not enough players (" + str(rdict.size()) + "/" + str(state.server_info.game.max_players) + ")")
	
	if last_check_frame > 0:
		get_node("ready").set_disabled(false)
		get_node("back").set_disabled(get_node("ready").is_pressed())
		last_check_frame = 0
