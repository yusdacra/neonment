extends Control

export var pl_path: NodePath
onready var player_list: ItemList = get_node(pl_path)
export var pr_path: NodePath
onready var player_row: BoxContainer = get_node(pr_path)
export var pn_path: NodePath
onready var player_name: Label = get_node(pn_path)
var networking: Node

func _ready():
	networking = utils.networking()
	networking.connect("new_player", self, "_on_player_list_changed")
	networking.connect("player_left", self, "_on_player_list_changed")

	player_row.set_visible(false)
	player_name.set_text(networking.player.name)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	if Input.is_action_pressed("show_player_list"):
		player_row.set_visible(true)
	else:
		player_row.set_visible(false)

func _on_player_list_changed(_no):
	player_list.clear()
	for p in networking.players.values():
		player_list.add_item(p.name, null, false)
		print_debug("Player with name ", p.name, " has been added to the player list node!")
