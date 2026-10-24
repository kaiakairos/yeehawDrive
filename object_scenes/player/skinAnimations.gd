extends SubViewport

@export var parent :PlayerCar

func _process(delta: float) -> void:
	$brakeLight.visible = Input.is_action_pressed("brake") or Input.is_action_pressed("hop")
	
	$wheels/wheel1.rotate(parent.velocity.length() * delta * -0.06)
	$wheels/wheel2.rotate(parent.velocity.length() * delta * -0.06)
	
	$wheels/wheel3.rotate(parent.velocity.length() * delta * 0.06)
	$wheels/wheel4.rotate(parent.velocity.length() * delta * 0.06)

var playingWindshieldWiper :bool = false
func playAnimWindshieldWiper() -> void:
	if playingWindshieldWiper:
		return
	

	
	playingWindshieldWiper = true
	for i in range(3):
		var tween :Tween= get_tree().create_tween()
		tween.set_parallel(true) 
		tween.tween_property($Windshield/Sprite2D,"rotation",-(PI),0.25)#.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		
		await tween.finished
		
		var tweenBack :Tween= get_tree().create_tween()
		tweenBack.set_parallel(true)
		tweenBack.tween_property($Windshield/Sprite2D,"rotation",0.0,0.25)
		await tweenBack.finished
	
	playingWindshieldWiper = false
