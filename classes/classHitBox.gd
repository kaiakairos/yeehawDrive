class_name Hitbox
extends Node2D

@export var healthCompenent :HealthComponent

## used so entity dosn't damage ourselves
@export var parentObject :Node

@export var radius :float = 3

func _ready() -> void:
	add_to_group("hitbox")
