extends CharacterBody2D

var health = 3
const SHIP_ATTRACTION = 100.0
@onready var player = get_node("/root/Game/Player")

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * SHIP_ATTRACTION
	move_and_slide()

func take_damage():
	player.acceleration
	print(player.acceleration)
	health -= player.acceleration/100
	
	if health <= 0:
		queue_free()
