extends Node

var mouse_axis := Vector2()

func _input(event) -> void:
	if event is InputEventMouseMotion:
		mouse_axis = event.relative

func gather_input() -> Dictionary:
	var idata: Dictionary = {
		forward = Input.is_action_pressed("move_forward"),
		backward = Input.is_action_pressed("move_backward"),
		left = Input.is_action_pressed("move_left"),
		right = Input.is_action_pressed("move_right"),
		jump = Input.is_action_just_pressed("move_jump"), # NOTE: don't make this "pressed" it breaks double jumping
		sprint = Input.is_action_pressed("move_sprint"),
		mouse_axis = mouse_axis,
		ability = [
			Input.is_action_just_pressed("ability_0"),
			Input.is_action_just_pressed("ability_1"),
			Input.is_action_just_pressed("ability_2"),
			Input.is_action_just_pressed("ability_3"),
		],
	}
	mouse_axis = Vector2()
	return idata
