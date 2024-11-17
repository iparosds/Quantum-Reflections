extends Area2D

@onready var timer = $TeleportTime

func _on_body_entered(body):
	print("You died!")
	#Engine.time_scale = 0.1
	#timer.start()

func _on_teleport_time_timeout() -> void:
	#Engine.time_scale = 1.0
	print("acabou")
	#get_tree().reload_current_scene()
