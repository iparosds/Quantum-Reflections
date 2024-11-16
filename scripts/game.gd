extends Node2D;

const ASTEROID = preload("res://scenes/asteroid.tscn")

func spawn_asteroid():
	var new_asteroid = ASTEROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_asteroid.global_position = %PathFollow2D.global_position
	add_child(new_asteroid)

func _on_timer_timeout():
	spawn_asteroid()
