extends Node2D

@export var size :Vector2i = Vector2i(1,6)

@export_enum("Bottom-Up","Top-Down","Left-Right","Right-Left") var fillMode :int = 0

@export var maxValue :float = 100.0

@export var colorDictionary :Dictionary[float,Color]

func updateValue(value:float) -> void:
	$bg.size = size + Vector2i(2,2)
	
	var ratio :float = value / maxValue
	ratio = clamp(ratio,0.0,1.0)
	
	match fillMode:
		0,1: 
			$progress.size = Vector2(size) * Vector2(1.0,ratio)
			$progress.size.y = roundi($progress.size.y)
		2,3: $progress.size = Vector2(size) * Vector2(ratio,1.0)
	
	match fillMode:
		1,2: $progress.position = Vector2(1.0,1.0)
		0: $progress.position = Vector2(1.0,roundi(size.y - $progress.size.y) + 1.0)
		3: $progress.position = Vector2(roundi(size.x - $progress.size.x + 1.0),1.0)
	
	for key in colorDictionary.keys():
		if value > key:
			$progress.color = colorDictionary[key]
		else:
			break

func updateMax(amount:int,maximumizing:int) -> void:
	maxValue = maximumizing
	updateValue(amount)
