extends CanvasGroup

@export var playerCar :PlayerCar

@export var driftFlashColor :Gradient

@export var wallRightContainer :Node2D
@export var wallLeftContainer :Node2D

@export var rightWall1 :WallPolygon # colored one
@export var rightWall2 :WallPolygon

@export var leftWall1 :WallPolygon # colored one
@export var leftWall2 :WallPolygon

func coolDriftEffect() -> void:
	
	rightWall1.visible = playerCar.drifting
	rightWall2.visible = playerCar.drifting
	leftWall1.visible = playerCar.drifting
	leftWall2.visible = playerCar.drifting
	
	if playerCar.drifting:
		
		rightWall1.color = driftFlashColor.sample( playerCar.driftboost / 900.0 )
		leftWall1.color = rightWall1.color
		
		wallRightContainer.rotation = playerCar.carDirection.angle()
		wallLeftContainer.rotation = playerCar.carDirection.angle()
		if playerCar.otherContainer.rotation != clamp(playerCar.otherContainer.rotation,-PI/2,PI/2):
			move_child(wallRightContainer,1)
			move_child(wallLeftContainer,7)
			
		else:
			move_child(wallRightContainer,7)
			move_child(wallLeftContainer,1)
		
		var dot1 :float= playerCar.carDirection.normalized().dot( playerCar.velocity.normalized() )
		
		rightWall1.scale = Vector2(1.0,1.0) * (1.0 - abs(dot1))
		rightWall2.scale = Vector2(1.0,1.0) * (1.0 - abs(dot1))
		leftWall1.scale = Vector2(1.0,1.0) * (1.0 - abs(dot1))
		leftWall2.scale = Vector2(1.0,1.0) * (1.0 - abs(dot1))
		
		
		var playerSpeed :float = playerCar.velocity.length()
		var heightMultiplier :float = clamp(playerSpeed / 600.0,0.0,1.0)
			
		var dot2 :float= playerCar.carDirection.normalized().dot( playerCar.velocity.normalized().rotated(PI/2) )
		if dot2 < 0:
			rightWall1.topAdditive = Vector2(0,8) * heightMultiplier
			rightWall2.topAdditive = Vector2(0,8) * heightMultiplier
			
			leftWall1.topAdditive = Vector2(0,-4) * heightMultiplier
			leftWall2.topAdditive = Vector2(0,0) * heightMultiplier
			
			rightWall1.wallHeight = 24.0 * heightMultiplier
			rightWall2.wallHeight = 16.0 * heightMultiplier
			
			leftWall1.wallHeight = 0.0
			leftWall2.wallHeight = 0.0
			
			rightWall1.width = 20.0 
			leftWall1.width = 15.0
			
		else:
			leftWall1.topAdditive = Vector2(0,-8)  * heightMultiplier
			leftWall2.topAdditive = Vector2(0,-8) * heightMultiplier
			
			rightWall1.topAdditive = Vector2(0,4)  * heightMultiplier
			rightWall2.topAdditive = Vector2(0,0) * heightMultiplier
			
			leftWall1.wallHeight = 24.0 * heightMultiplier
			leftWall2.wallHeight = 16.0 * heightMultiplier
			
			rightWall1.wallHeight = 0.0
			rightWall2.wallHeight = 0.0
			
			rightWall1.width = 15.0
			leftWall1.width = 20.0
	
		rightWall1.drawPolygon()
		rightWall2.drawPolygon()
		leftWall1.drawPolygon()
		leftWall2.drawPolygon()
	
	$driftParticles.emitting = playerCar.drifting or playerCar.currentSpeed > 840
	
