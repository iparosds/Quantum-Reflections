class_name PlayerStats extends Node

signal stats_updated

enum UpgradeTrack { ACTIVE_WEAPON_1, ACTIVE_WEAPON_2, PASSIVE_SHIELD, PASSIVE_SPEED }

const MAX_LEVEL : int = 5

# Bases (podem ser lidas por quem aplica os efeitos no Player)
var base_health: float = 100.0
var base_damage_rate: float = 500.0
var base_max_acceleration: float = 1000.0

# Níveis atuais de cada trilha (0 = não selecionado ainda)
var active_weapon_1_level: int = 0
var active_weapon_2_level: int = 0
var passive_shield_level: int = 0
var passive_speed_level: int = 0


func _ready() -> void:
	Singleton.player_stats = self


# ---------------------------
# APLICAÇÃO DE UPGRADE
# ---------------------------
func apply_upgrade(track: UpgradeTrack) -> void:
	# Incrementa 1 nível na trilha escolhida (até MAX_LEVEL)
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

# ---------------------------
# CONSULTAS (DERIVADOS)
# ---------------------------

# ATIVAS: multiplica o dano
func get_active_damage_multiplier(slot: int) -> float:
	var level = (slot == 1) if active_weapon_1_level else active_weapon_2_level
	if level <= 0:
		return 1.0
	
	# nível 1 = 1.0x; cada nível adicional soma +0.5
	return 1.0 + 0.5 * float(level - 1)


# PASSIVAS: retorna bônus percentual (0.0 .. 0.25) de escudo/velocidade
func get_shield_bonus() -> float:
	return min(passive_shield_level * 0.05, 0.25)


func get_speed_bonus() -> float:
	return min(passive_speed_level * 0.05, 0.25)


# Valores efetivos
func get_effective_max_acceleration() -> float:
	return base_max_acceleration * (1.0 + get_speed_bonus())


func get_effective_health() -> float:
	return base_health * (1.0 + get_shield_bonus())


# Dano efetivo por trilha ativa (multiplica o "base_damage_rate")
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


# Utilitario para reload
func reset() -> void:
	active_weapon_1_level = 0
	active_weapon_2_level = 0
	passive_shield_level = 0
	passive_speed_level = 0
	stats_updated.emit()
