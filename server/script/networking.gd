extends Node

var port: int = state.config.port

signal player_joined(pinfo)
signal player_left(id)
signal input_received(idata, id)
signal ready_received(ready, id)

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "client_connected")
	get_tree().connect("network_peer_disconnected", self, "client_disconnected")
	
	state.server_info.name = state.config.name
	state.server_info.max_clients = state.config.max_clients
	state.server_info.game = state.config.game

	# Extract map info that client needs
	var sp = load("res://server/map_sp/" + state.server_info.game.map + ".tscn").instance()
	state.server_info.game.team_count = sp.get_child_count()
	state.server_info.game.max_players = 0
	for sps in sp.get_children():
		state.server_info.game.max_players += sps.get_child_count()
	sp.free()
	
	create_server()
	state.change_map_to("lobby", false)

func client_connected(id) -> void:
	state.pdbg("Client " + str(id) + " connected to server")
	rpc_id(id, "sv_info", state.server_info)

func client_disconnected(id) -> void:
	state.pdbg("Client " + str(id) + " disconnected from server")
	unregister_player(id)

func create_server() -> void:
	state.plog("Starting server with configuration:")
	state.plog("Server name: " + str(state.server_info.name))
	state.plog("Port: " + str(port))
	state.plog("Max clients: " + str(state.server_info.max_clients))
	state.plog("Map: " + str(state.server_info.game.map))
	state.plog("Max players: " + str(state.server_info.game.max_players))
	state.plog("Team count: " + str(state.server_info.game.team_count))
	
	var sv := NetworkedMultiplayerENet.new()
	sv.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZSTD)
	
	match sv.create_server(port, state.server_info.max_clients):
		ERR_ALREADY_IN_USE:
			state.perr("A server is already running, close it and try again.")
			get_tree().quit(ERR_ALREADY_IN_USE)
			return
		ERR_CANT_CREATE:
			state.perr("Failed to create server.")
			get_tree().quit(ERR_CANT_CREATE)
			return
		OK:
			state.plog("Server created successfully!")
	
	get_tree().set_network_peer(sv)

func unregister_player(id: int) -> void:
	emit_signal("player_left", id)
	# Remove player from list
	state.players.erase(id)
	# Call the clients to remove this player
	rpc("unregister_player", id)
	state.pdbg("Server player list: " + str(state.players))

func send_snapshot(ss: Dictionary) -> void:
	rpc_unreliable("receive_snapshot", ss)

func send_change_map(map_name: String, game_map: bool = true) -> void:
	rpc("receive_change_map", map_name, game_map)

func send_rdict(rdict: Dictionary) -> void:
	rpc("receive_ready_dict", rdict)

remote func register_player(pinfo: Dictionary) -> void:
	# Check if the server is "full"
	if state.players.size() >= state.server_info.game.max_players:
		rpc_id(pinfo.id, "sv_wont_register", "Server is full.")
		return
	for player in state.players.values():
		# Check if a player with the same name exists
		if player.name == pinfo.name:
			# If so, notify connected player and stop registering
			rpc_id(pinfo.id, "sv_wont_register", "Server already has a player with the same name.")
			return
	# TODO: Make servers be able to specify a regex for invalid names
	if pinfo.name.empty():
		rpc_id(pinfo.id, "sv_wont_register", "Server does not allow your name.")
		return
	for player in state.players.values():
		# Call the clients to add this new player to their lists
		rpc_id(player.id, "register_player", pinfo)
	# Call the new client to add every other player to their list
	rpc_id(pinfo.id, "register_players", state.players)
	# Add it to the local list
	state.players[pinfo.id] = pinfo
	emit_signal("player_joined", pinfo)
	rpc_id(pinfo.id, "sv_register")
	state.pdbg("Server player list: " + str(state.players))

remote func receive_input(idata: Dictionary, pid: int) -> void:
	emit_signal("input_received", idata, pid)

remote func receive_ready(ready: bool, pid: int) -> void:
	emit_signal("ready_received", ready, pid)
