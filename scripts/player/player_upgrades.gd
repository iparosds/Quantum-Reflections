extends Node

signal stats_updated

const MAX_LEVEL: int = 5

# Cena da Primeira Arma Ativa (bullet 1)
const BULLET_1_SCENE: PackedScene = preload("res://scenes/game/bullet.tscn")

# Nível atual da Arma Ativa 1 (0 = não escolhida)
var active_weapon_1_level: int = 0

# Sobe 1 nível na Arma Ativa 1
func apply_upgrade_active_weapon_1() -> void:
	active_weapon_1_level = min(active_weapon_1_level + 1, MAX_LEVEL)
	stats_updated.emit()

# Mantém a assinatura usada pela Turret:
# retorna o multiplicador de dano; só dá suporte ao slot 1.
func get_active_damage_multiplier(slot: int) -> float:
	if slot != 1:
		return 1.0
	var level := active_weapon_1_level
	if level <= 0:
		return 1.0
	return 1.0 + 0.5 * float(level - 1)

# (Opcional) salvar/carregar só o que importa pra #55
func to_dictionary() -> Dictionary:
	return {"active_weapon_1_level": active_weapon_1_level}

func from_dictionary(data: Dictionary) -> void:
	active_weapon_1_level = int(data.get("active_weapon_1_level", active_weapon_1_level))
	stats_updated.emit()
