extends KinematicBody

onready var movement: Node = get_node("movement")
onready var head: Spatial = get_node("head")
onready var abilities: Node = get_node("abilities")

func process_input(input_data: Dictionary) -> void:
	movement.process_input(input_data)
	for a in abilities.get_children():
		a.process_input(input_data)

func apply_state(pstate: Dictionary) -> void:
	var alpha = pstate.time / state.UDELTA
	set_translation(lerp(pstate.from.translation, pstate.to.translation, alpha))
	set_rotation(pstate.to.rotation)
	head.set_rotation(pstate.to.head_rotation)

func get_state() -> Dictionary:
	return {
		translation = get_translation(),
		rotation = get_rotation(),
		head_rotation = head.get_rotation(),
	}
