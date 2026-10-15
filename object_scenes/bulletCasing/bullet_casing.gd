class_name BulletCasing
extends Node2D

@export var sprite :Sprite2D
@export var shadow :Sprite2D

var velocity :Vector2

var verticalVel :float = -120.0

var bouncing :bool = true


var deleteTick :float = 0.0

func _ready() -> void:
	sprite.frame = randi() % sprite.hframes
	sprite.position.y = -8.0


func _process(delta: float) -> void:
	
	if !bouncing:
		deleteTick += delta
		if deleteTick > 0.25:
			modulate.a = 1.0 - modulate.a
		if deleteTick > 0.5:
			queue_free()
		return
	
	position += velocity * delta
	sprite.position.y += verticalVel * delta
	if sprite.position.y > 0.0:
		sprite.position.y *= -1
		verticalVel *= -0.75
		
		sprite.frame = (sprite.frame + 1) % sprite.hframes
		
		velocity *= 0.5
		
		if abs(verticalVel) < 80.0:
			sprite.position.y = 0.0
			bouncing = false
		
	
	
	shadow.scale = Vector2(0.02,0.02) * (32-(sprite.position.y * -1.0))
	if shadow.scale.x < 0.01:
		shadow.scale = Vector2(0.01,0.01)
	
	verticalVel += 500.0 * delta
