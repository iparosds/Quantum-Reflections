extends Area2D
const BULLET = preload("res://scenes/bullet.tscn")

func _physics_process(delta):
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		var target_enemy = enemies_in_range[0]
		look_at(target_enemy.global_position)

func shoot():
	var new_bullet = BULLET.instantiate()
	print(%ShootingPoint.global_position)
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.global_rotation = %ShootingPoint.global_rotation
	%ShootingPoint.add_child(new_bullet)

func _on_timer_timeout():
	shoot()
