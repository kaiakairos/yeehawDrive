class_name PlayerGunHandler
extends Node2D

@export var flashSprite1 :Sprite2D
@export var flashSprite2 :Sprite2D
@export var flashSpriteUV :Sprite2D

@export var player :PlayerCar
@export var delay :float = 0.2
@export var delayBoost :float = 0.12
@export var delayBoost2 :float = 0.11
@export var accuracy :float = 0.16

var timer :float = 0.0

var BULLETMODE :int = 0 # 0: NORMAL, 1: FIRED UP, 2: VEGETA COOL BLUE

func setBulletMode(mode:int) -> void:
	if BULLETMODE == mode:
		return # don't switch to mode we already are 
	BULLETMODE = mode
	

func _process(delta: float) -> void:
	timer -= delta
	#BULLETMODE = 2
	if Input.is_action_just_pressed("shoot"):
		summonBullet()
		resetTimer()
	
	if Input.is_action_pressed("shoot") and timer <= 0.0:
		summonBullet()
		resetTimer()

	flashSpriteUV.modulate.a = move_toward(flashSpriteUV.modulate.a,0.0,delta * 4.0)

func summonBullet()-> void:
	var obj :BulletHitscan = load("res://object_scenes/bullets/hitscan/bullet_hitscan.tscn").instantiate()
	obj.global_position = global_position
	obj.rotation = get_local_mouse_position().angle() + randf_range(-accuracy,accuracy)
	obj.motionVector = player.velocity * 0.5
	obj.type = BULLETMODE
	player.get_parent().add_child(obj)
	blastEffect()
	
	createCasing()
	playBulletSound()

func createCasing() -> void:
	var obj :BulletCasing = load("res://object_scenes/bulletCasing/bullet_casing.tscn").instantiate()
	obj.global_position = global_position + Vector2( randf_range(-4,4),randf_range(-4,4))
	
	obj.velocity = player.velocity + (get_local_mouse_position().normalized().rotated(randf_range(-0.2,0.2)) * randf_range(50,80) * -1)
	
	
	player.get_parent().add_child(obj)


func blastEffect()-> void:
	
	flashSprite1.frame = BULLETMODE
	flashSprite2.frame = BULLETMODE
	flashSpriteUV.frame = BULLETMODE
	
	flashSprite1.show()
	flashSprite2.show()
	
	flashSprite2.scale = Vector2(2,2)
	flashSprite1.rotation = randf_range(-PI,PI)
	
	flashSprite1.scale = Vector2(1.0,1.0)
	flashSprite2.rotation = randf_range(-PI,PI)
	
	flashSprite2.position = flashSprite1.position + (get_local_mouse_position().normalized() * 12)
	
	flashSpriteUV.modulate.a = 0.5
	flashSpriteUV.rotation = randf()
	
	await get_tree().process_frame
	flashSprite2.scale = Vector2(1.5,1.5)
	flashSprite1.scale = Vector2(0.75,0.75)
	flashSprite2.position = flashSprite1.position + (get_local_mouse_position().normalized() * 10)
	await get_tree().process_frame
	flashSprite1.hide()
	flashSprite2.hide()
	
func resetTimer() -> void:
	match BULLETMODE:
		0: timer = delay
		1: timer = delayBoost
		2: timer = delayBoost2

func playBulletSound() -> void:
	pass
