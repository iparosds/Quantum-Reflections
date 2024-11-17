extends Node2D;

const ASTEROID = preload("res://scenes/asteroid.tscn")
var game_paused = false;
var quantum = false;
var score = 0;
@onready var score_label = $ScoreLabel

func spawn_asteroid():
	var new_asteroid = ASTEROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_asteroid.global_position = %PathFollow2D.global_position
	var asteroids_group = get_tree().get_first_node_in_group("asteroids")
	asteroids_group.add_child(new_asteroid)

func reset_quantum():
	if randi_range(0,10) == 0:
		quantum = false;

func _physics_process(delta):
	if quantum == true:
		Engine.time_scale = 0.5
		RenderingServer.set_default_clear_color(Color.hex(0x7c7ea1ff))
	else:
		Engine.time_scale = 1
		RenderingServer.set_default_clear_color(Color.hex(0x2f213bff))
		
func _on_timer_timeout():
	if quantum == true:
		reset_quantum()
	spawn_asteroid()
	if score > 2:
		spawn_asteroid()
	if score > 4:
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
	if score > 8:
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
	if score > 10:
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()
		spawn_asteroid()

func add_ore():
	score += 1
	score_label.text = str(score) + " ores."

func game_over():
	%GameOver.visible = true
	get_tree().paused = true

func get_score():
	return score;
