extends Node2D

@export var playerCar :PlayerCar
@export var line1 :Line2D
@export var line2 :Line2D
@export var frontLine :Line2D

var randomization :float = 2.0
@export var addition :Vector2 = Vector2.ZERO

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var POOPASS :float = playerCar.velocity.normalized().dot( playerCar.carDirection.normalized() )
	if playerCar.currentSpeed > 700 and !playerCar.drifting and playerCar.state == 0 and POOPASS > 0.9:
	
		line1.global_position = addition
		line1.add_point(global_position + (Vector2(16,-8).rotated( playerCar.carDirection.angle() ) * Vector2(1.0,0.75) ))
		if line1.points.size() > 10:
			line1.remove_point(0)
			
		line2.global_position = addition
		line2.add_point(global_position + (Vector2(16,8).rotated( playerCar.carDirection.angle() ) * Vector2(1.0,0.75) ))
		if line2.points.size() > 10:
			line2.remove_point(0)
		
		for i in range(line1.points.size()):
			line1.set_point_position(i, line1.get_point_position(i) + Vector2(randf_range(-randomization,randomization),randf_range(-randomization,randomization)) )
		for i in range(line2.points.size()):
			line2.set_point_position(i, line2.get_point_position(i) + Vector2(randf_range(-randomization,randomization),randf_range(-randomization,randomization)) )
		
		
		frontLine.global_position = addition
		frontLine.clear_points()
		for i in range(5):
			frontLine.add_point( global_position + Vector2(16,(4.0 * i)-8.0).rotated(playerCar.carDirection.angle()) * Vector2(1.0,0.75) )
		for i in range(frontLine.points.size()):
			#if i == 0:
			#	frontLine.set_point_position(i,line1.get_point_position(line1.get_point_count()-1))
			#elif i == frontLine.points.size() - 1:
			#	frontLine.set_point_position(i,line2.get_point_position(line2.get_point_count()-1))
			if i != 0 and i != frontLine.points.size() - 1:
				frontLine.set_point_position(i,frontLine.get_point_position(i) + Vector2(randf_range(-randomization,randomization),randf_range(-randomization,randomization)) )
		
		randomization = lerp(randomization,1.0,0.1)
		
	else:
		
		
		randomization = 16.0
		
		line1.global_position = Vector2.ZERO
		line2.global_position = Vector2.ZERO
		
		if line1.points.size() > 0:
			line1.remove_point(0)
		if line2.points.size() > 0:
			line2.remove_point(0)
		
		if frontLine.points.size() > 0:
			frontLine.remove_point(0)
	
	var dot :float = playerCar.carDirection.normalized().dot( Vector2.RIGHT )
	line1.z_index = int(dot < 0) - 2
	line2.z_index = int(dot > 0) - 2
	
	var otherDot :float = playerCar.carDirection.normalized().dot( Vector2.DOWN )
	
	frontLine.z_index = int(otherDot > 0) - 2
	
