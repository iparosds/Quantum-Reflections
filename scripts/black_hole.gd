extends Area2D

@onready var game = get_node("/root/Game")
var activated = false

func _on_body_entered(body):
	if activated == true:
		if body.has_method("is_player"):
			if body.is_player():
				game.game_over()
				print("acabou")

func _on_body_exited(body):
	activated = true
	pass
