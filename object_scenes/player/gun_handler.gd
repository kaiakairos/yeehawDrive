class_name PlayerGunHandler
extends Node2D

@export var flashSprite1 :Sprite2D
@export var flashSprite2 :Sprite2D


@export var player :PlayerCar
@export var delay :float = 0.12
@export var accuracy :float = 0.16

var timer :float = 0.0

func _process(delta: float) -> void:
	timer -= delta
	
	if Input.is_action_just_pressed("shoot"):
		summonBullet()
		timer = delay
	
	if Input.is_action_pressed("shoot") and timer <= 0.0:
		summonBullet()
		timer = delay

	$"../SubViewport/Flash".modulate.a = move_toward($"../SubViewport/Flash".modulate.a,0.0,delta * 4.0)

func summonBullet()-> void:
	var obj :BulletHitscan = load("res://object_scenes/bullets/hitscan/bullet_hitscan.tscn").instantiate()
	obj.global_position = global_position
	obj.rotation = get_local_mouse_position().angle() + randf_range(-accuracy,accuracy)
	obj.motionVector = player.velocity * 0.5
	player.get_parent().add_child(obj)
	blastEffect()
	
	createCasing()

func createCasing() -> void:
	var obj :BulletCasing = load("res://object_scenes/bulletCasing/bullet_casing.tscn").instantiate()
	obj.global_position = global_position + Vector2( randf_range(-4,4),randf_range(-4,4))
	
	obj.velocity = player.velocity + (get_local_mouse_position().normalized().rotated(randf_range(-0.2,0.2)) * randf_range(50,80) * -1)
	
	
	player.get_parent().add_child(obj)


func blastEffect()-> void:
	flashSprite1.show()
	flashSprite2.show()
	
	flashSprite2.scale = Vector2(2,2)
	flashSprite1.rotation = randf_range(-PI,PI)
	
	flashSprite1.scale = Vector2(1.0,1.0)
	flashSprite2.rotation = randf_range(-PI,PI)
	
	flashSprite2.position = flashSprite1.position + (get_local_mouse_position().normalized() * 12)
	
	$"../SubViewport/Flash".modulate.a = 0.5
	$"../SubViewport/Flash".rotation = randf()
	
	await get_tree().process_frame
	flashSprite2.scale = Vector2(1.5,1.5)
	flashSprite1.scale = Vector2(0.75,0.75)
	flashSprite2.position = flashSprite1.position + (get_local_mouse_position().normalized() * 10)
	await get_tree().process_frame
	flashSprite1.hide()
	flashSprite2.hide()
	
