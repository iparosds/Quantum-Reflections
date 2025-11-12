class_name Bullet extends Area2D

const RANGE : int = 300

var target : Node2D
var direction : Vector2
var travelled_distance : int = 0
var move_speed : int = 200
var damage_multiplier : float = 1.0


## Define a direção inicial do projétil em direção ao alvo assim que ele é criado.
func _ready():
	direction = global_position.direction_to(target.global_position)


## Atualiza o movimento e a animação do projétil a cada frame de física.
## Remove o projétil se ultrapassar o alcance máximo ou se o alvo deixar de existir.
func _physics_process(delta):
	if travelled_distance > RANGE:
		queue_free()
	if target == null:
		queue_free()
	else:
		if move_speed != 0:
			move_speed += 20
			direction = global_position.direction_to(target.global_position)
			if !Singleton.level.quantum:
				%Projectile.play("default")
			else:
				%Projectile.play("quantum")
			position += direction * move_speed * delta
			travelled_distance += move_speed * delta


## Executado quando o projétil colide com outro corpo.
## Aplica dano se o corpo tiver o método take_damage e inicia a animação de impacto.
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(-1.0, damage_multiplier)
	%Projectile.play("contact")
	move_speed = 0
	$Explosion.start()


## Remove o projétil da cena após o término da animação de explosão.
func _on_explosion_timeout() -> void:
	queue_free()


## Define o multiplicador de dano que será aplicado ao atingir o alvo.
func set_damage_multiplier(multiplier: float) -> void:
	damage_multiplier = multiplier
