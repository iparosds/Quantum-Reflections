class_name Bullet2 extends Area2D

const RANGE = 300
@onready var projectile: AnimatedSprite2D = %Projectile
var target
var direction
var travelled_distance = 0
var move_speed = 200
var damage_multiplier: float = 1.0


func _ready():
	direction = global_position.direction_to(target.global_position)

func _physics_process(delta):
	if travelled_distance > RANGE:
		queue_free()
	if target == null:
		queue_free()
	else:
		if move_speed != 0:
			move_speed += 20
			position += direction * move_speed * delta
			travelled_distance += move_speed * delta
			projectile.rotate(0.7)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		# -1.0 : "calcula o base pela velocidade", e enviamos o multiplicador
		body.take_damage(-1.0, damage_multiplier)
	queue_free()


func set_damage_multiplier(multiplier: float) -> void:
	damage_multiplier = multiplier
