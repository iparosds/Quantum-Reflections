extends Panel

@export var upgrade: PlayerUpgrades.UpgradeTrack = PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1
@export var title := ""
@export var icon: Texture2D

@onready var texture_rect: TextureRect = $VBoxContainer/MarginContainer/TextureRect
@onready var label: Label = $VBoxContainer/MarginContainer2/Label

signal chosen(track: int)


func _ready() -> void:
	_refresh()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	set_process_unhandled_input(false)


func _refresh() -> void:
	if is_instance_valid(label):
		label.text = title if title != "" else _name_for(upgrade)
	if is_instance_valid(texture_rect):
		texture_rect.texture = icon


func _name_for(t: int) -> String:
	match t:
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1: return "Turret 1 (dano +)"
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2: return "Turret 2 (dano +)"
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD:  return "Escudo (vida +)"
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED:   return "Velocidade (cap +)"
		_: return "Upgrade"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		PlayerUpgrades.apply_upgrade(upgrade)
		chosen.emit(upgrade)
