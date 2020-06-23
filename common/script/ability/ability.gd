extends Node

# This is the general "timer" kind of class for abilities.
# An ability must implement:
# _init(properties: Dictionary, player: KinematicBody) # executed once when the ability is created
# execute() # executed once when the ability is triggered
# loop() # executed each frame (not including the start frame of the ability)
# end() # executed once when the ability duration wears off

export var duration: float = 1.0
export var cooldown: float = 5.0
export var hotkey_index: int = 0
export var ability_name: String
export var ability_properties: Dictionary
var last_dc_frame: int = 0
var last_cc_frame: int = 0
onready var ability: Node = load("res://common/script/ability/" + ability_name + ".gd").new(ability_properties, get_node("../.."))

func _ready() -> void:
	state.connect("new_frame", self, "update_loop")

func process_input(input_data: Dictionary) -> void:
	if input_data.ability[hotkey_index] && !is_running() && !is_on_cooldown():
		ability.execute()
		last_dc_frame = state.frame

func update_loop() -> void:
	if is_running():
		ability.loop()
		if state.did_pass(last_dc_frame, duration):
			ability.end()
			last_dc_frame = 0
			last_cc_frame = state.frame
	elif is_on_cooldown() && state.did_pass(last_cc_frame, cooldown):
		last_cc_frame = 0

func is_running() -> bool:
	return last_dc_frame > 0

func is_on_cooldown() -> bool:
	return last_cc_frame > 0
