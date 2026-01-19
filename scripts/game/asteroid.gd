class_name Asteroid extends CharacterBody2D

const ORE : PackedScene = preload("res://scenes/game/ore.tscn")
const MIN_DAMAGE : float = 10.0

@onready var player : Node2D = Singleton.level.get_node_or_null("Player")

@export var health_multiplier: float = 1.0
@export var base_speed: float = 100.0
@export var speed_multiplier: float = 1.0
@export var splits_on_death: bool = false
@export var split_count: int = 4
@export var asteroid_type : int = 0

var health : int = 100
var moving : bool = true
var portal : Node2D = null


## Escolhe aleatoriamente um tipo de asteroide (1, 2 ou 3) 
## e toca a animação correspondente ao iniciar a cena.
func _ready():
	health = int(health * health_multiplier)
	print("ASTEROID TYPE:", asteroid_type, "HP:", health)
	if asteroid_type == 0:
		var rand = round(randf_range(1,3))
		if rand == 1:
			asteroid_type = 1
		elif rand == 2:
			asteroid_type = 2
		else:
			asteroid_type = 3
	if asteroid_type == 1:
		$Asteroid.play("asteroid01")
	elif asteroid_type == 2:
		$Asteroid.play("asteroid02")
	else:
		$Asteroid.play("asteroid03")
	
	if has_node("AudioStreamPlayer2D"):
		var explosion_player := $AudioStreamPlayer2D
		explosion_player.bus = "SFX"


## Armazena a referência ao portal aberto, 
## usada para direcionar o movimento do asteroide até ele.
func on_portal_opened(p: Node2D) -> void:
	portal = p


## Remove o asteroide da cena quando entra em um portal ativo.
func on_portal() -> void:
	queue_free()


## Atualiza o movimento e animação do asteroide a cada frame de física.
## Segue o player por padrão, mas se o portal estiver ativo, 
## é atraído ou repelido conforme o modo quantum.
func _physics_process(_delta) -> void:
	if !is_instance_valid(player):
		player = Singleton.level.get_node_or_null("Player")
		if !is_instance_valid(player):
			return
	
	var direction: Vector2
	
	if Singleton.level.portal_active:
		if !is_instance_valid(portal):
			portal = get_tree().get_first_node_in_group("portal")
		if is_instance_valid(portal):
			direction = global_position.direction_to(portal.global_position)
		else:
			direction = global_position.direction_to(player.global_position)
	else:
		direction = global_position.direction_to(player.global_position)
	
	if moving:
		if !Singleton.level.quantum:
			if asteroid_type == 1:
				$Asteroid.play("asteroid01")
			elif asteroid_type == 2:
				$Asteroid.play("asteroid02")
			else:
				$Asteroid.play("asteroid03")
			velocity = direction * base_speed * speed_multiplier
		else:
			velocity = -direction * base_speed * speed_multiplier
			if asteroid_type == 1:
				$Asteroid.play("asteroid01-quantum")
			elif asteroid_type == 2:
				$Asteroid.play("asteroid02-quantum")
			else:
				$Asteroid.play("asteroid03-quantum")
		move_and_slide()


## Chamada quando o asteroide colide com o jogador. 
## Inicia o processo de destruição.
func player_collision() -> void:
	take_damage(health)


## Executa a sequência de destruição do asteroide: 
## animação, som e registro da morte.
func asteroid_destruction() -> void:
	moving = false
	$Asteroid.play("explosion")
	$AsteroidExplosion.start()
	
	$AudioStreamPlayer2D.bus = "SFX"
	$AudioStreamPlayer2D.volume_db = -6.0 # ajuste só da explosão, se quiser
	$AudioStreamPlayer2D.play()
	set_collision_layer_value(1, true)
	set_collision_layer_value(2, false)
	SaveManager.on_enemy_killed()


## Instancia um novo minério no local da destruição e adiciona-o à cena atual.
func add_new_ore() -> void:
	var new_ore = ORE.instantiate()
	new_ore.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", new_ore)


## Aplica dano ao asteroide.
## - Se amount for >= 0, usa esse valor como dano fixo.
## - Se amount for -1.0 (padrão), calcula o dano automaticamente com base na aceleração do player.
func take_damage(amount: float = -1.0, multiplier: float = 1.0) -> void:
	var damage := 0.0
	if amount >= 0.0:
		damage = amount
	else:
		var base := MIN_DAMAGE
		if is_instance_valid(player):
			base = max(MIN_DAMAGE, float(player.acceleration) / 10.0)
		damage = base * max(0.0, multiplier)
	health -= int(damage)
	if health <= 0.0:
		asteroid_destruction()
		if splits_on_death:
			_spawn_split_asteroids()
		else:
			add_new_ore()
	else:
		Singleton.display_number(int(damage), $DamageText.global_position, "#b4b542")


## Remove o asteroide da cena quando o timer de explosão termina.
func _on_asteroid_explosion_timeout() -> void:
	queue_free()


## Remove o asteroide da cena quando o tempo de vida total expira.
func _on_asteroid_life_timeout() -> void:
	queue_free()

func _spawn_split_asteroids():
	if not is_instance_valid(Singleton.level):
		return
	for i in range(split_count):
		var asteroid := Singleton.level.ASTEROID.instantiate()
		var angle := TAU * float(i) / float(split_count)
		var offset := Vector2.RIGHT.rotated(angle) * 24
		asteroid.global_position = global_position + offset
		asteroid.health_multiplier = 1.0
		asteroid.speed_multiplier = 1.0
		asteroid.splits_on_death = false
		var asteroids_group = get_tree().get_first_node_in_group("asteroids")
		asteroids_group.call_deferred("add_child", asteroid)
