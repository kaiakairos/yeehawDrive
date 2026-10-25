class_name ItemPickup
extends Node2D

## used by the dang donger to determine behavior when eaten by dylan
@export_enum("Health","EXP","Upgrade") var pickupType :int = 0

@export var amount :int = 1
@export var additionalID :String = ""

@export_category("Nodes")
@export var area :Area2D
@export var nodeToHeightAdjust :Node2D
@export var shadow :Sprite2D
@export var trailLine :Line2D

@export_category("Additional Animation")
@export var trailLineOffset :float = 0.0
@export var trailLength :int = 10


var vely :float = 0.0
var velocity :Vector2 = Vector2.ZERO

var state :int = 0

var tick :float = 0.0

func _ready() -> void:
	vely = -250.0
	shadow.z_index = -5
	area.monitoring = false
	area.collision_layer = 16
	area.collision_mask = 0

func _process(delta: float) -> void:
	match state:
		0:
			nodeToHeightAdjust.position.y += vely * delta
			
			
			vely += 700.0 * delta # add bouncing
			
			position += velocity * delta
			velocity = velocity.move_toward(Vector2.ZERO,delta*20.0)
			if nodeToHeightAdjust.position.y > 0.0:
				nodeToHeightAdjust.position.y = 0.0
				state = 1
			
			trailLine.global_position = Vector2.ZERO
			trailLine.add_point(nodeToHeightAdjust.global_position + Vector2(0,trailLineOffset))
			
			if trailLine.points.size() > trailLength:
				trailLine.remove_point(0)
			
		1: # yo
			tick += delta * 8.0
			nodeToHeightAdjust.position.y = sin( tick ) * 3.0
			
			if trailLine.points.size() > 0:
				trailLine.global_position = Vector2.ZERO
				trailLine.remove_point(0)
		2: # picked up
			
			velocity = GlobalReference.player.velocity
			velocity += (GlobalReference.player.global_position - global_position).normalized() * 50.0
			position += velocity * delta
			
			nodeToHeightAdjust.position.y += vely * delta
			vely += 1300.0 * delta # add bouncing
			nodeToHeightAdjust.position.y = min(nodeToHeightAdjust.position.y,0.0)
			
			trailLine.global_position = Vector2.ZERO
			trailLine.add_point(nodeToHeightAdjust.global_position + Vector2(0,trailLineOffset))
			
			
			if trailLine.points.size() > trailLength:
				trailLine.remove_point(0)
			
			if nodeToHeightAdjust.position.y > -0.5:
				state = 3
				giveReward()
			
		3: # preparing for awesome FUCKING deletion
			
			global_position = GlobalReference.player.global_position
			trailLine.global_position = Vector2.ZERO
			if trailLine.points.size() > 0:
				
				trailLine.remove_point(0)
			else:
				queue_free()
			
			nodeToHeightAdjust.hide()
			shadow.hide()
			
			
		
	shadow.scale = Vector2(0.03,0.03) * (32-(nodeToHeightAdjust.position.y * -1.0))
	if shadow.scale.x < 0.2:
		shadow.scale = Vector2(0.2,0.2)
	
	additionalProcess(delta)
	
func additionalProcess(delta:float) -> void:
	pass

func getPickedUp() -> void:
	state = 2
	vely = -300.0
	if GlobalReference.player.driftboost > 20.0:
		amount *= 2

func giveReward() -> void:
	match pickupType:
		0: # health
			GlobalReference.playerHealthComponent.heal(amount)
