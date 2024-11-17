extends Area2D

@onready var game = get_node("/root/Game")
const BULLET_1 = preload("res://scenes/bullet.tscn")
const BULLET_2 = preload("res://scenes/bullet_2.tscn")
var current_bullet = 2;

func _physics_process(delta):
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		var target_enemy = enemies_in_range.front()
		#look_at(target_enemy.global_position)

func shoot():
	var new_bullet
	if current_bullet == 1:
		new_bullet = BULLET_1.instantiate()
	else:
		new_bullet = BULLET_2.instantiate()
	new_bullet.position = %ShootingPoint.position
	new_bullet.rotation = %ShootingPoint.rotation
	%ShootingPoint.add_child(new_bullet)

func _on_timer_timeout():
	shoot()
