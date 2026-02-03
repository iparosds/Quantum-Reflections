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


## Converte o ID da arma (WeaponId) para o "track" correspondente de upgrade (UpgradeTrack).
## Retorna -1 se o weapon_id não for reconhecido (sem track válido / arma inexistente).
func _weapon_id_to_track(weapon_id: int) -> int:
	match weapon_id:
		PlayerUpgrades.WeaponId.BULLET_1: return PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1
		PlayerUpgrades.WeaponId.BULLET_2: return PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2
		PlayerUpgrades.WeaponId.BULLET_3: return PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3
		PlayerUpgrades.WeaponId.BULLET_4: return PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4
		_: return -1


## Retorna o nível atual de um track de upgrade consultando os valores armazenados em PlayerUpgrades.
## Para tracks desconhecidos, retorna 0 (trata como "ainda não evoluído").
func _get_level_for_track(track: int) -> int:
	match track:
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1: return PlayerUpgrades.active_weapon_1_level
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2: return PlayerUpgrades.active_weapon_2_level
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3: return PlayerUpgrades.active_weapon_3_level
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4: return PlayerUpgrades.active_weapon_4_level
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD:  return PlayerUpgrades.passive_shield_level
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED:   return PlayerUpgrades.passive_speed_level
		_: return 0


## Preenche as cartas de upgrade exibidas na UI com picks aleatórios gerados por _build_random_upgrade_picks().
## Mostra as primeiras N cartas (até "count") e oculta as cartas extras, evitando acessar índices inválidos.
func _populate_random(count: int = 3) -> void:
	var cards := upgrade_card_container.get_children()
	if cards.is_empty():
		return
	var upgrade_picks := _build_random_upgrade_picks(count)
	for card in range(cards.size()):
		if card < upgrade_picks.size():
			cards[card].visible = true
			cards[card].upgrade = upgrade_picks[card]
		else:
			cards[card].visible = false


## Monta uma lista de "tracks" de upgrade para oferecer ao jogador:
## 1) Prioriza incluir a arma atualmente selecionada se ela existir e ainda não estiver no nível MAX.
## 2) Tenta garantir uma "arma nova" (track com nível 0); se não houver, usa fallback para arma não-MAX
##    e, se todas as armas estiverem MAX, libera qualquer arma.
## 3) Completa o restante com upgrades aleatórios não-MAX (inclui passivas); se não houver, libera MAX,
##    sempre evitando repetir tracks dentro dos picks.
func _build_random_upgrade_picks(count: int = 3) -> Array[int]:
	# Lista completa de "tracks" que podem aparecer (armas + passivas).
	var all_tracks := [
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD,
		PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED,
	]
	# Lista apenas das armas ativas (tracks 1..4).
	var weapon_tracks := [
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_3,
		PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_4,
	]
	# Picks finais (tracks escolhidos).
	var picks: Array[int] = []
	# Helper: um track está "MAX" se seu nível atingiu o máximo global.
	var is_track_maxed := func(track: int) -> bool:
		return _get_level_for_track(track) >= PlayerUpgrades.MAX_LEVEL
	# Descobre o track da arma atualmente selecionada.
	# Se o player ainda não existir (ou não for válido), fica -1.
	var current_weapon_track: int = -1
	if is_instance_valid(Singleton.player):
		current_weapon_track = _weapon_id_to_track(Singleton.player.selected_weapon_id)
	# Helper: retorna true se TODAS as armas ativas estão MAX.
	# Isso define se o código pode "repetir armas maxadas" quando não há alternativa.
	var are_all_weapons_maxed := func() -> bool:
		for weapon_track in weapon_tracks:
			if not is_track_maxed.call(weapon_track):
				return false
		return true
	var can_repeat_maxed_weapons = are_all_weapons_maxed.call()

	# Upgrade da arma atual, se existir e não estiver MAX
	if picks.size() < count and current_weapon_track != -1 and not is_track_maxed.call(current_weapon_track):
		picks.append(current_weapon_track)
	
	# Tentar oferecer arma nova (nível == 0)
	# - Tenta arma nova (nível 0), exceto a arma atual.
	# - Se não houver nova e ainda existir arma não-MAX, pega qualquer arma não-MAX (exceto a atual).
	# - Se todas as armas estiverem MAX, libera qualquer arma (exceto a atual).
	if picks.size() < count:
		var weapon_candidates: Array[int] = []
		# Arma nova (level == 0), sem repetir a atual.
		for weapon_track in weapon_tracks:
			if weapon_track == current_weapon_track:
				continue
			if _get_level_for_track(weapon_track) == 0:
				if can_repeat_maxed_weapons or not is_track_maxed.call(weapon_track):
					weapon_candidates.append(weapon_track)
		# Fallback: qualquer arma não-MAX (sem repetir a atual),
		# - Apenas se ainda nao estiver no estado "todas as armas MAX".
		if weapon_candidates.is_empty() and not can_repeat_maxed_weapons:
			for weapon_track in weapon_tracks:
				if weapon_track == current_weapon_track:
					continue
				if not is_track_maxed.call(weapon_track):
					weapon_candidates.append(weapon_track)
		# Se todas as armas estiverem MAX, libera qualquer arma (exceto a atual).
		if weapon_candidates.is_empty() and can_repeat_maxed_weapons:
			for weapon_track in weapon_tracks:
				if weapon_track == current_weapon_track:
					continue
				weapon_candidates.append(weapon_track)
		# Escolhe aleatoriamente 1 candidato e adiciona (sem duplicar).
		if not weapon_candidates.is_empty():
			weapon_candidates.shuffle()
			var chosen_weapon_track := weapon_candidates[0]
			if not picks.has(chosen_weapon_track):
				picks.append(chosen_weapon_track)

	# Completa o restante aleatoriamente
	# - Primeiro tenta apenas tracks não-MAX (armas + passivas), sem repetir picks.
	# - Se não existir mais nenhum não-MAX, libera qualquer track restante (mesmo MAX), sem repetir.
	if picks.size() < count:
		var pool: Array[int] = []
		# Pool com tracks não-MAX.
		for track in all_tracks:
			if picks.has(track):
				continue
			if not is_track_maxed.call(track):
				pool.append(track)
		# Se acabou, libera qualquer track restante.
		if pool.is_empty():
			for track in all_tracks:
				if not picks.has(track):
					pool.append(track)
		# Embaralha e vai puxando os cards até completar.
		pool.shuffle()
		while picks.size() < count and not pool.is_empty():
			picks.append(pool.pop_front())
	
	return picks
