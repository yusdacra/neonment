extends KinematicBody

onready var udelta: float = get_node("/root/root").udelta
onready var movement: Node = get_node("movement")
onready var head: Spatial = get_node("head")
onready var ability: Node = get_node("ability")

func process_input(input_data: Dictionary) -> void:
	movement.process_input(input_data)
	for a in ability.get_children():
		a.process_input(input_data)

func apply_state(pstate: Dictionary) -> void:
	var alpha = pstate.time / udelta
	set_translation(lerp(pstate.from.translation, pstate.to.translation, alpha))
	set_rotation(pstate.to.rotation)
	head.set_rotation(pstate.to.head_rotation)

func get_state() -> Dictionary:
	return {
		translation = get_translation(),
		rotation = get_rotation(),
		head_rotation = head.get_rotation(),
	}
