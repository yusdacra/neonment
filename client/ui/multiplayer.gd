extends Control

onready var networking: Node = get_node("/root/root")
onready var fail_dialog: AcceptDialog = get_node("fail_dialog")

func _ready() -> void:
	networking.connect("registered_by_sv", self, "go_to_lobby")
	networking.connect("connection_fail", self, "connection_error")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_node("menu/column/direct/center/row/player_row/player_name").set_text(networking.player.name)

func _on_join_pressed() -> void:
	networking.player.name = get_node("menu/column/direct/center/row/player_row/player_name").text
	
	var ip: String = get_node("menu/column/direct/center/row/join_row/ip").text
	var port: int = int(get_node("menu/column/direct/center/row/join_row/port").text)
	
	networking.connect_to_server(ip, port)

func go_to_lobby() -> void:
	state.change_map_to("lobby", false)
	
func connection_error(reason: String):
	fail_dialog.set_text("Could not connect to the server. Reason:\n" + reason)
	fail_dialog.set_visible(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed():
	state.change_map_to("main_menu", false)
