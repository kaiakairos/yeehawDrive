class_name BoidFlyer
extends Node2D

var velocity := Vector2.ZERO

enum states {NORMAL,EXPLODE,DYING}
var state :int = 0

var spin :float = 0.0
var noise :FastNoiseLite = FastNoiseLite.new()

var offsetTargetAngle :float = 0.0

func _ready() -> void:
	
	if randi() % 2 == 0:
		offsetTargetAngle = Vector2(0,1).rotated(randf_range(-0.02,0.02)).angle()
	else:
		offsetTargetAngle = Vector2(0,-1).rotated(randf_range(-0.02,0.02)).angle()
	
	add_to_group("boidAvoid")

func _process(delta: float) -> void:
	match state:
		states.NORMAL:
			velocity = stateNormal(velocity,delta)
		
		states.EXPLODE:
			velocity = velocity.move_toward(Vector2.ZERO,delta*1400.0)
		
		
		states.DYING:
			velocity = stateNormal(velocity,delta)
	
	
	position += velocity * delta

func stateNormal(vel:Vector2,delta:float) -> Vector2:
	
	var player :PlayerCar = GlobalReference.player
	var distanceVector :Vector2 = (player.predictFuturePosition(0.25) + Vector2(8,0).rotated(offsetTargetAngle).rotated(player.velocity.angle())) - global_position
	
	#global_position = distanceVector + global_position debug
	
	vel += distanceVector * 0.16
	
	
	for obj in get_tree().get_nodes_in_group("boidAvoid"):
		var yep :Vector2= obj.global_position - global_position
		if yep.length() < 64:
			vel += yep * -1
	
	if vel.length() > player.velocity.length() + 120:
		vel = vel.normalized() * (player.velocity.length() + 120)
	
	if vel.length() < 400:
		vel = vel.normalized() * 400
	
	#if distanceVector.length() < 24:
	#	state = states.EXPLODE
	#	$ColorRect.show()
	
	return vel
