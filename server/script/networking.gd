extends Node

var players: Dictionary = {}

var port: int = 5000
var server_info: Dictionary = {
	name = "Server",
	max_players = 6,
	current_map = "test",
}

signal player_joined(pinfo)
signal player_left(id)
signal input_received(idata, id)
signal ready_received(ready, id)

#---------------------------#

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "client_connected")
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")
	
	var config = state.read_conf()
	if config is Dictionary:
		port = config.port
		server_info.name = config.name
		server_info.max_players = config.max_players
		server_info.current_map = config.map
	
	create_server()
	state.change_map_to("lobby", false)

#---------------------------#

func client_connected(id) -> void:
	state.pdbg("Client " + str(id) + " connected to server")
	rpc_id(id, "sv_info", server_info)

func client_disconnected(id) -> void:
	state.pdbg("Client " + str(id) + " disconnected from server")
	unregister_player(id)

#---------------------------#

func create_server() -> void:
	state.plog("Starting server with configuration:")
	state.plog("Server name: " + str(server_info.name))
	state.plog("Map: " + str(server_info.current_map))
	state.plog("Port: " + str(port))
	state.plog("Max players: " + str(server_info.max_players))
	
	var sv := NetworkedMultiplayerENet.new()
	sv.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZSTD)
	
	match sv.create_server(port, server_info.max_players):
		ERR_ALREADY_IN_USE:
			state.perr("A server is already running, close it and try again.")
			get_tree().quit(ERR_ALREADY_IN_USE)
		ERR_CANT_CREATE:
			state.perr("Failed to create server.")
			get_tree().quit(ERR_CANT_CREATE)
		OK:
			state.plog("Server created successfully!")
	
	get_tree().set_network_peer(sv)

func unregister_player(id: int) -> void:
	emit_signal("player_left", id)
	# Remove player from list
	players.erase(id)
	# Call the clients to remove this player
	rpc("unregister_player", id)
	state.pdbg("Server player list: " + str(players))

func send_snapshot(ss: Dictionary) -> void:
	rpc_unreliable("receive_snapshot", ss)

func send_start_game_map() -> void:
	rpc("receive_start_game_map")

func send_rdict(rdict: Dictionary) -> void:
	rpc("receive_ready_dict", rdict)

#---------------------------#

remote func register_player(pinfo: Dictionary) -> void:
	# Check if server is full
	# NOTE: when implementing spectators, check for spectator max player list
	if players.size() >= state.PLAYERS_NEEDED:
		# Notify connected player and stop registering
		rpc_id(pinfo.id, "sv_full")
		return
	for player in players.values():
		# Check if a player with the same name exists
		if player.name == pinfo.name:
			# If so, notify connected player and stop registering
			rpc_id(pinfo.id, "sv_already_has")
			return
	for player in players.values():
		# Call the clients to add this new player to their lists
		rpc_id(player.id, "register_player", pinfo)
	# Call the new client to add every other player to their list
	rpc_id(pinfo.id, "register_players", players)
	# Add it to the local list
	players[pinfo.id] = pinfo
	emit_signal("player_joined", pinfo)
	rpc_id(pinfo.id, "sv_register")
	state.pdbg("Server player list: " + str(players))

remote func receive_input(idata: Dictionary, pid: int) -> void:
	emit_signal("input_received", idata, pid)

remote func receive_ready(ready: bool, pid: int) -> void:
	emit_signal("ready_received", ready, pid)

#---------------------------#
