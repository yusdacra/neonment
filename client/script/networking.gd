extends Node

var players: Dictionary = {}
var player: Dictionary = {
	id = 1,
	name = "Player",
	classname = "test_player",
}

const TIMEOUT: float = 5.0
var server_info: Dictionary = {
	name = "Server",
	max_players = 10,
	current_map = "test",
}
var udelta: float = 1.0 / 60

######### CLIENT ###########
var timeout_counter: float = 0.0
var latency_from_server: float = 0.0
var latency_to_server: float = 0.0
var latency_counter: float = 0.0
var averaged_latency: int = 0
var connected_to_server: bool = false

signal ready_to_play
signal connection_success
signal connection_fail
signal disconnected

signal new_player(pinfo)
signal player_left(id)
signal received_snapshot(ss)

func _ready() -> void:
	get_tree().connect("connected_to_server", self, "on_connect")
	get_tree().connect("server_disconnected", self, "on_disconnect")
	get_tree().connect("connection_failed", self, "on_connection_fail")
	utils.change_map_to("main_menu", false)

func _process(delta: float) -> void:
	if !connected_to_server:
		return
	
	if timeout_counter >= TIMEOUT:
		get_tree().set_network_peer(null)
		on_disconnect()
	
	ping_server()
	timeout_counter += delta
	
	latency_counter += delta
	if latency_counter >= 1.0:
		utils.plog("Latency: " + str(averaged_latency / 60))
		averaged_latency = 0
		latency_counter -= 1.0
	else:
		averaged_latency += (latency_from_server + latency_to_server) * 1000

func connect_to_server(ip: String, port: int) -> void:
	var client = NetworkedMultiplayerENet.new()
	# Hardcoded compression mode, must be same with server mode
	client.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZSTD)
		
	match client.create_client(ip, port):
		ERR_ALREADY_IN_USE:
			utils.perr("This port is already in use. Try a different one, or close whatever uses it.")
			return
		ERR_CANT_CREATE:
			utils.perr("Failed to create client.")
			return
		OK:
			utils.plog("Client created successfully!")
	
	timeout_counter = 0.0
	get_tree().set_network_peer(client)

func on_connect() -> void:
	connected_to_server = true
	player.id = get_tree().get_network_unique_id()
	set_network_master(player.id)
	rpc_id(1, "register_player", player)
	emit_signal("connection_success")

func on_connection_fail() -> void:
	get_tree().set_network_peer(null)
	utils.perr("Failed to connect to the server!")
	emit_signal("connection_fail")

func on_disconnect() -> void:
	connected_to_server = false
	players.clear()
	emit_signal("disconnected")

func ping_server() -> void:
	rpc_id(1, "pong", player.id)

#---------------------------#

func send_input_data(idata: Dictionary) -> void:
	rpc_unreliable_id(1, "receive_input", idata, player.id)

remote func register_player(pinfo: Dictionary) -> void:
	players[pinfo.id] = pinfo
	emit_signal("new_player", pinfo)

remote func register_players(psinfo: Dictionary) -> void:
	players = psinfo

remote func unregister_player(id: int) -> void:
	players.erase(id)
	emit_signal("player_left", id)

remote func receive_server_info(ud: float, svinfo: Dictionary) -> void:
	server_info = svinfo
	udelta = ud

remote func receive_snapshot(ss: Dictionary) -> void:
	emit_signal("received_snapshot", ss)

remote func ready_to_play() -> void:
	emit_signal("ready_to_play")

remote func pong() -> void:
	latency_to_server = timeout_counter
	timeout_counter = 0.0

remote func receive_ping_time(l: float) -> void:
	latency_from_server = l

############## CLIENT ################
