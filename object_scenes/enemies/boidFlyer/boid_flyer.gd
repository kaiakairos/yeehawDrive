class_name BoidFlyer
extends Node2D

var velocity := Vector2.ZERO

enum states {NORMAL,DASH,DASHRECOVER,KNOCKBACK,DYING}
var state :int = 0

var spin :float = 0.0
var noise :FastNoiseLite = FastNoiseLite.new()

var offsetTargetAngle :float = 0.0

const DASHBOOST :float = 320.0
const AMOUNTOFTIMEDASHING :float = 0.5
var dashTimer :float = 0.0
const WAITTIMEFORFASH :float = 0.5
var waitForDash :float = 0.0

@export var heightSpriteOrigin :Node2D

@export var heightMax :float = 16.0

@export var heightSpeedMax :float = 1000.0

@export var normalHeightCurve :Curve
@export var dashHeightCurve :Curve

var heightIntoDashSave :float = 0.0
var dashRecoveryTimer :float = 0.0
var knockbackRecoveryTimer :float = 0.0
var hitPlayerInThisDash :bool = false

@export var damageFlashGradient :Gradient
var damageFlash :float = 2.0

func _ready() -> void:
	
	if randi() % 2 == 0:
		offsetTargetAngle = Vector2(0,1).rotated(randf_range(-0.02,0.02)).angle()
	else:
		offsetTargetAngle = Vector2(0,-1).rotated(randf_range(-0.02,0.02)).angle()
	
	add_to_group("boidAvoid")

func _process(delta: float) -> void:
	match state:
		states.NORMAL:
			velocity = stateNormal(velocity,delta)
			var sample :float = normalHeightCurve.sample( min(velocity.length() / heightSpeedMax,1.0) )
			var heightTarget :float = sample * heightMax * -1
			heightSpriteOrigin.position.y = lerp(heightSpriteOrigin.position.y,heightTarget,0.2)
		
		states.KNOCKBACK:
			var trueShit :Vector2 = stateNormal(velocity,delta)
			velocity = lerp(velocity,trueShit,0.4)
			var sample :float = normalHeightCurve.sample( min(velocity.length() / heightSpeedMax,1.0) )
			var heightTarget :float = sample * heightMax * -1
			heightSpriteOrigin.position.y = lerp(heightSpriteOrigin.position.y,heightTarget,0.2)
			
			knockbackRecoveryTimer -= delta
			if knockbackRecoveryTimer < 0.0:
				state = states.NORMAL
			
		states.DASH:
			dashTimer -= delta
			if dashTimer < 0.0:
				state = states.DASHRECOVER
				
				hitPlayerInThisDash = false
				dashRecoveryTimer = 0.5
			
			var sample :float = dashHeightCurve.sample( 1.0 - (dashTimer / AMOUNTOFTIMEDASHING) )
			var heightTarget :float = sample * heightIntoDashSave
			heightSpriteOrigin.position.y = heightTarget
			
			if !hitPlayerInThisDash:
				var response :Array[Hitbox] = ManagerDamager.getHitboxInRadius(global_position,4.0,self)
				for hitbox in response:
					if hitbox.parentObject == GlobalReference.player:
						
						hitbox.healthCompenent.dealDamage(5)
						hitPlayerInThisDash = true
		
		states.DASHRECOVER:
			
			var trueShit :Vector2 = stateNormal(velocity,delta)
			velocity = lerp(velocity,trueShit,0.2)
			var sample :float = normalHeightCurve.sample( min(velocity.length() / heightSpeedMax,1.0) )
			var heightTarget :float = sample * heightMax * -1
			heightSpriteOrigin.position.y = lerp(heightSpriteOrigin.position.y,heightTarget,0.2)
			
			
			dashRecoveryTimer -= delta
			if dashRecoveryTimer < 0.0:
				state = states.NORMAL
			
		
		states.DYING:
			velocity = stateNormal(velocity,delta)
	
	
	position += velocity * delta
	$HeightSpriteOrigin/Placeholder.rotate(0.07*delta*velocity.length())
	$HeightSpriteOrigin/Placeholder2.rotate(-0.08*delta*velocity.length())
	
	$Shadow2.scale.x = 2.0 - ((heightSpriteOrigin.position.y*-1) / heightMax)
	$Shadow2.scale.y =$Shadow2.scale.x
	
	$Line2D.add_point(global_position + heightSpriteOrigin.position + Vector2(0,-4))
	$Line2D.global_position = Vector2.ZERO
	if $Line2D.points.size() > 10:
		$Line2D.remove_point(0)
	
	$Line2D2.add_point(global_position)
	$Line2D2.global_position = Vector2.ZERO
	if $Line2D2.points.size() > 6:
		$Line2D2.remove_point(0)
	
	damageFlash += delta * 4.0
	modulate = damageFlashGradient.sample( damageFlash )

func stateNormal(vel:Vector2,delta:float) -> Vector2:
	
	var player :PlayerCar = GlobalReference.player
	var distanceVector :Vector2 = (player.predictFuturePosition(0.06) + Vector2(8,0).rotated(offsetTargetAngle).rotated(player.velocity.angle())) - global_position
	
	
	vel += distanceVector * 0.16
	
	for obj in get_tree().get_nodes_in_group("boidAvoid"):
		var yep :Vector2= obj.global_position - global_position
		if yep.length() < 64:
			vel += yep * -1
	
	if vel.length() > player.velocity.length() + 120:
		vel = vel.normalized() * (player.velocity.length() + 120)
	
	if vel.length() < 120:
		vel = vel.normalized() * 120
	
	
	if state == states.DASHRECOVER or state == states.KNOCKBACK:
		return vel #dont try to go for dash if we're still recovering
	
	if distanceVector.length() < 72:
		waitForDash += delta
	else:
		waitForDash -= delta * 0.15
		if waitForDash < 0.0:
			waitForDash = 0.0
		
	if waitForDash > WAITTIMEFORFASH:
		vel = player.velocity
		vel += (player.global_position-global_position).normalized() * DASHBOOST
		state = states.DASH
		dashTimer = AMOUNTOFTIMEDASHING
		waitForDash = 0.0
		
		heightIntoDashSave = heightSpriteOrigin.position.y
	
	return vel


func _on_health_component_took_damage(amount:int) -> void:
	damageFlash = 0.0


func _on_health_component_justgotkilled() -> void:
	queue_free()


func _on_health_component_took_knockback(amount: Vector2) -> void:
	velocity += amount
	knockbackRecoveryTimer = 0.3
	state = states.KNOCKBACK
