extends Control

var networking: Node

func _ready():
	networking = utils.networking()
	networking.connect("ready_to_play", self, "start_game")
	networking.connect("connection_fail", self, "_on_connection_error")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _on_join_pressed():
	if !update_player_info():
		printerr("Invalid player information.")
		return
	
	var ip: String = get_node("menu/column/row/center/row/join_row/ip").text
	var port: int = int(get_node("menu/column/row/center/row/join_row/port").text)
	
	networking.connect_to_server(ip, port)

func start_game():
	utils.change_map_to(networking.server_info.current_map)
	
func _on_connection_error():
	printerr("Connection to server failed.")

func update_player_info() -> bool:
	networking.player.name = get_node("menu/column/row/center/row/player_row/player_name").text
	if networking.player.name.empty():
		return false
	return true
