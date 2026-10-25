extends Node2D

# this is just a placeholder scene to get a basic gameplay loop available for a demo

var enemyScene :PackedScene = preload("res://object_scenes/enemies/boidFlyer/boid_flyer.tscn")

var enemySpawnTimer :float = 0.0

func _process(delta: float) -> void:
	enemySpawnTimer += delta
	
	if enemySpawnTimer > 4.0:
		spawnEnemy() 
		enemySpawnTimer = 0.0
	
	if GlobalReference.playerHealthComponent.health <= 0:
		get_tree().reload_current_scene()
	

func spawnEnemy() -> void:
	
	var erm :Array[Node] = get_tree().get_nodes_in_group("boidAvoid")
	
	if erm.size() > 5:
		return
	
	var obj :BoidFlyer = enemyScene.instantiate()
	obj.global_position = GlobalReference.player.global_position + Vector2(500,0).rotated(randf_range(-PI,PI))
	add_child(obj)
