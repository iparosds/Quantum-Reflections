extends CanvasLayer

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused == true:
			%Pause.visible = false
			get_tree().paused = false
		else:
			%Pause.visible = true
			get_tree().paused = true
