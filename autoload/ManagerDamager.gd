extends Node

func getAllHitboxes() -> Array[Hitbox]:
	var grr := get_tree().get_nodes_in_group("hitbox")
	var poop :Array[Hitbox] = []
	for i in grr:
		if i is Hitbox:
			poop.append(i)
	return poop

func getHitboxOnLine(sourcePosition:Vector2,direction:Vector2,lineRange:float=500,lineWidth:float=0.0,sourceEntity:Node=null,hitmultiple:bool=false) -> Array[Hitbox]:
	var collidedHitboxes :Array[Hitbox] = []
	for hitbox in getAllHitboxes():
		if hitbox.parentObject == sourceEntity:
			continue # make sure entities don't attack themselves
		
		var response :float = Geometry2D.segment_intersects_circle(sourcePosition,sourcePosition + (direction.normalized()*lineRange),hitbox.global_position,hitbox.radius + lineWidth)
		if response > -0.1:
			collidedHitboxes.append(hitbox)
	
	if collidedHitboxes.size() <= 0:
		return collidedHitboxes
	
	if hitmultiple:
		return collidedHitboxes
	
	var findClosest :Hitbox = collidedHitboxes[0]
	for hitbox in collidedHitboxes:
		if hitbox.global_position.distance_to(sourcePosition) < findClosest.global_position.distance_to(sourcePosition):
			findClosest = hitbox
	
	return [findClosest]

func getHitboxInRadius(sourcePosition:Vector2,damageRadius:float,sourceEntity:Node=null) -> Array[Hitbox]:
	var collidedHitboxes :Array[Hitbox] = []
	for hitbox in getAllHitboxes():
		if hitbox.parentObject == sourceEntity:
			continue # make sure entities don't attack themselves
		
		if sourcePosition.distance_to(hitbox.global_position) < damageRadius + hitbox.radius:
			collidedHitboxes.append(hitbox)
	
	return collidedHitboxes
