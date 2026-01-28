class_name SlotUI extends Control

## Nível máximo exibido (quantidade máxima de levels preenchidos).
@export var max_levels: int = 5

## Container que contém os pontos de nível.
@onready var weapon_levels: HBoxContainer = $Root/WeaponLevels
## Ícone exibido dentro do quadrado (arma/passivo).
@onready var weapon_icon: TextureRect = $Root/Border/WeaponIcon

## Se o slot está ocupado/selecionado (ícone e níveis visíveis).
var is_selected: bool = false
## Nível atual, usado para preencher os levels.
var current_level: int = 0


## Estado inicial: slot vazio (sem ícone e sem níveis).
func _ready() -> void:
	weapon_icon.visible = false
	_set_levels_visible(false)
	_set_level(0)


## Marca o slot como selecionado:
## - define a textura do ícone
## - torna ícone e níveis visíveis
## - aplica o nível (preenche quadrados)
func set_selected(texture: Texture2D, level: int) -> void:
	is_selected = true
	weapon_icon.texture = texture
	weapon_icon.visible = true
	_set_levels_visible(true)
	_set_level(level)


## Limpa o slot:
## - remove o ícone
## - esconde níveis
## - reseta nível para 0
func clear_slot() -> void:
	is_selected = false
	weapon_icon.texture = null
	weapon_icon.visible = false
	_set_levels_visible(false)
	_set_level(0)


## Mostra/oculta o container de levels.
func _set_levels_visible(visible_value: bool) -> void:
	weapon_levels.visible = visible_value


## Atualiza o nível atual e preenche os levels:
## - clamp em 0..max_levels
## - para cada ColorRect em `weapon_levels`, liga (branco) até o nível e desliga (alpha 0) os demais
func _set_level(level: int) -> void:
	current_level = level
	if current_level < 0:
		current_level = 0
	if current_level > max_levels:
		current_level = max_levels
	var level_index: int = 0
	for child in weapon_levels.get_children():
		level_index += 1
		if child is ColorRect:
			var level_indicator := child as ColorRect
			if level_index <= current_level:
				# ligado (branco)
				level_indicator.color = Color(1, 1, 1, 1) 
			else:
				 # desligado (invisível)
				level_indicator.color = Color(1, 1, 1, 0)
