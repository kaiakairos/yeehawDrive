extends Node2D

@export var size :Vector2i = Vector2i(1,6)

@export_enum("Bottom-Up","Top-Down","Left-Right","Right-Left") var fillMode :int = 0

@export var maxValue :float = 100.0

func updateValue(value:float) -> void:
	$bg.size = size + Vector2i(2,2)
	
	var ratio :float = value / maxValue
	
	match fillMode:
		0,1: $progress.size = Vector2(size) * Vector2(1.0,ratio)
		2,3: $progress.size = Vector2(size) * Vector2(ratio,1.0)
