extends Node

# This is the general "timer" kind of class for abilities.
# An ability must implement "execute", "loop" and "end" functions.

export var duration: float = 1.0
export var cooldown: float = 5.0
export var hotkey_index: int = 0
export var ability_name: String
export var ability_properties: Dictionary
var dcounter: float = 0.0
var ccounter: float = 0.0
var current_time: float = 0.0
onready var udelta: float = get_node("/root/root").udelta
onready var ability: Node = load("res://common/script/ability/" + ability_name + ".gd").new(ability_properties, get_node("../.."))

func process_input(input_data: Dictionary) -> void:
	if input_data.ability[hotkey_index] && !is_running() && !is_on_cooldown():
		ability.execute()
		dcounter = udelta

func _process(delta: float) -> void:
	current_time += delta
	if current_time < udelta:
		return
	current_time -= udelta
	
	if is_running():
		dcounter += udelta
		ability.loop()
		if dcounter >= duration:
			ability.end()
			dcounter = 0.0
			ccounter = udelta
	elif is_on_cooldown():
		ccounter += udelta
		if ccounter >= cooldown:
			ccounter = 0.0

func is_running() -> bool:
	return dcounter > 0.0

func is_on_cooldown() -> bool:
	return ccounter > 0.0
