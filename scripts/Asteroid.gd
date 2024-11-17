extends CharacterBody2D

var health = 3
var moving = true
var ore = false
const SHIP_ATTRACTION = 100.0
@onready var player = get_node("/root/Game/Player")

func _ready():
	var rand = round(randf_range(1,3))
	if rand == 1:
		$Asteroid.play("asteroid01")
	if rand == 2:
		$Asteroid.play("asteroid02")
	if rand == 3:
		$Asteroid.play("asteroid03")

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	if moving == true:
		velocity = direction * SHIP_ATTRACTION
		move_and_slide()

func take_damage():
	player.acceleration
	health -= 3
	health -= player.acceleration/100

	if health <= 0:
		moving = false
		ore = true
		$Asteroid.play("explosion")
		$Asteroid.play("coin")
		$".".set_collision_layer_value(1, true)
		$".".set_collision_layer_value(2, false)
		#queue_free()
