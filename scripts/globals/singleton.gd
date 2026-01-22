class_name GlobalSingleton extends Node2D

@onready var closest_enemy := find_closest_enemy()

const SETTINGS_ICON := preload("res://scenes/globals/settings_icon.tscn")
const TUTORIAL_DIALOGUE := preload("res://dialogues/tutorial_dialogue.dialogue")

var gui_manager: GuiManager
var level_manager: LevelManager
var level : Level
var player : Player
var settings_icon : SettingsIcon
var quantum := false
var closest_distance := 1000
var current_level: String
var current_level_path: String
var score = 0
var god_mode = false
var quantum_roll = 0
var portal_timer = 150.0
var _tutorial_running := false
var active_balloons: Array = []
var tutorial_unlocked: bool = false
var skip_tutorial: bool = false

# Dicionário com os níveis disponíveis e seus caminhos
var levels: Dictionary = {
	"tutorial": {
		"label": "Tutorial (under construction)",
		"url": "tutorial.tscn",
		"unblock": "_tutorial",
	},
	"level01" : {
		"label": "Level 01",
		"url": "level_01.tscn",
		"unblock": "_level01",
	},
}

signal action_pressed(action_name)


## Inicia o jogo carregando o nível selecionado
func start_game() -> void:
	get_tree().paused = false
	if gui_manager:
		gui_manager.main_menu_layer.visible = false
		gui_manager.game_hud_layer.visible = true
	goto_level(current_level_path)
	
	if current_level == "level_01" or current_level_path.ends_with("level_01.tscn") and not skip_tutorial:
		start_tutorial()


## Inicia o tutorial do jogo.
func start_tutorial() -> void:
	if _tutorial_running:
		return
	_tutorial_running = true
	var dialogue_balloon = DialogueManager.show_dialogue_balloon(TUTORIAL_DIALOGUE, "start")
	_register_balloon(dialogue_balloon)
	if dialogue_balloon and dialogue_balloon.has_method("set"):
		dialogue_balloon.advance_after_blocking_mutation = true


## Aguarda até que o jogador pressione a ação especificada.
func _wait_action(action_name) -> void:
	var action = await action_pressed
	if action == action_name:
		return
	await _wait_action(action_name)


## Aguarda até que o jogador pressione qualquer ação.
func _wait_any_action(action_names: Array) -> void:
	var action = await action_pressed
	if action_names.has(action):
		return
	await _wait_any_action(action_names)


## Captura entradas globais do jogador e emite o sinal `action_pressed`.
func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		for action in InputMap.get_actions():
			if event.is_action_pressed(action):
				action_pressed.emit(String(action))


## Registra um balão de diálogo aberto para controle/fechamento posterior.
func _register_balloon(balloon: Node) -> void:
	if not is_instance_valid(balloon):
		return
	active_balloons.append(balloon)
	if not balloon.is_in_group("dialogue_balloon"):
		balloon.add_to_group("dialogue_balloon")
	var reference := balloon
	balloon.tree_exited.connect(func():
		active_balloons.erase(reference))


## Fecha todos os balões de diálogo atualmente ativos.
func _close_all_dialogue_balloons() -> void:
	for balloon in get_tree().get_nodes_in_group("dialogue_balloon"):
		if is_instance_valid(balloon):
			balloon.visible = false
	active_balloons.clear()


## Retoma o jogo a partir do estado de pausa.
func continue_game() -> void:
	if not gui_manager.is_paused:
		return
	if is_instance_valid(gui_manager.upgrades_menu):
		var picker := gui_manager.upgrades_menu.get_node_or_null("SelectUpgrades")
		if picker and picker.visible and not gui_manager.upgrades_menu.visible:
			gui_manager.upgrades_menu.visible = true
			gui_manager.is_paused = false
			AudioPlayer.on_pause_exited()
			return
	gui_manager.hide_pause_menu()
	AudioPlayer.on_pause_exited()


## Carrega dados de jogo persistidos.
func load_game() -> void:
	pass


## Salva dados de jogo persistidos.
func save_game() -> void:
	pass


## Abre a tela de Settings a partir do menu ou do jogo.
func open_settings() -> void:
	if gui_manager:
		if gui_manager.is_paused:
			gui_manager.on_settings_back = Callable(gui_manager, "show_pause_overlay_only")
			gui_manager.hide_pause_overlay_only()
		else:
			gui_manager.on_settings_back = Callable(self, "open_main_menu")
		gui_manager.show_settings()



## Abre a tela de Settings a partir do ícone in-game (sem passar pelo overlay do Pause).
func open_settings_from_icon() -> void:
	if not gui_manager:
		return	
	var in_game := is_instance_valid(level) and gui_manager.game_hud_layer.visible
	if in_game:
		if is_instance_valid(gui_manager.upgrades_menu):
			var picker := gui_manager.upgrades_menu.get_node_or_null("SelectUpgrades")
			if picker and picker.visible and gui_manager.upgrades_menu.visible:
				gui_manager.upgrades_menu.visible = false
		get_tree().paused = true
		gui_manager.is_paused = true
		gui_manager.hide_pause_overlay_only()
		gui_manager.on_settings_back = Callable(self, "continue_game")
		AudioPlayer.on_pause_entered()
	else:
		gui_manager.on_settings_back = Callable(gui_manager, "show_main_menu")
		AudioPlayer._play_menu_music()
	gui_manager.show_settings()


## Abre a tela de créditos.
func open_credits() -> void:
	if gui_manager:
		gui_manager.show_credits()


## Abre o Main Menu.
func open_main_menu() -> void:
	get_tree().paused = true
	_close_all_dialogue_balloons()
	_tutorial_running = false
	if gui_manager:
		if gui_manager.is_paused:
			if gui_manager.has_method("hide_pause_overlay_only"):
				gui_manager.hide_pause_overlay_only()
			else:
				gui_manager.pause_menu_layer.visible = false
	if is_instance_valid(level):
		var old_level := level
		level = null
		player = null
		old_level.queue_free()
		await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("asteroid"):
		if is_instance_valid(node):
			node.queue_free()
	for node in get_tree().get_nodes_in_group("ore"):
		if is_instance_valid(node):
			node.queue_free()
	if gui_manager:
		gui_manager.show_main_menu()
		gui_manager.is_paused = false
		AudioPlayer._play_menu_music()
		_ensure_settings_icon(gui_manager)
	get_tree().paused = false


## Abre a tela de configurações de controle.
func open_controls() -> void:
	if gui_manager:
		gui_manager.show_input_settings()


## Sai do jogo ao ser chamado a partir do menu principal.
func quit_game_from_menu() -> void:
	SaveManager.on_stage_ended(false)
	get_tree().quit()


## Sai do jogo a partir do pause in-game.
func quit_to_desktop_from_game() -> void:
	if not gui_manager.is_paused:
		return
	SaveManager.on_stage_ended(false)
	get_tree().quit()


## Reinicia a partida e restaura o HUD.
func restart_game() -> void:
	if current_level_path == null or current_level_path == "":
		return
	get_tree().paused = true
	_reset_all_bonuses_and_hide_picker()
	for node in get_tree().get_nodes_in_group("ore"):
		if is_instance_valid(node):
			node.queue_free()
	if gui_manager:
		gui_manager.game_over_screen.visible = false
	change_level(current_level_path)
	await get_tree().process_frame
	reset_game_state()
	if gui_manager:
		gui_manager.hud_portal_active.visible = false
		gui_manager.hud_timer_bar.get(
			"theme_override_styles/fill"
		).bg_color = Color(0.129, 0.259, 0.42)
	get_tree().paused = false
	start_game()
	AudioPlayer._play_level_music()
	AudioPlayer.on_level_restart()
	if gui_manager and gui_manager.is_paused:
		gui_manager.hide_pause_menu()


## Reseta variáveis de estado do jogo.
func reset_game_state():
	if gui_manager:
		score = 0
		gui_manager.hud_score_label.text = ""
		gui_manager.hud_xp.value = 0
	if is_instance_valid(player):
		player.set_selected_weapon(1)


## Executa rotina de Game Over e exibe a tela correspondente.
func game_over():
	_close_all_dialogue_balloons()
	_reset_all_bonuses_and_hide_picker()
	if god_mode == false:
		get_tree().paused = true
		gui_manager.game_over_screen.visible = true
		gui_manager.game_over_label.text = "Game over!"
		gui_manager.hud_portal_active.visible = false
		settings_icon.visible = false
		AudioPlayer.stop_music() 
		AudioPlayer._play_menu_music()
		SaveManager.on_stage_ended(false)


## Sempre retorna verdadeiro para liberar o nível de tutorial.
func _tutorial() -> bool:
	return true


## Retorna se o Level 01 está desbloqueado.
func _level01() -> bool:
	return true


## Verifica se um nível está desbloqueado.
func level_is_unlocked(level_id: String) -> bool:
	var level_data: Dictionary = levels.get(level_id, {})
	var method_name: String = str(level_data.get("unblock", ""))
	return method_name != "" and has_method(method_name) and call(method_name)


## Vai para um nível por ID lógico.
func goto_level(level_or_path: String) -> void:
	if level_or_path.begins_with("res://"):
		var file_name := level_or_path.get_file()
		change_level(file_name)
		return
	if level_or_path.ends_with(".tscn"):
		change_level(level_or_path)
		return
	var level_data: Dictionary = levels.get(level_or_path, {})
	if level_data.is_empty():
		push_error("Nível desconhecido: %s" % level_or_path)
		return
	if not level_is_unlocked(level_or_path):
		push_warning("Nível bloqueado: %s" % level_or_path)
		return
	var url: String = str(level_data.get("url", ""))
	if url == "":
		push_error("Nível %s sem 'url' definido" % level_or_path)
		return
	change_level(url)


## Carrega/troca o nível atual.
func change_level(load_level: String) -> void:
	var level_path: String
	if load_level.begins_with("res://"):
		level_path = load_level
	else:
		level_path = "res://levels/%s" % load_level
	var scene_res: PackedScene = ResourceLoader.load(level_path) as PackedScene
	var new_level: Level = scene_res.instantiate() as Level
	if level != null and is_instance_valid(level):
		level.queue_free()
	var parent: Node = level_manager if level_manager != null else get_tree().current_scene
	parent.add_child(new_level)
	level = new_level
	_ensure_settings_icon(level)
	_tutorial_running = false
	current_level_path = level_path
	for id in levels.keys():
		var url := String(levels[id].get("url", ""))
		var path := String(levels[id].get("path", ""))
		if url == load_level or path == level_path:
			current_level = id
			break


## Garante a presença e o parente corretos do ícone de Settings.
##  Se o ícone ainda não existe, instancia-o, define PROCESS_MODE_ALWAYS
##  Se já existe mas está sob outro parente, realiza reparentamento seguro.
##  Garante que o ícone termine visível.
func _ensure_settings_icon(parent: Node) -> void:
	if not is_instance_valid(settings_icon):
		settings_icon = SETTINGS_ICON.instantiate()
		settings_icon.process_mode = Node.PROCESS_MODE_ALWAYS
		parent.add_child(settings_icon)
	else:
		if settings_icon.get_parent() != parent:
			settings_icon.get_parent().remove_child(settings_icon)
			parent.add_child(settings_icon)
	settings_icon.visible = true


## Exibe número animado na tela
func display_number(value: int, text_position: Vector2, text_color: String):
	var number := Label.new()
	number.global_position = text_position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	number.label_settings.font_color = text_color
	number.label_settings.font_size = 16
	call_deferred("add_child", number)
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	# Animações de movimento e desaparecimento
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y - 12, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:y", number.position.y, 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(number, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.5)
	await tween.finished
	number.queue_free()


## Retorna o inimigo mais próximo do player
func find_closest_enemy() -> Object:
	var all_enemy := get_tree().get_nodes_in_group("asteroid")
	for enemy in all_enemy:
		var gun2enemy_distance := position.distance_to(enemy.position)
		if gun2enemy_distance < closest_distance:
			closest_distance = int(gun2enemy_distance)
			closest_enemy = enemy
	return closest_enemy


## Atualiza o inimigo mais próximo.
func _process(_delta: float) -> void:
	closest_enemy = find_closest_enemy()


## Reseta upgrades e esconde o seletor de upgrades (se aberto).
func _reset_all_bonuses_and_hide_picker() -> void:
	if get_tree().root.has_node("PlayerUpgrades"):
		PlayerUpgrades.reset()
	if is_instance_valid(gui_manager) and is_instance_valid(gui_manager.upgrades_menu):
		gui_manager.upgrades_menu.visible = false
		var picker := gui_manager.upgrades_menu.get_node_or_null("SelectUpgrades")
		if picker:
			picker.visible = false
