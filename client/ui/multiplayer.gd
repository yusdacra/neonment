extends Control

onready var networking: Node = get_node("/root/root")

func _ready():
	networking.connect("ready_to_play", self, "start_game")
	networking.connect("connection_fail", self, "_on_connection_error")

func _on_join_pressed():
	if !update_player_info():
		utils.perr("Invalid player information.")
		return
	
	var ip: String = get_node("menu/column/direct/center/row/join_row/ip").text
	var port: int = int(get_node("menu/column/direct/center/row/join_row/port").text)
	
	networking.connect_to_server(ip, port)

func start_game():
	utils.change_map_to(networking.server_info.current_map)
	
func _on_connection_error():
	# TODO: Show a popup when connection fails
	pass

func update_player_info() -> bool:
	networking.player.name = get_node("menu/column/direct/center/row/player_row/player_name").text
	if networking.player.name.empty():
		return false
	return true

func _on_back_pressed():
	utils.change_map_to("main_menu", false)
