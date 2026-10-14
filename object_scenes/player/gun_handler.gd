class_name PlayerGunHandler
extends Node2D

@export var player :PlayerCar
@export var delay :float = 0.1

var timer :float = 0.0

func _process(delta: float) -> void:
	timer -= delta
	
	if Input.is_action_just_pressed("shoot"):
		summonBullet()
		timer = delay
	
	if Input.is_action_pressed("shoot") and timer <= 0.0:
		summonBullet()
		timer = delay
		


func summonBullet()-> void:
	var obj :BulletHitscan = load("res://object_scenes/bullets/hitscan/bullet_hitscan.tscn").instantiate()
	obj.global_position = global_position
	obj.rotation = get_local_mouse_position().angle()
	player.get_parent().add_child(obj)
