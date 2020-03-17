extends Node

var players: Dictionary = {}
var player: Dictionary = {
	id = 1,
	name = "Player",
	classname = "player",
}

var server_info: Dictionary = {
	name = "Server",
	max_players = 10,
	current_map = "test",
}
var udelta: float = 1.0 / 60

######### CLIENT ###########

signal ready_to_play
signal connection_success
signal connection_fail
signal disconnected

signal new_player(pinfo)
signal player_left(id)
signal received_snapshot(ss)

func _ready():
	get_tree().connect("connected_to_server", self, "on_connect")
	get_tree().connect("server_disconnected", self, "on_disconnect")
	get_tree().connect("connection_failed", self, "on_connection_fail")
	utils.change_map_to("main_menu", false)

func connect_to_server(ip: String, port: int):
	var client = NetworkedMultiplayerENet.new()
	# Hardcoded compression mode, must be same with server mode
	client.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZSTD)
		
	match client.create_client(ip, port):
		ERR_ALREADY_IN_USE:
			printerr("If you are seeing this error, that means something has gone *very* wrong.")
			return
		ERR_CANT_CREATE:
			printerr("Failed to create client.")
			return
		OK:
			print("Client created successfully!")
		
	get_tree().set_network_peer(client)

func on_connect():
	player.id = get_tree().get_network_unique_id()
	set_network_master(player.id)
	rpc_id(1, "register_player", player)
	emit_signal("connection_success")

func on_connection_fail():
	get_tree().set_network_peer(null)
	emit_signal("connection_fail")

func on_disconnect():
	players.clear()
	emit_signal("disconnected")

#---------------------------#

func send_input_data(idata: Dictionary):
	rpc_unreliable_id(1, "receive_input", idata, player.id)

remote func register_player(pinfo: Dictionary):
	players[pinfo.id] = pinfo
	emit_signal("new_player", pinfo)

remote func register_players(psinfo: Dictionary):
	players = psinfo

remote func unregister_player(id: int):
	players.erase(id)
	emit_signal("player_left", id)

remote func receive_server_info(ud: float, svinfo: Dictionary):
	server_info = svinfo
	udelta = ud

remote func receive_snapshot(ss: Dictionary):
	emit_signal("received_snapshot", ss)

remote func ready_to_play() -> void:
	emit_signal("ready_to_play")

############## CLIENT ################
