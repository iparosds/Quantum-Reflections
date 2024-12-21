extends Area2D

@onready var game = get_node("/root/Game")

func _on_body_entered(body):
	if game.portal_active == true:
		if body.has_method("is_player"):
			game.win()
		if body.has_method("on_portal"):
			body.on_portal()
