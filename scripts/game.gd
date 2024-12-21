extends Node2D;

const ASTEROID = preload("res://scenes/asteroid.tscn")
var game_paused = false;
var quantum = false;
var god_mode = false;
var portal_active = false;
var score = 0;
var quantum_roll = 0
var portal_timer = 150.0
@onready var score_label = $UI/ScoreLabel
@onready var start_game = preload("res://scenes/game.tscn") as PackedScene

func _ready():
	AudioPlayer.stop()

func win():
	get_tree().paused = true
	%GameOver.visible = true
	$GameOver/ColorRect/Label.text = "You win!"

func game_over():
	if god_mode == false:
		get_tree().paused = true
		%GameOver.visible = true

func spawn_asteroid():
	var new_asteroid = ASTEROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_asteroid.global_position = %PathFollow2D.global_position
	var asteroids_group = get_tree().get_first_node_in_group("asteroids")
	asteroids_group.call_deferred("add_child", new_asteroid)

func reset_quantum():
	if quantum_roll >= 5 || randi_range(0,5) == 0:
		quantum = false;
		quantum_roll = 0
	else:
		quantum_roll += 1

func _physics_process(delta):
	if Input.is_action_just_released("god"):
		if god_mode == false:
			god_mode = true
			$UI/GodMode.visible = true
		else:
			god_mode = false
			$UI/GodMode.visible = false
	if quantum == true:
		Engine.time_scale = 0.8
		RenderingServer.set_default_clear_color(Color.hex(0x7c7ea1ff))
	else:
		Engine.time_scale = 1
		RenderingServer.set_default_clear_color(Color.hex(0x2f213bff))
	portal_timer -= delta
	var time_left = int(portal_timer)
	if time_left < 1:
		if portal_active == false:
			portal_active = true
			portal_timer = 20.0
			$UI/PortalActive.visible = true
			$UI/Timer.get("theme_override_styles/fill").bg_color = Color.hex(0xb4b542ff)
		else:
			game_over()
	var portal_minutes = 0
	if time_left > 60:
		portal_minutes = time_left/60
	var portal_seconds = time_left
	if portal_minutes > 0:
		portal_seconds = time_left - portal_minutes * 60
	if portal_seconds < 10:
		$UI/Label.text = str(portal_minutes, ":0", portal_seconds)
	else:
		$UI/Label.text = str(portal_minutes, ":", portal_seconds)
	if portal_active == true:
		$UI/Timer.max_value = 20
	else:
		$UI/Timer.max_value = 150
	$UI/Timer.value = int(portal_timer)

func add_ore():
	score += 1
	score_label.text = str(score) + " ores"
	if score <= 10:
		$UI/XP.max_value = 10
		$UI/XP.value = score
	elif score > 10 && score <= 50:
		$UI/XP.max_value = 50
		$UI/XP.value = score - 10
	elif score > 50 && score <= 100:
		$UI/XP.max_value = 100
		$UI/XP.value = score - 50
	elif score > 100 && score <=200:
		$UI/XP.max_value = 200
		$UI/XP.value = score - 100
	elif score > 200 && score <= 400:
		$UI/XP.max_value = 400
		$UI/XP.value = score - 200
	elif score > 400 && score <= 600:
		$UI/XP.max_value = 600
		$UI/XP.value = score - 400
	elif score > 600 && score < 800:
		$UI/XP.max_value = 800
		$UI/XP.value = score - 600

func _on_button_pressed() -> void:
	get_tree().paused = false
	%GameOver.visible = false
	quantum = false;
	quantum_roll = 0
	get_tree().reload_current_scene()

func get_score():
	return score;

func _on_world_body_exited(body: Node2D) -> void:
	if body.has_method("is_player"):
		body.world_limit($World/CollisionShape2D.shape.radius)
	else:
		body.queue_free()

func _on_time_timeout():
	if quantum == true:
		reset_quantum()
	spawn_asteroid() #10
	if score > 5:
		spawn_asteroid() #50
	if score > 10:
		spawn_asteroid() #100
	if score > 100:
		spawn_asteroid() #200
	if score > 200:
		spawn_asteroid() #400
	if score > 400:
		spawn_asteroid() #600
	if score > 600:
		spawn_asteroid() #800
