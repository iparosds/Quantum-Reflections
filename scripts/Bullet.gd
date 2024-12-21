class_name Bullet
extends Area2D

var target
var direction
var travelled_distance = 0
var move_speed = 200
const RANGE = 300
@onready var game = get_node("/root/Game")
@onready var bullet_rotation = rotation

func _ready():
	#direction = Vector2.RIGHT.rotated(bullet_rotation)
	#direction = global_transform.basis_xform(Vector2.RIGHT)
	direction = global_position.direction_to(target.global_position)

func _physics_process(delta):
	if travelled_distance > RANGE:
		queue_free()
	if target == null:
		queue_free()
	else:
		if move_speed != 0:
			move_speed += 20
			direction = global_position.direction_to(target.global_position)
			if game.quantum == false:
				%Projectile.play("default")
			else:
				%Projectile.play("quantum")
			position += direction * move_speed * delta
			travelled_distance += move_speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()
	%Projectile.play("contact")
	move_speed = 0
	$Explosion.start()
	#await %Projectile.tree_exited 
	#queue_free()


func _on_explosion_timeout() -> void:
	queue_free()
