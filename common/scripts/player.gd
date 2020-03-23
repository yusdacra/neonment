extends KinematicBody

const FLOOR_NORMAL := Vector3.UP

export var head_path: NodePath
onready var head: Spatial = get_node(head_path)
export var gravity: float = 30.0
export var walk_speed: float = 10.0
export var sprint_speed: float = 16.0
export var dash_speed: float = 50.0
export var acceleration: float = 8.0
export var deacceleration: float = 10.0
export(float, 0, 1, 0.05) var air_control: float = 0.3
export var jump_height: float = 10.0
export var floor_max_angle: float = 45.0
export var max_jump: int = 2

var cur_jump: int = 0
var velocity := Vector3()
var current_time: float = 0.0
var mouse_axis := Vector2()
onready var udelta: float = utils.networking().udelta

func _input(event) -> void:
	if event is InputEventMouseMotion:
		mouse_axis = event.relative

func gather_input() -> Dictionary:
	var idata: Dictionary = {
		forward = Input.is_action_pressed("move_forward"),
		backward = Input.is_action_pressed("move_backward"),
		left = Input.is_action_pressed("move_left"),
		right = Input.is_action_pressed("move_right"),
		jump = Input.is_action_just_pressed("move_jump"),
		sprint = Input.is_action_pressed("move_sprint"),
		mouse_axis = mouse_axis,
	}
	
	mouse_axis = Vector2()
	
	return idata

func apply_state(pstate: Dictionary):
	var alpha = pstate.time / udelta
	set_translation(lerp(pstate.from.translation, pstate.to.translation, alpha))
	set_rotation(pstate.to.rotation)
	get_node("head").set_rotation(pstate.to.head_rotation)

func get_state() -> Dictionary:
	return {
		translation = get_translation(),
		rotation = get_rotation(),
		head_rotation = get_node("head").get_rotation(),
	}

func process_state(input_data: Dictionary):
	# Input
	var direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if input_data.forward:
		direction -= aim.z
	if input_data.backward:
		direction += aim.z
	if input_data.left:
		direction -= aim.x
	if input_data.right:
		direction += aim.x
	direction.y = 0
	direction = direction.normalized()
	
	# Jump
	var _snap: Vector3
	if is_on_floor():
		cur_jump = 0
		_snap = Vector3.DOWN
		if input_data.jump && cur_jump < max_jump:
			_snap = Vector3.ZERO
			velocity.y = jump_height
			cur_jump += 1
	elif input_data.jump && cur_jump < max_jump:
		_snap = Vector3.ZERO
		velocity.y = jump_height
		cur_jump += 1
	
	velocity.y -= gravity * udelta

	var _speed: float
	if input_data.forward && input_data.sprint:
		_speed = sprint_speed
	else:
		_speed = walk_speed
	
	var _temp_vel: Vector3 = velocity
	_temp_vel.y = 0
	var _target: Vector3 = direction * _speed
	var _temp_accel: float
	if direction.dot(_temp_vel) > 0:
		_temp_accel = acceleration
	else:
		_temp_accel = deacceleration
	if not is_on_floor():
		_temp_accel *= air_control
	# interpolation
	_temp_vel = _temp_vel.linear_interpolate(_target, _temp_accel * udelta)
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	# clamping
	if direction.dot(velocity) == 0:
		var _vel_clamp: float = 0.25
		if velocity.x < _vel_clamp && velocity.x > -_vel_clamp:
			velocity.x = 0
		if velocity.z < _vel_clamp && velocity.z > -_vel_clamp:
			velocity.z = 0
	
	# Move
	velocity.y = move_and_slide_with_snap(velocity, _snap, FLOOR_NORMAL, 
			true, 4, deg2rad(floor_max_angle)).y
	
	# Rotation
	rotate_y(deg2rad(-input_data.mouse_axis.x))
	head.rotate_x(deg2rad(-input_data.mouse_axis.y))
	
	# Clamp rotation
	var temp_rot: Vector3 = head.rotation_degrees
	temp_rot.x = clamp(temp_rot.x, -80, 80)
	head.rotation_degrees = temp_rot
