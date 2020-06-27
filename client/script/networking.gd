extends Node

var player: Dictionary = {
	id = 1,
	name = state.config.nickname,
	classname = "test_player",
}

signal connection_success
signal connection_fail(reason)
signal disconnected(reason)
signal game_map_started
signal registered_by_sv

signal new_player(pinfo)
signal player_left(id)
signal received_snapshot(ss)
signal received_rdict(rdict)

func _ready() -> void:
	get_tree().connect("connected_to_server", self, "on_connect")
	get_tree().connect("server_disconnected", self, "on_disconnect")
	get_tree().connect("connection_failed", self, "on_connection_fail")
	
	state.change_map_to("main_menu", false)

func on_connect() -> void:
	player.id = get_tree().get_network_unique_id()
	set_network_master(player.id)

func on_connection_fail(reason: String = "Unknown reason.") -> void:
	get_tree().set_network_peer(null)
	state.perr("Failed to connect to the server: " + reason)
	emit_signal("connection_fail", reason)

func on_disconnect(reason: String = "Unknown reason.") -> void:
	get_tree().call_deferred("set_network_peer", null)
	state.players.clear()
	state.plog("Disconnected from the server: " + reason)
	emit_signal("disconnected", reason)

func connect_to_server(ip: String, port: int) -> void:
	var client = NetworkedMultiplayerENet.new()
	client.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZSTD)
		
	match client.create_client(ip, port):
		ERR_ALREADY_IN_USE:
			state.perr("This port is already in use. Try a different one, or close whatever uses it.")
			return
		ERR_CANT_CREATE:
			state.perr("Failed to create client.")
			return
		OK:
			state.plog("Client created successfully!")
	
	get_tree().set_network_peer(client)

func send_input_data(idata: Dictionary) -> void:
	rpc_unreliable_id(1, "receive_input", idata, player.id)

func send_ready(ready: bool) -> void:
	rpc_id(1, "receive_ready", ready, player.id)

remote func register_player(pinfo: Dictionary) -> void:
	state.players[pinfo.id] = pinfo
	emit_signal("new_player", pinfo)

remote func register_players(psinfo: Dictionary) -> void:
	state.players = psinfo

remote func unregister_player(id: int) -> void:
	state.players.erase(id)
	emit_signal("player_left", id)

remote func sv_info(svinfo: Dictionary) -> void:
	state.server_info = svinfo
	rpc_id(1, "register_player", player)
	emit_signal("connection_success")

remote func receive_snapshot(ss: Dictionary) -> void:
	emit_signal("received_snapshot", ss)

remote func receive_ready_dict(rdict: Dictionary) -> void:
	emit_signal("received_rdict", rdict)

remote func receive_change_map(map_name: String, game_map: bool) -> void:
	state.change_map_to(map_name, game_map)

remote func sv_register() -> void:
	emit_signal("registered_by_sv")

remote func sv_wont_register(reason: String) -> void:
	get_tree().emit_signal("connection_failed", reason)
