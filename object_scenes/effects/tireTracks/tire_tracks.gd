extends Node2D

var reset:float = 0.0

func _process(delta: float) -> void:
	reset += delta
	modulate.a = 1.0 - reset
	if reset > 1.0:
		queue_free()

func addPoints(point1:Vector2,point2:Vector2,point3:Vector2,point4:Vector2) -> void:
	$Line2D.add_point(point1)
	$Line2D2.add_point(point2)
	$Line2D3.add_point(point3)
	$Line2D4.add_point(point4)
	reset = 0.0
