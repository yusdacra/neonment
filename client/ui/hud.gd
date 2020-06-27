extends Control

onready var player_row: BoxContainer = get_node("c/player_row")
onready var player_list: ItemList = player_row.get_node("player_list")
onready var player_name: Label = player_row.get_node("player_name")

onready var networking: Node = get_node("/root/root")
var beforeb: bool = false

func _ready() -> void:
	networking.connect("new_player", self, "_on_player_list_changed")
	networking.connect("player_left", self, "_on_player_list_changed")

	player_row.set_visible(false)
	player_name.set_text(networking.player.name)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta) -> void:
	var afterb: bool = false
	if Input.is_action_pressed("show_player_list"):
		player_row.set_visible(true)
		afterb = true
	else:
		player_row.set_visible(false)
		afterb = false
	if beforeb != afterb:
		_on_player_list_changed(null)
		beforeb = afterb

func _on_player_list_changed(_no) -> void:
	player_list.clear()
	for p in state.players.values():
		player_list.add_item(p.name, null, false)
		state.pdbg("Player with name " + p.name + " has been added to the player list node!")
