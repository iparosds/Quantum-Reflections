extends Node2D

var quantum = false;
var closestDistance = 1000
@onready var closestEnemy = find_closest_enemy()

func find_closest_enemy() -> Object:
	var all_enemy = get_tree().get_nodes_in_group("asteroid")
	print(all_enemy)
	for enemy in all_enemy:
		var gun2enemy_distance = position.distance_to(enemy.position)
		if gun2enemy_distance < closestDistance:
			closestDistance = gun2enemy_distance
			closestEnemy = enemy
	return closestEnemy

func _process(delta):
	closestEnemy = find_closest_enemy()
