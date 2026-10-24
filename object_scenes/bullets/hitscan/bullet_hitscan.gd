class_name BulletHitscan
extends Node2D


@export var gradient :Gradient

@export var shadowLine :Line2D
@export var bulletLine :Line2D

var amountOfPoints :int = 16

var waveVector :PackedVector2Array = PackedVector2Array()

var motionVector :Vector2 = Vector2.ZERO

var type:int = 0 # 0: normal, 1: boosted, 2: super boosted

func _ready() -> void:
	
	if type == 1:
		bulletLine.texture = load("res://object_scenes/bullets/hitscan/boost.png")
		bulletLine.width = 8.0
	elif type == 2:
		bulletLine.texture = load("res://object_scenes/bullets/hitscan/boost2.png")
		bulletLine.width = 16.0
	
	var lineLength :float = 420
	
	var guy :Array[Hitbox]= ManagerDamager.getHitboxOnLine(global_position,Vector2(1,0).rotated(rotation),lineLength,type*4.0,GlobalReference.player,false)
	if guy.size() > 0:
		lineLength = guy[0].global_position.distance_to(global_position)
		guy[0].healthCompenent.recieveKnockback( Vector2(200,0).rotated(rotation) )
		guy[0].healthCompenent.dealDamage(5 * (type+1))
	
	# play animation
	for i in range(amountOfPoints):
		shadowLine.add_point( Vector2( (lineLength/float(amountOfPoints)) * i  ,0.0 ) )
		waveVector.append( Vector2(randf_range(-2.0,2.0),randf_range(-2.0,2.0)) )
		
	
	
	bulletLine.points = shadowLine.points
	bulletLine.position = Vector2(0,-8.0).rotated(-rotation) * Vector2(1,0.75)
	
	bulletLine.default_color = gradient.sample(0.0)
	
	motionVector += Vector2(100,0).rotated(rotation)
	
	
	if type == 2:
		for i in range(7):
			applyWind()
	
	await get_tree().process_frame
	
	bulletLine.width = 3.0
	shadowLine.width = 2.0
	
	bulletLine.default_color = gradient.sample(0.25)
	
	await get_tree().process_frame
	
	bulletLine.width = 2.0
	shadowLine.width = 1.0
	
	bulletLine.default_color = gradient.sample(0.5)
	
	
	await get_tree().process_frame
	
	bulletLine.width = 1.0
	shadowLine.width = 0.5
	applyWind()
	bulletLine.default_color = gradient.sample(0.75)
	
	await get_tree().process_frame
	
	motionVector += Vector2(60,40)
	
	bulletLine.width = 0.5
	shadowLine.width = 0.25
	bulletLine.default_color = gradient.sample(1.0)
	applyWind()
	await get_tree().process_frame
	shadowLine.hide()
	bulletLine.default_color = Color(0.193, 0.193, 0.193, 1.0)
	applyWind()
	bulletLine.modulate.a = 0.8
	await get_tree().process_frame
	applyWind()
	bulletLine.modulate.a = 0.6
	await get_tree().process_frame
	applyWind()
	bulletLine.modulate.a = 0.4
	await get_tree().process_frame
	applyWind()
	bulletLine.modulate.a = 0.2
	await get_tree().process_frame
	queue_free()

func applyWind() -> void:
	for index in range(amountOfPoints):
		if index == 0:
			continue
		var vec :Vector2 = shadowLine.get_point_position(index)
		shadowLine.set_point_position(index,vec+waveVector[index])
		bulletLine.set_point_position(index,vec+waveVector[index])

func _process(delta: float) -> void:
	position += motionVector * delta
