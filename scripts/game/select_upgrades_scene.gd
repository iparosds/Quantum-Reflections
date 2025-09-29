extends Control

@onready var upgrade_card_container: HBoxContainer = $UpgradeCardContainer

signal closed(track: int)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conecta todos os cards ao handler local
	for node in upgrade_card_container.get_children():
		if node.has_signal("chosen"):
			node.chosen.connect(_on_card_chosen)
	
	_populate_random(3)


func _on_card_chosen(track: int) -> void:
	closed.emit(track)


func _populate_random(count := 3) -> void:
	var all := [
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED,
	]
	all.shuffle()
	var cards := upgrade_card_container.get_children()
	for i in range(min(count, cards.size())):
		cards[i].upgrade = all[i]
