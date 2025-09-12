extends CharacterBody2D

const SHIP_ATTRACTION = 100.0
const ORE = preload("res://scenes/game/ore.tscn")
const MIN_DAMAGE := 10.0

var health = 100
var moving = true
var ore = false
var asteroid_type
var level


@onready var player: Node2D = Singleton.level.get_node_or_null("Player")
var portal: Node2D = null


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


func on_portal_opened(p: Node2D) -> void:
	portal = p


func on_portal():
	queue_free()


func _physics_process(_delta):
	if !is_instance_valid(player):
		player = Singleton.level.get_node_or_null("Player")
		if !is_instance_valid(player):
			return

	var direction: Vector2

	if Singleton.level.portal_active:
		if portal == null or !is_instance_valid(portal):
			portal = get_tree().get_first_node_in_group("portal")
		if is_instance_valid(portal):
			direction = global_position.direction_to(portal.global_position)
		else:
			direction = global_position.direction_to(player.global_position)
	else:
		direction = global_position.direction_to(player.global_position)

	if Singleton.level.quantum == false:
		if moving == true:
			if asteroid_type == 1:
				$Asteroid.play("asteroid01")
			elif asteroid_type == 2:
				$Asteroid.play("asteroid02")
			else:
				$Asteroid.play("asteroid03")
			velocity = direction * SHIP_ATTRACTION
	else:
		if moving == true:
			velocity = -direction * SHIP_ATTRACTION
			if asteroid_type == 1:
				$Asteroid.play("asteroid01-quantum")
			elif asteroid_type == 2:
				$Asteroid.play("asteroid02-quantum")
			else:
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


func take_damage(amount: float = -1.0, multiplier: float = 1.0) -> void:
	var damage := 0.0

	if amount >= 0.0:
		damage = amount
		print("[Asteroid] incoming=", amount, " applied=", damage, " hp_before=", health)
	else:
		# Dano base pela velocidade do player
		var base := MIN_DAMAGE
		if is_instance_valid(player):
			base = max(MIN_DAMAGE, float(player.acceleration) / 10.0)

		# combinação base + multiplicador
		damage = base * max(0.0, multiplier)
		
		# Se quiser SOMAR em vez de multiplicar, troque a linha acima por:
		#damage = base + (multiplier)
		print("[Asteroid] incoming=", amount, " applied=", damage, " hp_before=", health)

	health -= damage
	#print("[Asteroid] hp_after=", health)
	if health <= 0.0:
		asteroid_destruction()
		add_new_ore()
	else:
		Singleton.display_number(damage, $DamageText.global_position, "#b4b542")


func _on_asteroid_explosion_timeout() -> void:
	queue_free()


func _on_asteroid_life_timeout() -> void:
	queue_free()
