extends Node

signal stats_updated

# Cena da Primeira Arma Ativa
const BULLET_1_SCENE: PackedScene = preload("res://scenes/game/bullet.tscn")
const BULLET_2_SCENE: PackedScene = preload("res://scenes/game/bullet_2.tscn")
const MAX_LEVEL: int = 5

# Trilhas de upgrade disponíveis
enum UpgradeTrack { ACTIVE_WEAPON_1, ACTIVE_WEAPON_2}
# IDs dos projéteis (casam com o que o turret.gd espera em current_bullet)
enum WeaponId { BULLET_1 = 1, BULLET_2 = 2 }

# Nível atual da Arma Ativa
var active_weapon_1_level: int = 0
var active_weapon_2_level: int = 0


# ---------------------------
# APLICAÇÃO DE UPGRADE
# ---------------------------
func apply_upgrade(track: UpgradeTrack) -> void:
	match track:
		UpgradeTrack.ACTIVE_WEAPON_1:
			active_weapon_1_level = min(active_weapon_1_level + 1, MAX_LEVEL)
		UpgradeTrack.ACTIVE_WEAPON_2:
			active_weapon_2_level = min(active_weapon_2_level + 1, MAX_LEVEL)


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


# (Opcional) salvar/carregar só o que importa pra #55
func to_dictionary() -> Dictionary:
	return {
		"active_weapon_1_level": active_weapon_1_level,
		"active_weapon_2_level": active_weapon_2_level,
	}


func from_dictionary(data: Dictionary) -> void:
	active_weapon_1_level = int(data.get("active_weapon_1_level", active_weapon_1_level))
	active_weapon_2_level = int(data.get("active_weapon_2_level", active_weapon_2_level))
	stats_updated.emit()


func reset() -> void:
	active_weapon_1_level = 0
	active_weapon_2_level = 0
	stats_updated.emit()
