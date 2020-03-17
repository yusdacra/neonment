extends Node

var players: Dictionary = {}

var port: int = 5000
var udelta: float = 1.0 / 60
var server_info: Dictionary = {
	name = "Server",
	max_players = 10,
	current_map = "test",
}

signal player_joined(pinfo)
signal player_left(id)
signal input_received(idata, id)

#---------------------------#

func _ready():
	get_tree().connect("network_peer_connected",    self, "client_connected"   )
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")
	create_server()
	utils.change_map_to(server_info.current_map)

#------------------------#

func client_connected(id):
	print("Client ", id, " connected to server")
	rpc_id(id, "receive_server_info", udelta, server_info)

func client_disconnected(id):
	print("Client ", id, " disconnected from server")
	unregister_player(id)

#---------------------------#

func create_server():
	print("Starting server with configuration:")
	print("Port: ", port)
	print("Max players: ", server_info.max_players)
	print("Name: ", server_info.name)
	print("Update delta: ", udelta)

	var sv := NetworkedMultiplayerENet.new()
	# Hardcoded compression mode, must be same with client mode
	sv.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZSTD)
	
	match sv.create_server(port, server_info.max_players):
		ERR_ALREADY_IN_USE:
			printerr("A server is already running, close it and try again.")
			get_tree().quit(ERR_ALREADY_IN_USE)
		ERR_CANT_CREATE:
			printerr("Failed to create server.")
			get_tree().quit(ERR_CANT_CREATE)
		OK:
			print("Server created successfully!")
	
	get_tree().set_network_peer(sv)

func unregister_player(id: int):
	emit_signal("player_left", id)
	# Remove player from list
	players.erase(id)
	# Call the clients to remove this player
	rpc("unregister_player", id)
	print_debug("Server player list: ", players)

func send_snapshot(ss: Dictionary):
	rpc_unreliable("receive_snapshot", ss)

remote func register_player(pinfo: Dictionary):
	for player in players.values():
		# Call the clients to add this new player to their lists
		rpc_id(player.id, "register_player", pinfo)
	# Call the new client to add every other player to their list
	rpc_id(pinfo.id, "register_players", players)
	# Add it to the local list
	players[pinfo.id] = pinfo
	emit_signal("player_joined", pinfo)
	rpc_id(pinfo.id, "ready_to_play")
	print_debug("Server player list: ", players)

remote func receive_input(idata: Dictionary, pid: int):
	emit_signal("input_received", idata, pid)

#---------------------------#
