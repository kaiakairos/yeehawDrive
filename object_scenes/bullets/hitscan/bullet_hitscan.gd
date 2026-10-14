class_name BulletHitscan
extends Node2D

@export var raycast :RayCast2D

@export var line :Line2D

func _ready() -> void:
	var lineLength :int = 360
	raycast.force_raycast_update()
	var collider := raycast.get_collider()
	if is_instance_valid(collider):
		pass
	# play animation
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2( lineLength,0.0 ))
	raycast.enabled = false
	await get_tree().process_frame
	queue_free()
