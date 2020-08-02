extends Control

onready var player_row: BoxContainer = get_node("c/player_row")
onready var player_list: ItemList = player_row.get_node("player_list")
onready var player_name: Label = player_row.get_node("player_name")

onready var networking: Node = get_node("/root/root")
var pressed_before := false

func _ready() -> void:
	networking.connect("new_player", self, "on_player_list_changed")
	networking.connect("player_left", self, "on_player_list_changed")

	player_row.set_visible(false)
	player_name.set_text(networking.player.name)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta) -> void:
	var pressed_now := false
	if Input.is_action_pressed("show_player_list"):
		player_row.set_visible(true)
		pressed_now = true
	else:
		player_row.set_visible(false)
		pressed_now = false
	if pressed_before != pressed_now:
		on_player_list_changed(null)
		pressed_before = pressed_now

func on_player_list_changed(_no_need_for_arg) -> void:
	player_list.clear()
	for p in state.players.values():
		player_list.add_item(p.name, null, false)
		state.pdbg("Player with name " + p.name + " has been added to the HUD player list node!")
