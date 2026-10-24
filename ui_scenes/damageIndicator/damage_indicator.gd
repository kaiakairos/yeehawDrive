class_name DamageIndicator
extends Node2D

@export var displayColor :Color
@export var displayNumber :int = 0

@export var numberCurve :Curve

@export var fontTex :Texture


var flashTimer :float = 0.0

var bigVelocity :Vector2 = Vector2.ZERO # used to follow car
var smallVelocity :Vector2 = Vector2.ZERO # used to make jump effect

var done :bool = false

func _ready() -> void:
	smallVelocity = Vector2(30,-250)
	if GlobalReference.player != null:
		bigVelocity = GlobalReference.player.velocity
	
	var stwing :String = str(displayNumber)
	var i :int = 0
	for letter in stwing:
		var spr :Sprite2D = Sprite2D.new()
		spr.texture = fontTex
		spr.hframes = 4
		spr.vframes = 3
		spr.frame = ["0","1","2","3","4","5","6","7","8","9","-","?"].find(letter)
		spr.modulate = displayColor
		add_child(spr)
		spr.position.x = i * 7
		
		i += 1
		
		var newTween :Tween = get_tree().create_tween()
		newTween.tween_method(tweenMethod.bind(spr),0.0,1.0,0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		await get_tree().create_timer(0.06).timeout
	await get_tree().create_timer(0.85).timeout
	done = true
	smallVelocity = Vector2.ZERO
	
func tweenMethod(sample:float,obj:Node) -> void:
	obj.position.y = numberCurve.sample(sample) * 4


func _process(delta: float) -> void:
	flashTimer += delta * 20.0
	
	if !done:
		modulate.a = 0.95 - (sin(flashTimer) * 0.2)
		smallVelocity.y += 500 * delta
	
	
	position += bigVelocity * delta
	position += smallVelocity * delta
	
	
	if done:
		bigVelocity = lerp(bigVelocity,Vector2.ZERO,0.1)
		modulate.a = lerp(modulate.a,0.0,0.1)
		skew = lerp(skew,PI/2,0.1)
		if modulate.a < 0.05:
			queue_free()
