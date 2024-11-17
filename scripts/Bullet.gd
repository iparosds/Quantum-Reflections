class_name Bullet
extends Area2D

@export_range(0, 300, .2, "or_greater") var move_speed : float = 200.0
@onready var game = get_node("/root/Game")

var travelled_distance = 0
const SPEED = 200
const RANGE = 300
var direction
@onready var bullet_rotation = rotation
#@onready var bullet_rotation = %Projectile.rotation

func _ready():
	direction = Vector2.RIGHT.rotated(bullet_rotation)

func _physics_process(delta):
	if move_speed != 0:
		if game.quantum == false:
			%Projectile.play("default")
		else:
			%Projectile.play("quantum")
		position += direction * move_speed * delta
		travelled_distance += move_speed * delta
		if travelled_distance > RANGE:
			queue_free()

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
