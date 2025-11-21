extends Control

@onready var upgrade_card_container: HBoxContainer = $UpgradeCardContainer

signal closed(track: int)


## Configura o modo de processamento para sempre ativo (mesmo durante pausa)
## e conecta o sinal "chosen" de cada carta de upgrade à função de callback.
## Em seguida, preenche o container com três upgrades aleatórios.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for node in upgrade_card_container.get_children():
		if node.has_signal("chosen"):
			node.chosen.connect(_on_card_chosen)
	_populate_random(3)


## Callback acionado quando uma carta é escolhida.
## Identifica qual trilha de upgrade foi selecionada e atualiza a arma ativa do jogador
## chamando o método set_selected_weapon() correspondente. 
## Após aplicar o upgrade, emite o sinal "closed" indicando que o menu pode ser fechado.
func _on_card_chosen(track: int) -> void:
	if is_instance_valid(Singleton.player):
		match track:
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1:
				Singleton.player.set_selected_weapon(PlayerUpgrades.WeaponId.BULLET_1)
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2:
				Singleton.player.set_selected_weapon(PlayerUpgrades.WeaponId.BULLET_2)
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3:
				Singleton.player.set_selected_weapon(PlayerUpgrades.WeaponId.BULLET_3)
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4:
				Singleton.player.set_selected_weapon(PlayerUpgrades.WeaponId.BULLET_4)
	closed.emit(track)


## Popula o container de cartas com uma quantidade específica de upgrades aleatórios.
## Embaralha as opções de upgrades disponíveis e atribui um tipo de upgrade
## a cada carta visível no container, respeitando o limite definido por "count".
func _populate_random(count : int = 3) -> void:
	var all_weapons := [
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED,
	]
	all_weapons.shuffle()
	var cards := upgrade_card_container.get_children()
	for i in range(min(count, cards.size())):
		cards[i].upgrade = all_weapons[i]
