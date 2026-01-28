## Global
extends Node

signal stats_updated

const BULLET_1_SCENE: PackedScene = preload("res://scenes/game/bullet.tscn")
const BULLET_2_SCENE: PackedScene = preload("res://scenes/game/bullet_2.tscn")
const BULLET_3_SCENE: PackedScene = preload("res://scenes/game/bullet_3.tscn")
const BULLET_4_SCENE: PackedScene = preload("res://scenes/game/bullet_4.tscn")

const MAX_LEVEL: int = 5

# Trilhas de upgrade disponíveis
enum UpgradeTrack { 
	ACTIVE_WEAPON_1, ACTIVE_WEAPON_2, 
	ACTIVE_WEAPON_3, ACTIVE_WEAPON_4, 
	PASSIVE_SHIELD, PASSIVE_SPEED
}
# IDs dos projéteis
enum WeaponId { BULLET_1 = 1, BULLET_2 = 2, BULLET_3 = 3, BULLET_4 = 4 }

# Bases
var base_health: float = 100.0
var base_damage_rate: float = 500.0
var base_max_acceleration: float = 1000.0

# Nível atual da Arma Ativa
var active_weapon_1_level: int = 1
var active_weapon_2_level: int = 0
var active_weapon_3_level: int = 0
var active_weapon_4_level: int = 0
var passive_shield_level: int = 0
var passive_speed_level: int = 0


## Incrementa o nível da trilha de upgrade especificada, 
## limitado ao valor máximo, e emite o sinal stats_updated.
func apply_upgrade(track: UpgradeTrack) -> void:
	match track:
		UpgradeTrack.ACTIVE_WEAPON_1:
			active_weapon_1_level = min(active_weapon_1_level + 1, MAX_LEVEL)
		UpgradeTrack.ACTIVE_WEAPON_2:
			active_weapon_2_level = min(active_weapon_2_level + 1, MAX_LEVEL)
		UpgradeTrack.ACTIVE_WEAPON_3:
			active_weapon_3_level = min(active_weapon_3_level + 1, MAX_LEVEL)
		UpgradeTrack.ACTIVE_WEAPON_4:
			active_weapon_4_level = min(active_weapon_4_level + 1, MAX_LEVEL)
		UpgradeTrack.PASSIVE_SHIELD:
			passive_shield_level = min(passive_shield_level + 1, MAX_LEVEL)
		UpgradeTrack.PASSIVE_SPEED:
			passive_speed_level = min(passive_speed_level + 1, MAX_LEVEL)
	stats_updated.emit()


## Retorna o multiplicador de dano baseado no ID da arma.
## Cada nível adiciona +0.5x ao dano, com limite de 3.0x no nível 5.
## A BULLET_2 possui penalidade de 0.7x.
func get_damage_multiplier_for_weapon_id(weapon_id: int) -> float:
	var level: int
	if weapon_id == WeaponId.BULLET_1:
		level = active_weapon_1_level
	elif weapon_id == WeaponId.BULLET_2:
		level = active_weapon_2_level
	elif weapon_id == WeaponId.BULLET_3:
		level = active_weapon_3_level
	elif weapon_id == WeaponId.BULLET_4:
		level = active_weapon_4_level
	else:
		return 1.0
	if level <= 0:
		return 1.0
	var mult = min(1.0 + 0.5 * level, 3.0)
	if weapon_id == WeaponId.BULLET_2:
		mult *= 0.7
	return mult

# PASSIVAS (bônus percentual 0.0 .. 0.25)

## Retorna o bônus percentual de escudo baseado no nível atual, limitado a 25%.
func get_shield_bonus() -> float:
	return min(passive_shield_level * 0.05, 0.25)


## Retorna o valor total de saúde efetiva com o bônus de escudo aplicado.
func get_effective_health() -> float:
	return base_health * (1.0 + get_shield_bonus())


## Retorna o bônus percentual de velocidade baseado no nível atual, limitado a 25%.
func get_speed_bonus() -> float:
	return min(passive_speed_level * 0.05, 0.25)


## Retorna a aceleração máxima efetiva, aplicando o bônus de velocidade.
func get_effective_max_acceleration() -> float:
	return base_max_acceleration * (1.0 + get_speed_bonus())


## Reseta todos os níveis de upgrades (ativos e passivos) para 0 e emite o sinal
## stats_updated.
func reset() -> void:
	active_weapon_1_level = 1
	active_weapon_2_level = 0
	active_weapon_3_level = 0
	active_weapon_4_level = 0
	passive_shield_level = 0
	passive_speed_level = 0
	stats_updated.emit()
