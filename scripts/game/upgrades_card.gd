extends Panel

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
var shield_image : Texture2D = load("res://assets/sprites/icons/shield-minimalistic-svgrepo-com (1).svg")
var speed_image : Texture2D = load("res://assets/sprites/icons/speed-skiing-svgrepo-com.svg")

signal chosen(track: int)


func _ready() -> void:
	_refresh()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	set_process_unhandled_input(false)


func _refresh() -> void:
	if is_instance_valid(label):
		label.text = title if title != "" else _set_name_for(upgrade)
	if is_instance_valid(texture_rect):
		texture_rect.texture = _set_image_for(upgrade)


func _set_name_for(upgrade_label: int) -> String:
	match upgrade_label:
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1: return "Weapon 1 +50% Damage"
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2: return "Weapon 2 +50% Damage"
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD:  return "+5% Shield"
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED:   return "+5% Speed"
		_: return "Upgrade"


func _set_image_for(upgrade_image: int) -> Texture2D:
	match upgrade_image:
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1: return weapon_1_image
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2: return weapon_2_image
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD:  return shield_image
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED:   return speed_image
		_: return null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		PlayerUpgrades.apply_upgrade(upgrade)
		chosen.emit(upgrade)
