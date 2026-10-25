class_name HealthComponent
extends Node

@onready var damageIndicator :PackedScene= preload("res://ui_scenes/damageIndicator/damage_indicator.tscn")

@export var defaultMaxHealth :int = 100
var maxHealth :int = 100
var health :int = 100

var healthUpgradeLevel :int = 1
@export var healthIncreasePerLevel :int = 5

signal tookDamage(amount:int)
signal justgotkilled
var emittedKilled :bool = false

signal tookKnockback(amount:Vector2)
signal healthUpdated(health:int,maxHealth:int)
signal healed(amount:int)

@export var isPlayer :bool = false

func _ready() -> void:
	setMaxHealth()
	health = maxHealth
	if isPlayer:
		GlobalReference.playerHealthComponent = self

func setMaxHealth() -> void:
	maxHealth = defaultMaxHealth + (healthIncreasePerLevel * (healthUpgradeLevel-1))
	emit_signal("healthUpdated",health,maxHealth)
	
func upgradeHealthLevel(amount:int=1) -> void:
	healthUpgradeLevel += amount
	setMaxHealth()
	health += healthIncreasePerLevel * amount
	emit_signal("healthUpdated",health,maxHealth)

func dealDamage(amount:int=0) -> void:
	if emittedKilled:
		return # don't take more damage if we're dead!
	health -= amount
	
	var obj :DamageIndicator= damageIndicator.instantiate()
	obj.displayNumber = amount
	if isPlayer:
		obj.displayColor = Color(1.0, 0.183, 0.0, 1.0)
	else:
		obj.displayColor = Color(0.855, 0.143, 0.529, 1.0)
	obj.global_position = get_parent().global_position
	get_parent().get_parent().add_child(obj)
	
	
	
	emit_signal("tookDamage",amount)
	
	emit_signal("healthUpdated",health,maxHealth)
	if health <= 0 and !emittedKilled:
		emit_signal("justgotkilled")
		emittedKilled = true


func heal(amount:int) -> void:
	if emittedKilled:
		return # don't heal if we've already died
	health += amount
	health = min(health,maxHealth)
	
	var obj :DamageIndicator= damageIndicator.instantiate()
	obj.displayNumber = amount
	obj.displayColor = Color(0.407, 1.0, 0.0, 1.0)
	obj.global_position = get_parent().global_position
	get_parent().get_parent().add_child(obj)
	
	emit_signal("healed",amount)
	emit_signal("healthUpdated",health,maxHealth)
	
func recieveKnockback(vel:Vector2) -> void:
	emit_signal("tookKnockback",vel)
