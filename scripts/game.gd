extends Node2D;

const ASTEROID = preload("res://scenes/asteroid.tscn")
var game_paused = false;
var score = 0;
@onready var score_label = $ScoreLabel

func spawn_asteroid():
	var new_asteroid = ASTEROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_asteroid.global_position = %PathFollow2D.global_position
	add_child(new_asteroid)

func _on_timer_timeout():
	spawn_asteroid()

func add_ore():
	score += 1
	score_label.text = str(score) + " ores."

func game_over():
	%GameOver.visible = true
	get_tree().paused = true

func get_score():
	return score;
