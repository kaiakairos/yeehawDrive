extends Polygon2D

@export var width :float = 16.0
@export var wallHeight :float = 16.0

@export var topAdditive: Vector2 = Vector2.ZERO

var saveRotation :float = -5.0


func _ready() -> void:
	
	var imageSize :Vector2= texture.get_size()
	
	var uvPoly :PackedVector2Array = PackedVector2Array()
	
	uvPoly.append(imageSize)
	uvPoly.append(Vector2(0.0, imageSize.y))
	uvPoly.append(Vector2.ZERO)
	uvPoly.append(Vector2(imageSize.x,0))
	
	
	uv = uvPoly
	
func _process(delta: float) -> void:

	if saveRotation != global_rotation:
		
		drawPolygon()
		
		saveRotation = global_rotation

func drawPolygon() -> void:
	var newPoly :PackedVector2Array = PackedVector2Array()
	newPoly.append(Vector2(-width,0))
	newPoly.append(Vector2(width,0))
	
	newPoly.append(Vector2(width,0) + Vector2(0,-wallHeight).rotated(-global_rotation) + topAdditive)
	newPoly.append(Vector2(-width,0) + Vector2(0,-wallHeight).rotated(-global_rotation) + topAdditive)
	
	polygon = newPoly
