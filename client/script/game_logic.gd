extends Spatial

var from_to: Dictionary = {} # Interpolation entries
var last_ss_timestamp: int = -1 # Timestamp of the last received snapshot
var last_pi_timestamp: int = 0 # Timestamp of the input the server last processed
var input_timestamp: int = 0 # Timestamp of the last input sent
var sent_inputs: Dictionary = {} # Holds sent inputs that the server hasn't processed & sent back to us yet
var player_node: KinematicBody
var mouse_axis := Vector2()
onready var input: Dictionary = gather_input()
onready var networking: Node = get_node("/root/root")

func _ready() -> void:
	state.connect("new_frame", self, "update")
	networking.connect("disconnected", self, "on_disconnect")
	networking.connect("new_player", self, "spawn_player")
	networking.connect("player_left", self, "remove_player")
	networking.connect("received_snapshot", self, "apply_snapshot")

	# Spawn local player (position doesnt matter as it will be updated by the server)
	spawn_player(networking.player)
	# For convenience, store the player node inside a variable
	player_node = get_node(str(networking.player.id))
	# Spawn other players
	for p in state.players.values():
		spawn_player(p)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		mouse_axis = event.relative * state.config.mouse_sens
	# TODO: Replace this with a "pause" menu
	if event.is_action_pressed("ui_cancel"):
		get_tree().emit_signal("server_disconnected", "Disconnect requested.")

func _process(delta):
	# We collect the inputs here and "remember" them until they are sent to the server in "update()"
	var input_temp: Dictionary = gather_input()
	input.forward = input_temp.forward || input.forward
	input.backward = input_temp.backward || input.backward
	input.left = input_temp.left || input.left
	input.right = input_temp.right || input.right
	input.jump = input_temp.jump || input.jump
	input.sprint = input_temp.sprint || input.sprint
	input.ability[0] = input_temp.ability[0] || input.ability[0]
	input.ability[1] = input_temp.ability[1] || input.ability[1]
	input.ability[2] = input_temp.ability[2] || input.ability[2]
	input.ability[3] = input_temp.ability[3] || input.ability[3]
	input.mouse_axis += input_temp.mouse_axis

func update() -> void:
	var idata = {
		pinput = input,
		timestamp = input_timestamp,
	}
	input_timestamp += 1
	networking.send_input_data(idata)
	# Cache the input for later use
	sent_inputs[idata.timestamp] = idata
	# Predict server state using the inputs that hasn't been recognized by the server
	for itimestamp in sent_inputs:
		if itimestamp <= last_pi_timestamp:
			# If recognized, delete this input entry
			sent_inputs.erase(itimestamp)
		else:
			# If not, process it
			player_node.process_input(sent_inputs[itimestamp].pinput)
	input = {
		forward = false,
		backward = false,
		left = false,
		right = false,
		jump = false,
		sprint = false,
		mouse_axis = Vector2(),
		ability = [false, false, false, false],
	}

func on_disconnect(reason: String) -> void:
	state.change_map_to("multiplayer", false)

# Remove the player from the scene
func remove_player(id: int) -> void:
	get_node(str(id)).free()
	state.pdbg("Removed player with id " + str(id))

func spawn_player(pinfo: Dictionary, spawn_point: Vector3 = Vector3(0, 20, 0)) -> void:
	var new_player: KinematicBody = load("res://common/entity/" + pinfo.classname + ".tscn").instance()
	new_player.set_name(str(pinfo.id))
	if pinfo.id != networking.player.id:
		# If not local player, add the body (so that the local player can see others)
		new_player.add_child(load("res://client/entity_vis/" + pinfo.classname + ".tscn").instance())
	else:
		# If local player, add the camera
		new_player.get_node("head").add_child(Camera.new())
		# NOTE: Viewmodel should be spawned here
	new_player.set_translation(spawn_point)
	add_child(new_player)

func apply_snapshot(ss: Dictionary) -> void:
	# If this snapshots timestamp is older than the previous one's then
	# don't apply it
	if ss.timestamp <= last_ss_timestamp:
		return
	last_ss_timestamp = ss.timestamp
	last_pi_timestamp = ss.player_states[networking.player.id].timestamp
	
	for id in ss.player_states:
		var pnode = get_node(str(id))
		 
		if !pnode:
			return
		
		if from_to.has(id):
			from_to[id].from = from_to[id].to
			from_to[id].to = ss.player_states[id].pstate
			from_to[id].time = 0.0
		else:
			from_to[id] = {
				from = ss.player_states[id].pstate,
				to = ss.player_states[id].pstate,
				time = state.UDELTA,
			}
		
		if from_to[id].time < state.UDELTA:
			from_to[id].time += get_process_delta_time()
		else:
			return
		
		pnode.apply_state(from_to[id])

func gather_input() -> Dictionary:
	var idata: Dictionary = {
		forward = Input.is_action_pressed("move_forward"),
		backward = Input.is_action_pressed("move_backward"),
		left = Input.is_action_pressed("move_left"),
		right = Input.is_action_pressed("move_right"),
		# NOTE: don't make this "is_action_pressed" it breaks double jumping
		jump = Input.is_action_just_pressed("move_jump"),
		sprint = Input.is_action_pressed("move_sprint"),
		mouse_axis = self.mouse_axis,
		ability = [
			Input.is_action_just_pressed("ability_0"),
			Input.is_action_just_pressed("ability_1"),
			Input.is_action_just_pressed("ability_2"),
			Input.is_action_just_pressed("ability_3"),
		],
	}
	mouse_axis = Vector2()
	return idata
