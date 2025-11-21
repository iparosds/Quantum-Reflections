extends Panel

## Tipo de upgrade associado a esta carta (arma, escudo, velocidade etc.).
## Ao ser alterado, chama automaticamente _refresh() para atualizar a exibição.
@export var upgrade: PlayerUpgrades.UpgradeTrack = PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1:
	set(value):
		upgrade = value
		_refresh()
@export var title := ""
@export var icon: Texture2D

@onready var texture_rect: TextureRect = $VBoxContainer/MarginContainer/TextureRect
@onready var label: Label = $VBoxContainer/MarginContainer2/Label

var weapon_1_image : Texture2D = load("res://assets/sprites/levels_sprites/projectile.png")
var weapon_2_image : Texture2D = load("res://assets/sprites/levels_sprites/turret.png")
var weapon_3_image : Texture2D = load("res://assets/sprites/icons/mine-image.png")
var weapon_4_image : Texture2D = load("res://assets/sprites/icons/drone-image.png")
var shield_image : Texture2D = load("res://assets/sprites/icons/shield-minimalistic-svgrepo-com (1).svg")
var speed_image : Texture2D = load("res://assets/sprites/icons/speed-skiing-svgrepo-com.svg")

signal chosen(track: int)


## Inicializa a carta chamando _refresh() para configurar ícone e texto.
## Define o cursor de mão ao passar o mouse e desativa o processamento de input não tratado.
func _ready() -> void:
	_refresh()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_process_unhandled_input(false)


## Atualiza o texto e a imagem exibidos na carta conforme o tipo de upgrade.
## Usa os métodos auxiliares _set_name_for() e _set_image_for().
func _refresh() -> void:
	if is_instance_valid(label):
		label.text = title if title != "" else _set_name_for(upgrade)
	if is_instance_valid(texture_rect):
		texture_rect.texture = _set_image_for(upgrade)


## Retorna o nome descritivo do upgrade conforme o tipo especificado.
## Utilizado quando a carta não possui um título personalizado.
func _set_name_for(upgrade_label: int) -> String:
	match upgrade_label:
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1: return "Weapon 1 +50% Damage"
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2: return "Weapon 2 +50% Damage"
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3: return "Mine"
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4: return "Drone"
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD:  return "+5% Shield"
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED:   return "+5% Speed"
		_: return "Upgrade"


## Retorna a imagem correspondente ao tipo de upgrade informado.
## Caso o tipo não exista, retorna null.
func _set_image_for(upgrade_image: int) -> Texture2D:
	match upgrade_image:
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1: return weapon_1_image
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2: return weapon_2_image
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3: return weapon_3_image
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4: return weapon_4_image
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD:  return shield_image
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED:   return speed_image
		_: return null


## Detecta cliques do mouse na carta.
## Se o botão esquerdo for pressionado, aplica o upgrade correspondente
## e emite o sinal "chosen" informando qual tipo de upgrade foi selecionado.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		PlayerUpgrades.apply_upgrade(upgrade)
		chosen.emit(upgrade)
