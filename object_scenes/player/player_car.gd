class_name PlayerCar
extends CharacterBody2D

@export_group("Stats")
@export var cameraReachLimit :int = 64.0
@export var maxSpeed :float = 380.0
@export var absoluteMaxSpeed :float = 850.0
@export var hopTimeAmount :float = 0.25 # time hop takes
@export var wheelMaxAngle :float = 0.3 # max radian angle that tires rotate to
@export var frictionMultiplier :float = 1.0
@export_group("Curves")
@export var turnStrengthCurve :Curve
@export var hopAnimationCurve :Curve
@export_group("Nodes")
@export var spriteStackContainer :Node2D
@export var otherContainer :Node2D
@export var camera :Camera2D
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

func _ready() -> void:
	# generate sprite sheet automatically
	var frameTotal :int = 20
	for i in range(frameTotal):
		var spr :Sprite2D = Sprite2D.new()
		spr.texture = load("res://object_scenes/player/sprites/greenSquare.png")
		spr.hframes = frameTotal
		spr.frame = i
		spriteStackContainer.add_child(spr)
	
	debugLineVelocity.visible = showDebugLines
	debugLineCarFacingDir.visible = showDebugLines
	dbeugLineWheelFacingDir.visible = showDebugLines

func _process(delta: float) -> void:
	processWheelDirection(delta)
	checkforHopInput()
	
	match state:
		0: # drive
			turnVehicle()
			applyAcceleration(delta)
			var dot :float = carDirection.normalized().dot(trueVelocity.normalized())
			if dot > tractionLimitDot or currentSpeed < 20:
				driveStateNormal(delta)
			else:
				driveStateDrift(delta,dot)
		1: # hopping
			hoppingState(delta)
	
	velocity = trueVelocity * Vector2(1.0,0.75) # apply velocity changes
	move_and_slide() # move and shit
	
	updateTireTrack()
	placeCamera()
	stackThemSprites()
	otherContainer.rotation = carDirection.angle()
	
	if showDebugLines:
		updateDebugLines()
	updateDebugLabels()

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
		currentSpeed = maxSpeed + driftboost
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
		if um < 0.2:
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
	driftboost += (6.0 * (1.0 - abs(dot))) * min(currentSpeed / maxSpeed,1.0)

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
	camera.position = get_local_mouse_position() * Vector2(1.0,0.75) * 0.1
	if camera.position.length() > cameraReachLimit:
		camera.position = camera.position.normalized() * cameraReachLimit
	camera.position.x = roundi(camera.position.x)
	camera.position.y = roundi(camera.position.y)

func stackThemSprites() -> void:
	var i :int = 0
	for child in spriteStackContainer.get_children():
		child.position.y = -i * 0.5
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
