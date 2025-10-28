class_name Bullet3 extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var vanish_timer: Timer = $VanishTimer
@onready var mine_sprite: Sprite2D = $MineSprite
@onready var explosion_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var lifetime_seconds: float = 3.0
var insta_kill_amount: float = 99999


func _ready() -> void:
	vanish_timer.wait_time = lifetime_seconds
	vanish_timer.one_shot = true
	vanish_timer.start()
	monitoring = true
	monitorable = true
	explosion_animation.hide()
	if not vanish_timer.timeout.is_connected(_on_vanish_timer_timeout):
		vanish_timer.timeout.connect(_on_vanish_timer_timeout)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		collision_shape.set_deferred("disabled", true)
		set_deferred("monitoring", false)
		body.take_damage(insta_kill_amount, 1.0)
		vanish_timer.stop()
		mine_sprite.hide()
		explosion_animation.show()
		explosion_animation.frame = 0
		explosion_sound.play()
		explosion_animation.play("explosion")
		if not explosion_animation.animation_finished.is_connected(_on_explosion_finished):
			explosion_animation.animation_finished.connect(_on_explosion_finished)


func _on_explosion_finished() -> void:
	queue_free()


func _on_vanish_timer_timeout() -> void:
	queue_free()
