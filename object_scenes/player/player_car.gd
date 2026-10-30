class_name PlayerCar
extends CharacterBody2D

@export_group("Stats")
@export var cameraReachLimit :int = 80.0
@export var maxSpeed :float = 400.0
@export var absoluteMaxSpeed :float = 1000.0
@export var hopTimeAmount :float = 0.25 # time hop takes
@export var wheelMaxAngle :float = 0.3 # max radian angle that tires rotate to
@export var frictionMultiplier :float = 1.0
@export_group("Curves")
@export var turnStrengthCurve :Curve
@export var hopAnimationCurve :Curve
@export_group("Nodes")
@export var spriteStackContainer :Node2D
@export var wheelStackContainer :Node2D
@export var otherContainer :Node2D
@export var camera :Camera2D
@export_subgroup("Scripts")
@export var gunHandler :PlayerGunHandler
@export_subgroup("Effects")
@export var shadow :Sprite2D
@export_subgroup("Debug Lines")
@export var showDebugLines :bool = true
@export var debugLineVelocity :Line2D
@export var debugLineCarFacingDir :Line2D
@export var dbeugLineWheelFacingDir :Line2D
@export_subgroup("Debug Text")
@export var label1 :Label
@export var label2 :Label
@export_subgroup("TireTraceMarkers")
@export var tireMarker1 :Marker2D
@export var tireMarker2 :Marker2D
@export var tireMarker3 :Marker2D
@export var tireMarker4 :Marker2D

var wheelFacingAngle :float = 0.0 # -1.0, 0.0, 1.0 for left, center, right

var carDirection :Vector2 = Vector2.RIGHT

var currentSpeed :float = 0.0

var tractionLimitDot :float = 0.7
var state :int = 0 # 0 drive, 1 hopping

var hopTimer :float = 0.0

var drifting : bool = false
var driftboost :float = 0.0

var trueVelocity :Vector2 = Vector2.ZERO
var driftVelLengthSave :float = 0.0

var assignedTireTrack :Node2D = null

var lostControlTick :float = 0.0
var carForceRotate:float = 0.0


var engineNoise :FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	
	GlobalReference.player = self
	add_to_group("boidAvoid")
	
	
	# generate sprite sheet automatically
	var frameTotal :int = 15
	for i in range(frameTotal):
		for layerUp in range(2):
			var spr :Sprite2D = Sprite2D.new()
			spr.texture = load("res://object_scenes/player/sprites/greenSquare.png")
			spr.hframes = frameTotal
			spr.vframes = 3
			spr.frame_coords.x = frameTotal - i - 1
			spriteStackContainer.add_child(spr)
	
	var wheelFrameTotal :int = 5
	for i in range(wheelFrameTotal):
		for layerUp in range(2):
			var spr :Sprite2D = Sprite2D.new()
			spr.texture = load("res://object_scenes/player/sprites/wheelStack.png")
			spr.hframes = wheelFrameTotal
			spr.vframes = 3
			spr.frame_coords.x = wheelFrameTotal - i - 1
			wheelStackContainer.add_child(spr)
	
	debugLineVelocity.visible = showDebugLines
	debugLineCarFacingDir.visible = showDebugLines
	dbeugLineWheelFacingDir.visible = showDebugLines

func _process(delta: float) -> void:
	processWheelDirection(delta)
	checkforHopInput()
	$ProgressBars/simpleProgressBar.visible = drifting and state == 0 and driftboost > 10
	match state:
		0: # drive
			turnVehicle()
			applyAcceleration(delta)
			var dot :float = carDirection.normalized().dot(trueVelocity.normalized())
			if dot > tractionLimitDot or currentSpeed < 20:
				driveStateNormal(delta)
				if currentSpeed > 850:
					gunHandler.setBulletMode(1)
				else:
					gunHandler.setBulletMode(0)
				
			else:
				driveStateDrift(delta,dot)
				if driftboost > 900:
					gunHandler.setBulletMode(2)
				elif driftboost > 250:
					gunHandler.setBulletMode(1)
				
				$ProgressBars/simpleProgressBar.updateValue(driftboost)
				#$ProgressBars/simpleProgressBar/ColorRect2.position.y = 11.0 + ((1.0-abs(dot)) * -10.0)
				
		1: # hopping
			hoppingState(delta)
		2: # lost control
			carForceRotate = 16.0
			drifting = true
			if !is_instance_valid(assignedTireTrack):
				createNewTireTrack()
			else:
				updateTireTrack()
			
			lostControlTick -= delta
			if lostControlTick <= 0.0 and carDirection.normalized().dot(velocity.normalized()) > 0.2:
				state = 0
				assignedTireTrack = null
			elif lostControlTick <= 0.0 and velocity.length() < 20:
				state = 0
				assignedTireTrack = null
	
	
	carDirection = carDirection.rotated(carForceRotate*delta)
	carForceRotate = move_toward(carForceRotate,0.0,delta*50.0)
	
	
	velocity = trueVelocity * Vector2(1.0,0.75) # apply velocity changes
	move_and_slide() # move and shit
	
	updateTireTrack()
	placeCamera()
	stackThemSprites()
	otherContainer.rotation = carDirection.angle()
	
	if showDebugLines:
		updateDebugLines()
	updateDebugLabels()
	
	antennaAnimation()
	
	if Input.is_action_just_pressed("testKey"):
		$SubViewport.playAnimWindshieldWiper()
	
	$ProgressBars/healthbar.modulate.a = move_toward($ProgressBars/healthbar.modulate.a,0.0,delta*4.0)
	
	
	if !drifting:
		$Sounds/Drift.volume_linear = lerp($Sounds/Drift.volume_linear,0.0,0.4)
	else:
		var target :float = velocity.length() / 5200.0
		
		target = clamp(target,0.0,0.1)
		print(target)
		$Sounds/Drift.pitch_scale = 0.88 - (target*2.0)
		$Sounds/Drift.volume_linear = lerp($Sounds/Drift.volume_linear,target,0.25) 
	
	$Sounds/Engine.volume_linear = clamp(currentSpeed/400.0,0.2,0.8)
	$Sounds/Engine.pitch_scale = clamp(currentSpeed / maxSpeed,0.52,0.9) + 0.1 + ((engineNoise.get_noise_1d(Time.get_ticks_msec()*0.1*currentSpeed/400.0))*0.1)
	
	if Input.is_action_just_pressed("accelerate") and currentSpeed < maxSpeed:
		match randi() % 3:
			0: 
				$Sounds/EngineBoost1.volume_linear = (maxSpeed - currentSpeed ) / maxSpeed
				$Sounds/EngineBoost1.play()
			1: 
				$Sounds/EngineBoost2.volume_linear = (maxSpeed - currentSpeed )/ maxSpeed
				$Sounds/EngineBoost2.play()
			2: 
				$Sounds/EngineBoost3.volume_linear = (maxSpeed - currentSpeed )/ maxSpeed
				$Sounds/EngineBoost3.play()

func applyAcceleration(delta:float) -> void:
	var target :float = 0.0
	var rate :float = 0.0
	if Input.is_action_pressed("accelerate"):
		target = maxSpeed
		rate = 60.0 + (740.0 * int(currentSpeed < maxSpeed))
	else:
		rate = 100.0 + (700.0 * int(Input.is_action_pressed("brake")))
	
	currentSpeed = move_toward(currentSpeed,target,delta*rate)
	currentSpeed = min(currentSpeed,absoluteMaxSpeed) # cap speed

func driveStateNormal(delta:float) -> void:
	trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*1800.0*frictionMultiplier)
	spriteStackContainer.modulate = Color.WHITE
	if drifting and Input.is_action_pressed("accelerate"):
		currentSpeed = currentSpeed + driftboost
		trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*1200.0*frictionMultiplier)
	drifting = false
	driftboost = 0.0

func driveStateDrift(delta:float,dot:float) -> void:
	## IS DRIFTING
	if Input.is_action_pressed("hop"):
		if Input.is_action_pressed("accelerate"):
			trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*1600.0*frictionMultiplier)
		else:
			driftVelLengthSave = move_toward(driftVelLengthSave,0.0,delta*400.0*frictionMultiplier)
		trueVelocity = trueVelocity.normalized() * driftVelLengthSave
		var um :float = abs(dot)
		if um < 0.7:
			um = 0.0
		driftVelLengthSave = move_toward(driftVelLengthSave,0.0,delta*900.0 * um*frictionMultiplier)
		if trueVelocity.length() <= 0.0001:
			if Input.is_action_pressed("accelerate"):
				printerr("Safety Stillness Protocal activated")
				trueVelocity = carDirection.normalized()
			else:
				currentSpeed = 0
				drifting = false
	else:
		trueVelocity = trueVelocity.move_toward(carDirection.normalized() * currentSpeed,delta*2000.0*frictionMultiplier)
		driftVelLengthSave = trueVelocity.length()
	#spriteStackContainer.modulate = Color.RED
	if !drifting:
			createNewTireTrack()
	drifting = true
	driftboost += (4.2 * (0.8 - abs(dot))) * min(currentSpeed / maxSpeed,1.0)

func checkforHopInput() -> void: # Check to see if we've jumped and apply state change
	if state != 0 or drifting:
		return
	if Input.is_action_just_pressed("hop"): 
		state = 1
		hopTimer = 0.0
		driftboost = 0.0

func hoppingState(delta:float) -> void: # hopping behavior
	carDirection = carDirection.rotated( wheelFacingAngle * delta * 8.0 )
	#spriteStackContainer.modulate = Color.YELLOW
	hopTimer += delta
	if hopTimer > hopTimeAmount:
		state = 0
		driftVelLengthSave = trueVelocity.length()
	var hopSample :float = hopAnimationCurve.sample( hopTimer/hopTimeAmount)
	spriteStackContainer.position.y = hopSample * -8.0
	wheelStackContainer.position.y = spriteStackContainer.position.y
	var erm :float = 1.0 - (hopSample*0.25)
	shadow.scale = Vector2(erm,erm)

func processWheelDirection(delta:float) -> void:
	var wheelTarget :float = 0.0
	if Input.is_action_pressed("turnLeft"):
		wheelTarget -= 1.0
	if Input.is_action_pressed("turnRight"):
		wheelTarget += 1.0
	wheelFacingAngle = move_toward(wheelFacingAngle,wheelTarget,delta*6.0)

func turnVehicle(multiplier:float = 1.0) -> void:
	carDirection = Vector2.from_angle( 
		lerp_angle(carDirection.angle(),
		carDirection.rotated( wheelFacingAngle * wheelMaxAngle ).angle(),
		turnStrengthCurve.sample(currentSpeed/maxSpeed)) * multiplier) 

func updateDebugLines() -> void:
	dbeugLineWheelFacingDir.clear_points()
	dbeugLineWheelFacingDir.add_point(Vector2.ZERO)
	dbeugLineWheelFacingDir.add_point(carDirection.rotated(wheelMaxAngle * wheelFacingAngle).normalized()  * 32)
	
	debugLineCarFacingDir.clear_points()
	debugLineCarFacingDir.add_point(Vector2.ZERO)
	debugLineCarFacingDir.add_point(carDirection.normalized()  * 24)
	
	debugLineVelocity.clear_points()
	debugLineVelocity.add_point(Vector2.ZERO)
	debugLineVelocity.add_point(trueVelocity * 0.2)

func updateDebugLabels() -> void:
	label1.text = "set speed: " + str(int(currentSpeed))
	if driftboost != 0:
		label2.text = "drift boost: " + str(int(driftboost))

func placeCamera() -> void:
	camera.position = get_local_mouse_position() * Vector2(1.0,0.75) * 0.5
	if camera.position.length() > cameraReachLimit:
		camera.position = camera.position.normalized() * cameraReachLimit
	camera.position.x = roundi(camera.position.x)
	camera.position.y = roundi(camera.position.y)

func stackThemSprites() -> void:
	var i :int = 0
	for child in spriteStackContainer.get_children():
		
		child.frame_coords.y = 0
		if velocity.length() > 200.0:
			if Input.is_action_pressed("turnLeft"):
				child.frame_coords.y = 1
			if Input.is_action_pressed("turnRight"):
				child.frame_coords.y = 2
		
		child.position.y = -i * 0.4
		child.rotation =  carDirection.angle()
		i += 1
	
	i=0
	for child in wheelStackContainer.get_children():
		child.frame_coords.y = 0
		if Input.is_action_pressed("turnLeft"):
			child.frame_coords.y = 1
		if Input.is_action_pressed("turnRight"):
			child.frame_coords.y = 2
		child.position.y = -i * 0.4
		child.rotation =  carDirection.angle()
		i += 1

func createNewTireTrack() -> void:
	var obj :Node2D = load("res://object_scenes/effects/tireTracks/tire_tracks.tscn").instantiate()
	get_parent().add_child(obj)
	assignedTireTrack = obj

func updateTireTrack() -> void: # updates tire tracks
	if !drifting or !is_instance_valid(assignedTireTrack):
		return
	assignedTireTrack.addPoints(tireMarker1.global_position,tireMarker2.global_position,
	tireMarker3.global_position,tireMarker4.global_position)

func predictFuturePosition(time:float) -> Vector2:
	return global_position + (time * velocity)
	
func antennaAnimation() -> void:
	$SpriteGroup/otherContainer/antenna.position = Vector2(-13,-6.66) + spriteStackContainer.position.rotated(-otherContainer.rotation)
	$SpriteGroup/otherContainer/antenna.rotation = -otherContainer.rotation
	$SpriteGroup/otherContainer/antenna.clear_points()
	$SpriteGroup/otherContainer/antenna.add_point(Vector2(0,-6))
	$SpriteGroup/otherContainer/antenna.add_point(Vector2(0,-10) + (velocity * -0.005))
	$SpriteGroup/otherContainer/antenna.add_point(Vector2(0,-13) + (velocity * -0.012))
	#$SpriteGroup/otherContainer/antenna/emblem.position = Vector2(0,-13) + (velocity * -0.012)
	#$SpriteGroup/otherContainer/antenna/emblem.rotation = $SpriteGroup/otherContainer/antenna.get_point_position(1).angle_to($SpriteGroup/otherContainer/antenna.get_point_position(2))


func _on_health_component_health_updated(health: int, maxHealth: int) -> void:
	$ProgressBars/healthbar.modulate.a = 10.0
