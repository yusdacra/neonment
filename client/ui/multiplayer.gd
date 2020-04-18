extends Control

onready var networking: Node = get_node("/root/root")

func _ready() -> void:
	networking.connect("registered_by_sv", self, "go_to_lobby")
	networking.connect("connection_fail", self, "_on_connection_error")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_join_pressed() -> void:
	if !update_player_info():
		state.perr("Invalid player information.")
		return
	
	var ip: String = get_node("menu/column/direct/center/row/join_row/ip").text
	var port: int = int(get_node("menu/column/direct/center/row/join_row/port").text)
	
	networking.connect_to_server(ip, port)

func go_to_lobby() -> void:
	state.change_map_to("lobby", false)
	
func _on_connection_error(reason: String):
	# TODO: Show a popup when connection fails
	pass

func update_player_info() -> bool:
	networking.player.name = get_node("menu/column/direct/center/row/player_row/player_name").text
	if networking.player.name.empty():
		return false
	return true

func _on_back_pressed():
	state.change_map_to("main_menu", false)
