class_name Turret extends Area2D

const BULLET_1 = PlayerUpgrades.BULLET_1_SCENE
const BULLET_2 = PlayerUpgrades.BULLET_2_SCENE

@export var projectile : Projectile
@export var projectiles_parent_group = "projectile_parent"

var projectiles_node : Node
var cooldown = false
var current_bullet = 0;


func try_shoot() -> bool:
	push_error("Not implemented")
	return false


func _ready() -> void:
	projectiles_node = get_tree().get_first_node_in_group(projectiles_parent_group)
	assert(projectiles_node != null, "Projectiles node is required")


func shoot(target_enemy):
	$AudioStreamPlayer2D.play()

	var new_bullet: Node
	if current_bullet == 1:
		new_bullet = BULLET_1.instantiate()
	else:
		new_bullet = BULLET_2.instantiate()

	new_bullet.position = %ShootingPoint.position
	new_bullet.rotation = %ShootingPoint.rotation
	new_bullet.target = target_enemy

	# >>> INJETAR MULTIPLICADOR (pego do PlayerStats)
	if PlayerUpgrades != null:
		var mult := 1.0
		# 1 = Bullet.tscn, 2 = Bullet_2.tscn
		if current_bullet == 1:
			mult = PlayerUpgrades.get_active_damage_multiplier(1)
		else:
			mult = PlayerUpgrades.get_active_damage_multiplier(2)
		
		if new_bullet.has_method("set"):
			new_bullet.damage_multiplier = mult
		
		#print("[Turret] firing bullet_id=", current_bullet, " mult=", mult)
	
	# Opcional: também pode injetar um base_damage específico por arma/nível
	# new_bullet.base_damage = 10.0
	
	%ShootingPoint.add_child(new_bullet)


func _physics_process(_delta):
	if cooldown == false && current_bullet != 0:
		var enemies_in_range = get_overlapping_bodies()
		if enemies_in_range.size() > 0:
			var target_enemy = enemies_in_range.front()
			shoot(target_enemy)
			$ShootingInterval.start()
			cooldown = true
			#look_at(target_enemy.global_position)

func _on_timer_timeout():
	cooldown = false
