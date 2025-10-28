class_name Bullet3 extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var vanish_timer: Timer = $VanishTimer
@onready var mine_sprite: Sprite2D = $MineSprite

var lifetime_seconds: float = 3.0
var insta_kill_amount: float = 99999


func _ready() -> void:
	vanish_timer.wait_time = lifetime_seconds
	vanish_timer.one_shot = true
	vanish_timer.start()
	monitoring = true
	monitorable = true
	if not vanish_timer.timeout.is_connected(_on_vanish_timer_timeout):
		vanish_timer.timeout.connect(_on_vanish_timer_timeout)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		collision_shape.set_deferred("disabled", true)
		set_deferred("monitoring", false)
		body.take_damage(insta_kill_amount, 1.0)
		queue_free()


func _on_vanish_timer_timeout() -> void:
	queue_free()
