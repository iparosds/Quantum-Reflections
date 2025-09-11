extends Node

signal stats_updated

# Cena da Primeira Arma Ativa
const BULLET_1_SCENE: PackedScene = preload("res://scenes/game/bullet.tscn")
const BULLET_2_SCENE: PackedScene = preload("res://scenes/game/bullet_2.tscn")
const MAX_LEVEL: int = 5

# Trilhas de upgrade disponíveis
enum UpgradeTrack { ACTIVE_WEAPON_1, ACTIVE_WEAPON_2, PASSIVE_SHIELD, PASSIVE_SPEED}
# IDs dos projéteis (casam com o que o turret.gd espera em current_bullet)
enum WeaponId { BULLET_1 = 1, BULLET_2 = 2 }

# Bases
var base_health: float = 100.0
var base_damage_rate: float = 500.0
var base_max_acceleration: float = 1000.0

# Nível atual da Arma Ativa
var active_weapon_1_level: int = 0
var active_weapon_2_level: int = 0
var passive_shield_level: int = 0
var passive_speed_level: int = 0


# ---------------------------
# APLICAÇÃO DE UPGRADE
# ---------------------------
func apply_upgrade(track: UpgradeTrack) -> void:
	match track:
		UpgradeTrack.ACTIVE_WEAPON_1:
			active_weapon_1_level = min(active_weapon_1_level + 1, MAX_LEVEL)
		UpgradeTrack.ACTIVE_WEAPON_2:
			active_weapon_2_level = min(active_weapon_2_level + 1, MAX_LEVEL)
		UpgradeTrack.PASSIVE_SHIELD:
			passive_shield_level = min(passive_shield_level + 1, MAX_LEVEL)
		UpgradeTrack.PASSIVE_SPEED:
			passive_speed_level = min(passive_speed_level + 1, MAX_LEVEL)
	
	stats_updated.emit()


# Multiplicador de dano para o slot (1 → Bullet.tscn, 2 → Bullet_2.tscn)
func get_active_damage_multiplier(slot: int) -> float:
	var level: int
	if slot == 1:
		level = active_weapon_1_level
	else:
		level = active_weapon_2_level

	if level <= 0:
		return 1.0
	# nível 1 = 1.0x; cada nível adicional soma +0.5 (máx 3.0x no nível 5)
	return 1.0 + 0.5 * float(level - 1)


# Versão por "id" do projétil (1 ou 2)
func get_damage_multiplier_for_weapon_id(weapon_id: int) -> float:
	if weapon_id == WeaponId.BULLET_1:
		return get_active_damage_multiplier(1)
	elif weapon_id == WeaponId.BULLET_2:
		return get_active_damage_multiplier(2)
	else:
		return 1.0


# Cena do projétil para cada slot
func get_weapon_scene_for_slot(slot: int) -> PackedScene:
	if slot == 1:
		return BULLET_1_SCENE
	else:
		return BULLET_2_SCENE


# Cena do projétil por id (1/2)
func get_weapon_scene_for_id(weapon_id: int) -> PackedScene:
	if weapon_id == WeaponId.BULLET_1:
		return BULLET_1_SCENE
	elif weapon_id == WeaponId.BULLET_2:
		return BULLET_2_SCENE
	else:
		return BULLET_1_SCENE  # fallback


# PASSIVAS (bônus percentual 0.0 .. 0.25)
func get_shield_bonus() -> float:
	return min(passive_shield_level * 0.05, 0.25)


func get_effective_health() -> float:
	return base_health * (1.0 + get_shield_bonus())


func get_speed_bonus() -> float:
	return min(passive_speed_level * 0.05, 0.25)


# Valores efetivos (se quiser aplicar direto no Player)
func get_effective_max_acceleration() -> float:
	return base_max_acceleration * (1.0 + get_speed_bonus())


# Mantido para compatibilidade
func get_effective_damage_rate_for(slot: int) -> float:
	return base_damage_rate * get_active_damage_multiplier(slot)


# ---------------------------
# SERIALIZAÇÃO (save/load)
# ---------------------------
func to_dictionary() -> Dictionary:
	return {
		"active_weapon_1_level": active_weapon_1_level,
		"active_weapon_2_level": active_weapon_2_level,
		"passive_shield_level": passive_shield_level,
		"passive_speed_level": passive_speed_level,
		"base_health": base_health,
		"base_damage_rate": base_damage_rate,
		"base_max_acceleration": base_max_acceleration,
	}


func from_dictionary(data: Dictionary) -> void:
	active_weapon_1_level = int(data.get("active_weapon_1_level", active_weapon_1_level))
	active_weapon_2_level = int(data.get("active_weapon_2_level", active_weapon_2_level))
	passive_shield_level = int(data.get("passive_shield_level", passive_shield_level))
	passive_speed_level = int(data.get("passive_speed_level", passive_speed_level))
	base_health = float(data.get("base_health", base_health))
	base_damage_rate = float(data.get("base_damage_rate", base_damage_rate))
	base_max_acceleration = float(data.get("base_max_acceleration", base_max_acceleration))
	
	stats_updated.emit()


func reset() -> void:
	active_weapon_1_level = 0
	active_weapon_2_level = 0
	passive_shield_level = 0
	passive_speed_level = 0
	
	stats_updated.emit()
