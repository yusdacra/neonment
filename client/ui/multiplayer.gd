extends Control

onready var networking: Node = get_node("/root/root")
onready var fail_dialog: AcceptDialog = get_node("fail_dialog")
onready var first_row: BoxContainer = get_node("m/c/r/c/r")
onready var pname_ledit: LineEdit = first_row.get_node("player_row/pname_ledit")
onready var ip_ledit: LineEdit = first_row.get_node("join_row/ip_ledit")
onready var port_ledit: LineEdit = first_row.get_node("join_row/port_ledit")

func _ready() -> void:
	networking.connect("registered_by_sv", self, "go_to_lobby")
	networking.connect("connection_fail", self, "connection_error")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pname_ledit.set_text(networking.player.name)

func _on_join_pressed() -> void:
	networking.player.name = pname_ledit.get_text()
	
	var ip: String = ip_ledit.get_text()
	var port: int = int(port_ledit.get_text())
	
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
