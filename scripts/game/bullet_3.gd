class_name Bullet3 extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var vanish_timer: Timer = $VanishTimer
@onready var mine_sprite: Sprite2D = $MineSprite
@onready var explosion_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var lifetime_seconds: float = 3.0
var insta_kill_amount: float = 99999.0
var can_hit_player: bool = false


## Inicializa o timer e configura a mina para começar ativa e monitorando colisões.
func _ready() -> void:
	vanish_timer.wait_time = lifetime_seconds
	vanish_timer.one_shot = true
	vanish_timer.start()
	monitoring = true
	monitorable = true
	explosion_animation.hide()
	if not vanish_timer.timeout.is_connected(_on_vanish_timer_timeout):
		vanish_timer.timeout.connect(_on_vanish_timer_timeout)
	await get_tree().create_timer(0.2).timeout
	can_hit_player = true


## Detecta colisão com um corpo e aplica dano.
func _on_body_entered(body: Node) -> void:
	# Player: dano baseado na velocidade (mesma lógica da colisão com asteroide)
	if body.has_method("is_player"):
		if not can_hit_player:
			return
		var damage = body.acceleration / 30.0
		if damage <= 10.0:
			damage = 10.0
		body.health -= damage
		_explode()
		#return
	if body.has_method("take_damage"):
		body.take_damage(insta_kill_amount, 1.0)
		_explode()


## Executa a animação e o som da explosão e desativa colisões.
func _explode() -> void:
	collision_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	vanish_timer.stop()
	mine_sprite.hide()
	explosion_animation.show()
	explosion_animation.play("explosion")
	explosion_sound.play()
	if not explosion_animation.animation_finished.is_connected(_on_explosion_finished):
		explosion_animation.animation_finished.connect(_on_explosion_finished)


func _on_explosion_finished() -> void:
	queue_free()


func _on_vanish_timer_timeout() -> void:
	_explode()
