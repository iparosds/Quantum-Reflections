extends Area2D

@onready var game = get_node("/root/Game")
var activated = false
var player_on_black_hole = true
var size = 1

func _on_body_entered(body):
	if body.has_method("is_player"):
		if activated == true:
			player_on_black_hole = true
			game.game_over()
		else:
			$ActivateTimer.start()
	else:
		body.queue_free()
		game.spawn_asteroid()

func _physics_process(_delta):
	if game.quantum == false:
		$AnimatedSprite2D.play("default")
	else:
		$AnimatedSprite2D.play("quantum")

func _on_body_exited(body):
	if body.has_method("is_player"):
		player_on_black_hole = false
	activated = true

func _on_increase_size_timeout() -> void:
	if size < 20:
		$".".apply_scale(Vector2(1.1, 1.1))
	size += 1

func _on_activate_timer_timeout() -> void:
	activated = true
	if player_on_black_hole == true:
		game.game_over()
