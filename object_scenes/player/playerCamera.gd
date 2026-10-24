extends Camera2D


var shakeX :float = 0.0
var shakeY :float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	offset.x = sin(Time.get_ticks_msec() * 0.5) * shakeX
	offset.y = sin((Time.get_ticks_msec() + 1329) * 0.52) * shakeX
	
	shakeX = move_toward(shakeX,0.0,delta*3.5)
	shakeY = move_toward(shakeY,0.0,delta*3.5)

func addShake(x:float=0.0,y:float=0.0) -> void:
	shakeX += x
	shakeY += y
