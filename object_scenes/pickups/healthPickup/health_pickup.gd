extends ItemPickup

func additionalProcess(delta:float) -> void:
	$HeightOrigin/shine.rotate(4.0*delta)
