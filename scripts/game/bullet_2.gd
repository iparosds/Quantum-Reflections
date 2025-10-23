class_name Bullet2 extends Area2D

const RANGE : float= 200.0
const MAX_BOUNCES : int = 3

@onready var projectile: AnimatedSprite2D = %Projectile

var target : Node2D
var direction: Vector2
var travelled_distance : float= 0.0
var move_speed : float = 200.0
var damage_multiplier: float = 1.0
var bounce_count : int = 0
var bounce_chance: float = 0.30
var can_bounce: bool = false


func _ready():
	randomize()
	can_bounce = randf() < bounce_chance
	direction = global_position.direction_to(target.global_position).normalized()


func _physics_process(delta):
	if travelled_distance > RANGE:
		queue_free()
		return
	if target == null:
		queue_free()
		return
	else:
		if move_speed != 0:
			move_speed += 5
			position += direction * move_speed * delta
			travelled_distance += move_speed * delta
			projectile.rotate(0.5)


func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(-1.0, damage_multiplier)
		if can_bounce and bounce_count < MAX_BOUNCES:
			var diff_position = global_position - body.global_position
			if diff_position.length() > 0.0001:
				direction = direction.bounce(diff_position.normalized()).normalized()
				bounce_count += 1
			else:
				direction = -direction
				bounce_count += 1
		else:
			queue_free()
	else:
		queue_free()


func set_damage_multiplier(multiplier: float) -> void:
	damage_multiplier = multiplier
