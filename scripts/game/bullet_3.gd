class_name Bullet3 extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var vanish_timer: Timer = $VanishTimer
@onready var mine_sprite: Sprite2D = $MineSprite
@onready var explosion_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var lifetime_seconds: float = 3.0
var can_hit_player: bool = false
var damage : float = 0.0


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
	damage_enemy(body)
	damage_player(body)


## Aplica dano ao Player somente se a mina estiver autorizada a atingi-lo.
## O dano é calculado com base na aceleração atual do Player,
## Após aplicar o dano, a mina explode.
func damage_player(body: Node) -> void:
	if body is Player:
		if not can_hit_player:
			return
		damage = body.acceleration / 30.0
		if damage <= 10.0:
			damage = 10.0
		body.health -= damage
		explode()


## Aplica dano a inimigos que implementam `take_damage`.
## O dano é calculado a partir da velocidade do corpo,
## Explode a mina após o impacto.
func damage_enemy(body: Node) -> void:
	if body.has_method("take_damage"):
		damage = body.velocity.length() / 7.0
		if damage <= 10.0:
			damage = 10.0
		body.take_damage(damage, 1.0)
		print("ASTEROID damaged: ", snapped(damage, 0.01))
		explode()


## Executa a animação e o som da explosão e desativa colisões.
func explode() -> void:
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
	explode()
