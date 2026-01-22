class_name Turret extends Area2D

const BULLET_1 = PlayerUpgrades.BULLET_1_SCENE
const BULLET_2 = PlayerUpgrades.BULLET_2_SCENE

@export var projectile : Projectile
@export var projectiles_parent_group = "projectile_parent"

var projectiles_node : Node
var cooldown : bool = false
var current_bullet : int = 0


## Inicializa a referência ao nó pai de projéteis via grupo configurado.
## Garante, com assert, que o nó existe antes de continuar.
func _ready() -> void:
	projectiles_node = get_tree().get_first_node_in_group(projectiles_parent_group)
	assert(projectiles_node != null, "Projectiles node is required")


## Instancia o projétil conforme o tipo selecionado (current_bullet),
## configura posição/rotação/alvo, aplica multiplicador de dano vindo de PlayerUpgrades
## e adiciona o projétil como filho do ponto de disparo.
func shoot(target_enemy):
	var new_bullet: Node
	var shot_stream: AudioStream = $AudioStreamPlayer2D.stream
	AudioPlayer.play_shot(shot_stream, true, 6.0)
	$AudioStreamPlayer2D.stop()
	if current_bullet == 1:
		new_bullet = BULLET_1.instantiate()
		$AudioStreamPlayer2D.play()
	elif current_bullet == 2:
		new_bullet = BULLET_2.instantiate()
		$AudioStreamPlayer2D.play()
	else:
		return
	new_bullet.position = %ShootingPoint.position
	new_bullet.rotation = %ShootingPoint.rotation
	new_bullet.target = target_enemy
	var multiplier := 1.0
	if PlayerUpgrades:
		multiplier = PlayerUpgrades.get_damage_multiplier_for_weapon_id(current_bullet)
	if new_bullet.has_method("set_damage_multiplier"):
		new_bullet.set_damage_multiplier(multiplier)
	else:
		new_bullet.damage_multiplier = multiplier
	%ShootingPoint.add_child(new_bullet)


## Verifica a cada frame de física se pode atirar,
## seleciona um inimigo na área, dispara e inicia o temporizador de recarga.
func _physics_process(_delta):
	if not cooldown and current_bullet != 0:
		var enemies_in_range = get_overlapping_bodies()
		if enemies_in_range.size() > 0:
			var target_enemy = enemies_in_range.front()
			shoot(target_enemy)
			$ShootingInterval.start()
			cooldown = true


## Callback do temporizador de recarga: libera a turret para um novo disparo.
func _on_timer_timeout():
	cooldown = false
