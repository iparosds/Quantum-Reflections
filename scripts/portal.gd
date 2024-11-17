extends Area2D

@onready var game = get_node("/root/Game")
var activated = true

func activate_portal():
	print('entrou')
	pass

func _on_body_entered(body):
	if activated == true:
		if body.has_method("is_player"):
			if body.is_player():
				activate_portal()
