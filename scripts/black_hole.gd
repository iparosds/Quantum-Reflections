extends Area2D

@onready var game = get_node("/root/Game")
var activated = false

func _on_body_entered(body):
	if activated == true:
		game.game_over()
		print("acabou")


func _on_body_exited(body):
	activated = true
