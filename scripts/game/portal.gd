class_name Portal extends Area2D

var level


func _on_body_entered(body):
	if Singleton.level.portal_active == true:
		if body.has_method("is_player"):
			Singleton.level.win()
		if body.has_method("on_portal"):
			body.on_portal()
