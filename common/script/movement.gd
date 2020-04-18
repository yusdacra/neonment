extends Node

const FLOOR_NORMAL := Vector3.UP
const VEL_CLAMP: float = 0.25
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
var locked: bool = false
onready var player: KinematicBody = get_parent()

func process_input(input_data: Dictionary):
	if locked:
		return
	
	var direction = Vector3()
	var aim: Basis = player.get_global_transform().basis
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
	
	var is_on_floor = player.is_on_floor()
	var _snap: Vector3
	if is_on_floor:
		cur_jump = 0
		_snap = Vector3.DOWN
	if input_data.jump && cur_jump < max_jump:
		_snap = Vector3.ZERO
		velocity.y = jump_height
		cur_jump += 1
	
	velocity.y -= gravity * state.UDELTA

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
	if !is_on_floor:
		_temp_accel *= air_control
	# interpolation
	_temp_vel = _temp_vel.linear_interpolate(_target, _temp_accel * state.UDELTA)
	velocity.x = _temp_vel.x
	velocity.z = _temp_vel.z
	# clamping
	if direction.dot(velocity) == 0:
		if velocity.x < VEL_CLAMP && velocity.x > -VEL_CLAMP:
			velocity.x = 0
		if velocity.z < VEL_CLAMP && velocity.z > -VEL_CLAMP:
			velocity.z = 0
	
	# Move
	velocity.y = player.move_and_slide_with_snap(velocity, _snap, FLOOR_NORMAL, true).y
	# Rotation
	player.rotate_y(deg2rad(-input_data.mouse_axis.x))
	player.get_node("head").rotate_x(deg2rad(-input_data.mouse_axis.y))
	
	# Clamp rotation
	var temp_rot: Vector3 = player.get_node("head").rotation_degrees
	temp_rot.x = clamp(temp_rot.x, -80, 80)
	player.get_node("head").rotation_degrees = temp_rot
