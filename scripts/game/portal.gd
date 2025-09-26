class_name Portal extends Area2D

@onready var portal_sprite: AnimatedSprite2D = $AnimatedSprite2D
var start_animated: bool = false


func _ready() -> void:
	if not is_instance_valid(portal_sprite):
		return
	
	if start_animated:
		portal_sprite.play()
	else:
		portal_sprite.stop()
		portal_sprite.playing = false


func _on_body_entered(body):
	if Singleton.level.portal_active == true:
		if body.has_method("is_player"):
			Singleton.level.win()
		if body.has_method("on_portal"):
			body.on_portal()
