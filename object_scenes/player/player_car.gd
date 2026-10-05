class_name PlayerCar
extends CharacterBody2D

@export var turnStrengthCurve :Curve

var wheelFacingAngle :float = 0.0 # -1.0, 0.0, 1.0 for left, center, right
var wheelMaxAngle :float = 0.3 # max radian angle that tires rotate to

var carDirection :Vector2 = Vector2.RIGHT

var currentSpeed :float = 0.0
var maxSpeed :float = 400.0
var absoluteMaxSpeed :float = 1000.0

var tractionLimitDot :float = 0.6

var state :int = 0 # 0 drive, 1 hopping

var hopTimer :float = 0.0

var drifting : bool = false
var driftboost :float = 0.0

var trueVelocity :Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	processWheelDirection(delta)
	
	
	
	
	if Input.is_action_just_pressed("hop") and state == 0:
		state = 1
		hopTimer = 0.0
		driftboost = 0.0
	
	print(driftboost)
	
	match state:
		0: # drive
			turnVehicle()
			if Input.is_action_pressed("accelerate"):
				currentSpeed = min(currentSpeed,absoluteMaxSpeed)
				if currentSpeed < maxSpeed:
					currentSpeed = move_toward(currentSpeed,maxSpeed,delta*800.0)
				else:
					currentSpeed = move_toward(currentSpeed,maxSpeed,delta*10.0)
			elif Input.is_action_pressed("brake"):
				currentSpeed = move_toward(currentSpeed,0.0,delta*800.0)
			else:
				currentSpeed = move_toward(currentSpeed,0.0,delta*100.0)
			
			var dot :float = carDirection.normalized().dot(trueVelocity.normalized())
			#print(dot)
			if dot > tractionLimitDot:
				trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*1800.0)
				$SpriteGroup/rotationOrigin/ColorRect.color = Color.WHITE
				if drifting:
					currentSpeed += driftboost
					trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*1200.0)
				drifting = false
				driftboost = 0.0
			else:
				if Input.is_action_pressed("hop"):
					trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*600.0)
					trueVelocity += trueVelocity * 0.005 * (1.0 - abs(dot))
				else:
					trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*2500.0)
				$SpriteGroup/rotationOrigin/ColorRect.color = Color.RED
				drifting = true
				driftboost += (8.0 * (1.0 - abs(dot))) * min(currentSpeed / maxSpeed,1.0)
		1: # hopping
			carDirection = carDirection.rotated( wheelFacingAngle * delta * 8.0 )
			$SpriteGroup/rotationOrigin/ColorRect.color = Color.YELLOW
			hopTimer += delta
			if hopTimer > 0.25:
				state = 0
	
	
	velocity = trueVelocity * Vector2(1.0,0.75)
	move_and_slide()
	
	placeCamera()
	$SpriteGroup/rotationOrigin.rotation = carDirection.angle()
	
	updateDebugLines()
	updateDebugLabels()


func processWheelDirection(delta:float) -> void:
	var wheelTarget :float = 0.0
	if Input.is_action_pressed("turnLeft"):
		wheelTarget -= 1.0
	if Input.is_action_pressed("turnRight"):
		wheelTarget += 1.0
	wheelFacingAngle = move_toward(wheelFacingAngle,wheelTarget,delta*6.0)
	#print(wheelFacingAngle)

func turnVehicle(multiplier:float = 1.0) -> void:
	carDirection = Vector2.from_angle( 
		lerp_angle(carDirection.angle(),
		carDirection.rotated( wheelFacingAngle * wheelMaxAngle ).angle(),
		turnStrengthCurve.sample(currentSpeed/maxSpeed)) * multiplier) 

func updateDebugLines() -> void:
	$SpriteGroup/wheelMotion.clear_points()
	$SpriteGroup/wheelMotion.add_point(Vector2.ZERO)
	$SpriteGroup/wheelMotion.add_point(carDirection.rotated(wheelMaxAngle * wheelFacingAngle).normalized()  * 32)
	
	$SpriteGroup/carFacing.clear_points()
	$SpriteGroup/carFacing.add_point(Vector2.ZERO)
	$SpriteGroup/carFacing.add_point(carDirection.normalized()  * 24)
	
	$SpriteGroup/actualVel.clear_points()
	$SpriteGroup/actualVel.add_point(Vector2.ZERO)
	$SpriteGroup/actualVel.add_point(trueVelocity * 0.2)

func updateDebugLabels() -> void:
	$Camera2D/speed.text = "set speed: " + str(int(currentSpeed))
	if driftboost != 0:
		$Camera2D/dash.text = "drift boost: " + str(int(driftboost))

func placeCamera() -> void:
	$Camera2D.position = get_local_mouse_position() * Vector2(1.0,0.75) * 0.1
	if $Camera2D.position.length() > 48:
		$Camera2D.position = $Camera2D.position.normalized() * 48
