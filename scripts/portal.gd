extends Area2D

@onready var game = get_node("/root/Game")
var activated = true

func activate_portal():
	get_tree().paused = true
	print('entrou')
	pass

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused == true:
			get_tree().paused = false

func _on_body_entered(body):
	if activated == true:
		if body.has_method("is_player"):
			if body.is_player():
				activate_portal()
