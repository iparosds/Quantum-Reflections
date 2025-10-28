extends Control

@onready var upgrade_card_container: HBoxContainer = $UpgradeCardContainer

signal closed(track: int)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for node in upgrade_card_container.get_children():
		if node.has_signal("chosen"):
			node.chosen.connect(_on_card_chosen)
	_populate_random(3)


func _on_card_chosen(track: int) -> void:
	if is_instance_valid(Singleton.player):
		match track:
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1:
				Singleton.player.set_selected_weapon(PlayerUpgrades.WeaponId.BULLET_1)
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2:
				Singleton.player.set_selected_weapon(PlayerUpgrades.WeaponId.BULLET_2)
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3:
				Singleton.player.set_selected_weapon(PlayerUpgrades.WeaponId.BULLET_3)
	closed.emit(track)


func _populate_random(count := 3) -> void:
	var all_weapons := [
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED,
	]
	all_weapons.shuffle()
	var cards := upgrade_card_container.get_children()
	for i in range(min(count, cards.size())):
		cards[i].upgrade = all_weapons[i]
