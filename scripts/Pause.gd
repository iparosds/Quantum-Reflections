extends CanvasLayer

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		print(get_tree().paused)
		if get_tree().paused == true:
			%Pause.visible = false
			get_tree().paused = false
		else:
			%Pause.visible = true
			get_tree().paused = true
