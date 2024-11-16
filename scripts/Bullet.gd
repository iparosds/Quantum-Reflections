extends Area2D

var travelled_distance = 0
const SPEED = 2000
const RANGE = 3000
var direction
@onready var bullet_rotation = rotation
#@onready var bullet_rotation = %Projectile.rotation

func _ready():
	direction = Vector2.RIGHT.rotated(bullet_rotation)

func _physics_process(delta):
	position += direction * SPEED * delta
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free()

func _on_body_entered(body):
	queue_free()
	if body.has_method("take_damage"):
		body.take_damage()
