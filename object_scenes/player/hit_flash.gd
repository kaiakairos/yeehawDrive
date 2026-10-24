extends ColorRect

@export var hitflash :Gradient

var gradientPos :float = 1.2

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	gradientPos += delta * 3.0
	color = hitflash.sample(gradientPos)

func flash() -> void:
	gradientPos = 0.0


func _on_health_component_took_damage(amount:int) -> void:
	flash()
	color = hitflash.sample(gradientPos)
	var shakeAmount :float= clamp(amount*0.2,0.0,6.0)
	$"../../Camera2D".addShake(shakeAmount,shakeAmount)
	
	if amount > 4:
		get_tree().paused = true
		await get_tree().create_timer(amount * 0.01).timeout
		get_tree().paused = false
	$"../..".state = 2
	$"../..".lostControlTick = 0.3
