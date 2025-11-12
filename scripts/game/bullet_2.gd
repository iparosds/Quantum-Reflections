class_name Bullet2 extends Area2D

const RANGE : float = 200.0
const MAX_BOUNCES : int = 3

@onready var projectile: AnimatedSprite2D = %Projectile

var target : Node2D
var direction: Vector2
var travelled_distance : float = 0.0
var move_speed : float = 400.0
var damage_multiplier: float = 1.0
var bounce_count : int = 0
var bounce_chance: float = 90.0
var can_bounce: bool = false


## Inicializa o projétil definindo chance de ricochete e direção inicial
## em direção ao alvo, normalizando o vetor de movimento.
func _ready():
	randomize()
	can_bounce = randf() * 100 < bounce_chance
	direction = global_position.direction_to(target.global_position)


## Atualiza o movimento do projétil a cada frame de física.
## Remove o projétil se ultrapassar o alcance máximo ou se o alvo deixar de existir.
## Incrementa gradualmente a velocidade e adiciona rotação visual ao sprite.
func _physics_process(delta):
	if travelled_distance > RANGE:
		queue_free()
		return
	if target == null:
		queue_free()
		return
	if move_speed != 0:
		move_speed += 5
		position += direction * move_speed * delta
		travelled_distance += move_speed * delta
		projectile.rotate(0.5)


## Executado ao colidir com outro corpo.
## Aplica dano se o corpo possuir o método "take_damage".
## Caso o projétil tenha chance de ricochete e ainda possa fazê-lo,
## recalcula a direção do movimento e reduz gradualmente o tamanho.
## Caso contrário, remove o projétil da cena.
func _on_body_entered(body):
	if not body.has_method("take_damage"):
		queue_free()
		return
	body.take_damage(-1.0, damage_multiplier)
	if can_bounce and bounce_count < MAX_BOUNCES:
		var diff_position = global_position - body.global_position
		if diff_position.length() > 0.0001:
			direction = direction.bounce(diff_position.normalized())
		else:
			direction = -direction
		bounce_count += 1
		projectile.scale = projectile.scale.lerp(Vector2.ZERO, 0.3)
		if projectile.scale.x < 0.2 or projectile.scale.y < 0.2:
			queue_free()
	else:
		queue_free()


## Define o multiplicador de dano aplicado ao atingir o alvo.
## O valor influencia o cálculo de dano dentro do método "take_damage".
func set_damage_multiplier(multiplier: float) -> void:
	damage_multiplier = multiplier
