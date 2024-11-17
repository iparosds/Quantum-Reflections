extends CharacterBody2D

var health = 3
var moving = true
var ore = false
const SHIP_ATTRACTION = 100.0
var asteroid_type
@onready var player = get_node("/root/Game/Player")
@onready var game = get_node("/root/Game")

func _ready():
	var rand = round(randf_range(1,3))
	if rand == 1:
		asteroid_type = 1
		$Asteroid.play("asteroid01")
	if rand == 2:
		asteroid_type = 2
		$Asteroid.play("asteroid02")
	if rand == 3:
		asteroid_type = 3
		$Asteroid.play("asteroid03")

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	if game.quantum == false:
		if moving == true:
			if asteroid_type == 1:
				$Asteroid.play("asteroid01")
			if asteroid_type == 2:
				$Asteroid.play("asteroid02")
			if asteroid_type == 3:
				$Asteroid.play("asteroid03")
			velocity = direction * SHIP_ATTRACTION
	else:
		if moving == true:
			velocity = -direction * SHIP_ATTRACTION
			if asteroid_type == 1:
				$Asteroid.play("asteroid01-quantum")
			if asteroid_type == 2:
				$Asteroid.play("asteroid02-quantum")
			if asteroid_type == 3:
				$Asteroid.play("asteroid03-quantum")
	if moving == true:
		move_and_slide()

func take_damage():
	player.acceleration
	health -= 3
	health -= player.acceleration/100

	if health <= 0:
		moving = false
		ore = true
		$Asteroid.play("explosion")
		$AsteroidExplosion.start()
		$".".set_collision_layer_value(1, true)
		$".".set_collision_layer_value(2, false)
		#queue_free()

func _on_asteroid_explosion_timeout() -> void:
	$Asteroid.play("coin")
