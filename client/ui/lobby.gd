extends Control

var last_check_frame: int = 0
onready var networking: Node = get_node("/root/root")
onready var first_row: BoxContainer = get_node("m/h/v")
onready var timer: Label = first_row.get_node("timer")
onready var plist: ItemList = first_row.get_node("plist")
onready var back: Button = get_node("back")
onready var ready: Button = get_node("ready")

func _ready() -> void:
	state.connect("new_frame", self, "update_loop")
	networking.connect("disconnected", self, "on_disconnect")
	networking.connect("received_rdict", self, "update_ui")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_on_ready_toggled(false)

func _input(event: InputEvent) -> void:
	if last_check_frame <= 0:
		if !ready.is_pressed() && event.is_action_pressed("ui_cancel"):
			_on_back_pressed()
		elif event.is_action_pressed("ui_accept"):
			var ready: Button = get_node("ready")
			ready.set_pressed(!ready.is_pressed())

func _on_back_pressed() -> void:
	get_tree().emit_signal("server_disconnected", "Disconnect requested.")

func on_disconnect(reason: String) -> void:
	state.change_map_to("multiplayer", false)

func _on_ready_toggled(button_pressed: bool) -> void:
	back.set_disabled(button_pressed)
	networking.send_ready(button_pressed)

func update_loop() -> void:
	if last_check_frame > 0:
		timer.set_text("Players - All ready! - Starting in " + str(state.server_info.game.start_max_time - int((state.frame - last_check_frame) * state.UDELTA)))

func update_ui(rdict: Dictionary) -> void:
	plist.clear()
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
		plist.add_item(text, null, false)
	if rdict.size() == state.server_info.game.max_players:
		if all_true:
			last_check_frame = state.frame
			ready.set_disabled(true)
			back.set_disabled(true)
			timer.set_text("Players - All ready! - Starting in " + str(state.server_info.game.start_max_time))
			return
		else:
			timer.set_text("Players - Everyone isn't ready yet!")
	else:
		timer.set_text("Players - Not enough players (" + str(rdict.size()) + "/" + str(state.server_info.game.max_players) + ")")
	
	if last_check_frame > 0:
		ready.set_disabled(false)
		back.set_disabled(ready.is_pressed())
		last_check_frame = 0
