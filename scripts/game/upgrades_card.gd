class_name UpgradesCard extends Panel

@onready var texture_rect: TextureRect = $VBoxContainer/MarginContainer/TextureRect
@onready var label: Label = $VBoxContainer/MarginContainer2/Label

signal upgrade_selected

@export var icon : CompressedTexture2D
@export var description : String
@export var upgrade : PlayerUpgrades.UpgradeTrack


func _ready() -> void:
	Singleton.upgrades_card = self
	texture_rect.texture = icon
	label.text = description


func apply_upgrade() -> void:
	var upgradeNumber = int(description.split(" ")[0].replace("+", "").replace("%", ""))
	PlayerUpgrades.apply_upgrade(upgrade)
	
	upgrade_selected.emit()
