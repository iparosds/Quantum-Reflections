extends CharacterBody2D

var health = 100
var moving = true
var ore = false
const SHIP_ATTRACTION = 100.0
var asteroid_type
@onready var game = get_node("/root/Game")
@onready var player = get_node("/root/Game/Player")
@onready var portal = get_node("/root/Game/Portal")
const ORE = preload("res://scenes/ore.tscn")

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

func on_portal():
	queue_free()

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	if game.portal_active == true:
		direction = global_position.direction_to(portal.global_position)
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

func player_collision():
	asteroid_destruction()

func asteroid_destruction():
	moving = false
	$Asteroid.play("explosion")
	$AsteroidExplosion.start()
	$AudioStreamPlayer2D.play()
	$".".set_collision_layer_value(1, true)
	$".".set_collision_layer_value(2, false)

func add_new_ore():
	var new_ore = ORE.instantiate()
	new_ore.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", new_ore)

func take_damage():
	var damage = player.acceleration / 10
	if damage < 10:
		damage = 10
	health -= damage

	if health <= 0:
		asteroid_destruction()
		add_new_ore()
	else:
		Singleton.display_number(damage, $DamageText.global_position, '#b4b542')

func _on_asteroid_explosion_timeout() -> void:
	queue_free()

func _on_asteroid_life_timeout() -> void:
	queue_free()
