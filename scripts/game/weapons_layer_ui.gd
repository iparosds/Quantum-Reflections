class_name WeaponsLayerUI extends Control

# Texturas dos ícones exibidos em cada slot.
@export var weapon_1_texture: Texture2D
@export var weapon_2_texture: Texture2D
@export var weapon_3_texture: Texture2D
@export var weapon_4_texture: Texture2D
@export var shield_texture: Texture2D
@export var speed_texture: Texture2D

# Containers na cena que possuem os SlotUI.
@onready var weapons_row: HBoxContainer = $MarginContainer/VBoxContainer/WeaponsRow
@onready var passives_row: HBoxContainer = $MarginContainer/VBoxContainer/PassivesRow

# Cache dos SlotUI para acesso por índice.
var weapon_slots: Array[SlotUI] = []
var passive_slots: Array[SlotUI] = []


func _ready() -> void:
	# Monta cache, conecta sinal do PlayerUpgrades e faz o primeiro refresh da UI.
	_cache_slots()
	_bind_signals()
	_refresh_weapons()
	_refresh_passives()


## Coleta apenas filhos do tipo SlotUI (ignora outros nós decorativos).
func _cache_slots() -> void:
	weapon_slots.clear()
	for child in weapons_row.get_children():
		if child is SlotUI:
			weapon_slots.append(child)
	passive_slots.clear()
	for child in passives_row.get_children():
		if child is SlotUI:
			passive_slots.append(child)


## Conecta ao sinal global para atualizar a UI sempre que um upgrade mudar.
func _bind_signals() -> void:
	if get_tree().root.has_node("PlayerUpgrades"):
		if not PlayerUpgrades.stats_updated.is_connected(_on_upgrades_changed):
			PlayerUpgrades.stats_updated.connect(_on_upgrades_changed)


## Recria o estado visual de armas e passivos com base nos níveis atuais.
func _on_upgrades_changed() -> void:
	_refresh_weapons()
	_refresh_passives()


## Lê níveis das armas ativas no PlayerUpgrades e aplica no slot equivalente.
func _refresh_weapons() -> void:
	var weapon1 := _get_upgrade_level("active_weapon_1_level", 0)
	var weapon2 := _get_upgrade_level("active_weapon_2_level", 0)
	var weapon3 := _get_upgrade_level("active_weapon_3_level", 0)
	var weapon4 := _get_upgrade_level("active_weapon_4_level", 0)
	_set_slot_from_level(0, weapon_1_texture, weapon1)
	_set_slot_from_level(1, weapon_2_texture, weapon2)
	_set_slot_from_level(2, weapon_3_texture, weapon3)
	_set_slot_from_level(3, weapon_4_texture, weapon4)


## Lê níveis dos passivos no PlayerUpgrades e aplica no slot equivalente.
func _refresh_passives() -> void:
	var shield_level := _get_upgrade_level("passive_shield_level", 0)
	var speed_level := _get_upgrade_level("passive_speed_level", 0)
	_set_passive_slot_from_level(0, shield_texture, shield_level)
	_set_passive_slot_from_level(1, speed_texture, speed_level)


## Atualiza um slot de arma:
	# - Se level > 0: exibe ícone e preenche níveis
	# - Caso contrário: limpa o slot
func _set_slot_from_level(index: int, texture: Texture2D, level: int) -> void:
	if index < 0:
		return
	if index >= weapon_slots.size():
		return
	if level > 0 and texture != null:
		weapon_slots[index].set_selected(texture, level)
	else:
		weapon_slots[index].clear_slot()


## Atualiza um slot de passivos:
	# - Se level > 0: exibe ícone e preenche níveis
	# - Caso contrário: limpa o slot
func _set_passive_slot_from_level(index: int, texture: Texture2D, level: int) -> void:
	if index < 0:
		return
	if index >= passive_slots.size():
		return
	if level > 0 and texture != null:
		passive_slots[index].set_selected(texture, level)
	else:
		passive_slots[index].clear_slot()


## Lê dinamicamente os campos de upgrades do PlayerUpgrades (ex.: "active_weapon_1_level").
# Retorna int (aceita int/float) ou default_level caso não exista/esteja inválido, por segurança.
func _get_upgrade_level(upgrade_field_name: String, default_level: int) -> int:
	if not get_tree().root.has_node("PlayerUpgrades"):
		return default_level
	var upgrade_default_level = PlayerUpgrades.get(upgrade_field_name)
	if typeof(upgrade_default_level) == TYPE_INT:
		return int(upgrade_default_level)
	if typeof(upgrade_default_level) == TYPE_FLOAT:
		return int(upgrade_default_level)
	return default_level
