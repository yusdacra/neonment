extends Node

var dash_speed: float
var player: KinematicBody
var translate_by: Vector3

func _init(properties: Dictionary, player: KinematicBody) -> void:
	self.dash_speed = properties["dash_speed"]
	self.player = player

func execute() -> void:
	player.movement.locked = true
	
	var direction: Vector3 = Quat(player.head.get_global_transform().basis).normalized() * Vector3.FORWARD
	translate_by = direction * dash_speed

func loop() -> void:
	player.movement.velocity.x = translate_by.x
	player.movement.velocity.y = translate_by.y
	player.movement.velocity.z = translate_by.z
	
	player.move_and_slide(player.movement.velocity, player.movement.FLOOR_NORMAL)

func end() -> void:
	player.movement.locked = false
