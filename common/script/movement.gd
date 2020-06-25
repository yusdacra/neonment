extends Node

const FLOOR_NORMAL := Vector3.UP
const VEL_CLAMP: float = 0.25
export var gravity: float = 30.0
export var walk_speed: float = 10.0
export var sprint_speed: float = 16.0
export var jump_height: float = 10.0
export var max_jump: int = 2

var cur_jump: int = 0
var velocity := Vector3()
var locked: bool = false
onready var player: KinematicBody = get_parent()

func process_input(input_data: Dictionary):
	if locked:
		return
	
	# Rotation
	# TODO: Clamp mouse_axis
	player.rotate_y(deg2rad(-input_data.mouse_axis.x))
	player.get_node("head").rotate_x(deg2rad(-input_data.mouse_axis.y))
	
	# Clamp rotation
	var temp_rot: Vector3 = player.get_node("head").rotation_degrees
	temp_rot.x = clamp(temp_rot.x, -80, 80)
	player.get_node("head").rotation_degrees = temp_rot
	
	var direction := Vector3()
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
	
	var is_on_floor: bool = player.is_on_floor()
	var snap: Vector3
	if is_on_floor:
		cur_jump = 0
		snap = Vector3.DOWN
	if input_data.jump && cur_jump < max_jump:
		snap = Vector3.ZERO
		velocity.y = jump_height
		cur_jump += 1
	
	velocity.y -= gravity * state.UDELTA

	var speed: float = sprint_speed if input_data.forward && input_data.sprint else walk_speed
	
	var target: Vector3 = direction * speed
	
	velocity.x = target.x
	velocity.z = target.z
	
	# Move
	velocity.y = player.move_and_slide_with_snap(velocity, snap, FLOOR_NORMAL, true).y
