extends Area2D

@onready var game = get_node("/root/Game")
var activated = true

func _on_body_entered(body):
	if activated == true:
		if body.has_method("is_player"):
			if body.is_player():
				body.portal()
				$AnimatedSprite2D.play("unloaded")
				#activated = false
