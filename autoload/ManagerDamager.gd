extends Node

func getAllHitboxes() -> Array[Hitbox]:
	var grr := get_tree().get_nodes_in_group("hitbox")
	var poop :Array[Hitbox] = []
	for i in grr:
		if i is Hitbox:
			poop.append(i)
	return poop


func attackLineScan(damageAmount:int,sourcePosition:Vector2,direction:Vector2,lineRange:int=500,sourceEntity:Node=null,hitmultiple:bool=false) -> Array[Hitbox]:
	var collidedHitboxes :Array[Hitbox] = []
	for hitbox in getAllHitboxes():
		if hitbox.parentObject == sourceEntity:
			continue # make sure entities don't attack themselves
		
		var response :float = Geometry2D.segment_intersects_circle(sourcePosition,sourcePosition + (direction.normalized()*lineRange),hitbox.global_position,hitbox.radius)
		if response > -0.1:
			collidedHitboxes.append(hitbox)
	
	if collidedHitboxes.size() <= 0:
		return collidedHitboxes
	
	if hitmultiple:
		for hitbox in collidedHitboxes:
			hitbox.healthCompenent.dealDamage(damageAmount)
		return collidedHitboxes
	
	
	var findClosest :Hitbox = collidedHitboxes[0]
	for hitbox in collidedHitboxes:
		if hitbox.global_position.distance_to(sourcePosition) < findClosest.global_position.distance_to(sourcePosition):
			findClosest = hitbox
	
	findClosest.healthCompenent.dealDamage(damageAmount)
	return [findClosest]

func attackRadius(damageAmount:int,sourcePosition:Vector2,damageRadius:float,sourceEntity:Node=null) -> Array[Hitbox]:
	var collidedHitboxes :Array[Hitbox] = []
	for hitbox in getAllHitboxes():
		if hitbox.parentObject == sourceEntity:
			continue # make sure entities don't attack themselves
		
		if sourcePosition.distance_to(hitbox.global_position) < damageRadius + hitbox.radius:
			collidedHitboxes.append(hitbox)
	
	
	for hitbox in collidedHitboxes:
		hitbox.healthCompenent.dealDamage(damageAmount)
	
	return collidedHitboxes
