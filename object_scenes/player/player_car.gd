class_name PlayerCar
extends CharacterBody2D

@export var turnStrengthCurve :Curve

var wheelFacingAngle :float = 0.0 # -1.0, 0.0, 1.0 for left, center, right
var wheelMaxAngle :float = 0.3 # max radian angle that tires rotate to

var carDirection :Vector2 = Vector2.RIGHT

var currentSpeed :float = 0.0
var maxSpeed :float = 380.0
var absoluteMaxSpeed :float = 700.0

var tractionLimitDot :float = 0.7
var state :int = 0 # 0 drive, 1 hopping

@export var hopAnimationCurve :Curve
var hopTimer :float = 0.0
const hopTimeAmount :float = 0.25

var drifting : bool = false
var driftboost :float = 0.0

var trueVelocity :Vector2 = Vector2.ZERO
var driftVelLengthSave :float = 0.0

var assignedTireTrack :Node2D = null

func _ready() -> void:
	# generate sprite sheet automatically
	var frameTotal :int = 20
	for i in range(frameTotal):
		var spr :Sprite2D = Sprite2D.new()
		spr.texture = load("res://object_scenes/player/sprites/greenSquare.png")
		spr.hframes = frameTotal
		spr.frame = i
		$SpriteGroup/rotationOrigin.add_child(spr)

func _process(delta: float) -> void:
	processWheelDirection(delta)
	if Input.is_action_just_pressed("hop") and state == 0 and !drifting:
		state = 1
		hopTimer = 0.0
		driftboost = 0.0
	
	#print(driftboost)
	
	match state:
		0: # drive
			turnVehicle()
			if Input.is_action_pressed("accelerate"):
				currentSpeed = min(currentSpeed,absoluteMaxSpeed)
				if currentSpeed < maxSpeed:
					currentSpeed = move_toward(currentSpeed,maxSpeed,delta*800.0)
				else:
					currentSpeed = move_toward(currentSpeed,maxSpeed,delta*60.0)
			elif Input.is_action_pressed("brake"):
				currentSpeed = move_toward(currentSpeed,0.0,delta*800.0)
			else:
				currentSpeed = move_toward(currentSpeed,0.0,delta*100.0)
			
			var dot :float = carDirection.normalized().dot(trueVelocity.normalized())
			var dotReversed :float = 1.0 - abs(dot) # = 1.0 if drift perpendicular, 0.0 if parallel
			if dot > tractionLimitDot or currentSpeed < 20:
				trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*1800.0)
				$SpriteGroup/rotationOrigin.modulate = Color.WHITE
				if drifting:
					currentSpeed = currentSpeed + driftboost
					trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*1200.0)
				drifting = false
				driftboost = 0.0
			else:
				
				if Input.is_action_pressed("hop"):
					if Input.is_action_pressed("accelerate"):
						trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*900.0)
					else:
						driftVelLengthSave = move_toward(driftVelLengthSave,0.0,delta*400.0)
					trueVelocity = trueVelocity.normalized() * driftVelLengthSave
					var um :float = abs(dot)
					if um < 0.2:
						um = 0.0
					driftVelLengthSave = move_toward(driftVelLengthSave,0.0,delta*900.0 * um)
					if trueVelocity.length() <= 0.0001:
						printerr("Safety Stillness Protocal activated")
						trueVelocity = carDirection.normalized()
				else:
					trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*800.0)
					driftVelLengthSave = trueVelocity.length()
				$SpriteGroup/rotationOrigin.modulate = Color.RED
				if !drifting:
					createNewTireTrack()
				drifting = true
				
				
				driftboost += (6.0 * dotReversed) * min(currentSpeed / maxSpeed,1.0)
		1: # hopping
			carDirection = carDirection.rotated( wheelFacingAngle * delta * 8.0 )
			$SpriteGroup/rotationOrigin.modulate = Color.YELLOW
			hopTimer += delta
			if hopTimer > hopTimeAmount:
				state = 0
				driftVelLengthSave = trueVelocity.length()
			var hopSample :float = hopAnimationCurve.sample( hopTimer/hopTimeAmount)
			$SpriteGroup/rotationOrigin.position.y = hopSample * -8.0
			var erm :float = 1.0 - (hopSample*0.25)
			$SpriteGroup/otherRotate/Shadow.scale = Vector2(erm,erm)
	
	#print(trueVelocity)
	velocity = trueVelocity * Vector2(1.0,0.75)
	move_and_slide()
	
	
	if drifting:
		if is_instance_valid(assignedTireTrack):
					assignedTireTrack.addPoints($SpriteGroup/otherRotate/Marker2D.global_position,
					$SpriteGroup/otherRotate/Marker2D2.global_position,
					$SpriteGroup/otherRotate/Marker2D3.global_position,
					$SpriteGroup/otherRotate/Marker2D4.global_position)
	
	placeCamera()
	
	stackThemSprites()
	
	$SpriteGroup/otherRotate.rotation = carDirection.angle()
	
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
	$Camera2D.position.x = roundi($Camera2D.position.x)
	$Camera2D.position.y = roundi($Camera2D.position.y)

func stackThemSprites() -> void:
	var i :int = 0
	for child in $SpriteGroup/rotationOrigin.get_children():
		child.position.y = -i * 0.5
		child.rotation =  carDirection.angle()
		i += 1

func createNewTireTrack() -> void:
	var obj :Node2D = load("res://object_scenes/effects/tireTracks/tire_tracks.tscn").instantiate()
	get_parent().add_child(obj)
	assignedTireTrack = obj
