class_name GuiManager extends Node2D

# Constantes que definem grupos de botões.
# Esses grupos são usados para organizar os botões por contexto
# (menu principal, créditos, configurações, etc.).
const MAIN_MENU_BUTTON_GROUP := "main_menu_button"
const CREDITS_BUTTON_GROUP   := "credits_menu_button"
const SETTINGS_BUTTON_GROUP  := "settings_menu_button"
const INPUT_SETTINGS_BUTTON_GROUP := "input_settings_button"
const GAME_OVER_SCREEN_GROUP := "game_over_screen_button"
const PAUSE_MENU_GROUP := "pause_menu_button"
const LEVELS_MENU_GROUP := "level_menu_button"
const STATS_TABLE_GROUP := "stats_table_layer"

# Camadas principais da interface do jogo.
# Cada camada é uma parte visual do HUD ou de menus.
@onready var game_hud_layer: CanvasLayer    = $GameHud
@onready var main_menu_layer: CanvasLayer   = $MainMenu
@onready var credits_layer: CanvasLayer     = $Credits
@onready var settings_layer: CanvasLayer    = $SettingsMenu
@onready var input_settings_layer: CanvasLayer = $InputSettings
@onready var game_over_screen: CanvasLayer  = $GameOverScreen
@onready var pause_menu_layer: CanvasLayer = $PauseMenu
@onready var levels_menu_layer: CanvasLayer = $LevelsMenu
@onready var stats_table_layer: CanvasLayer = $StatsTable

# Sons para interações de interface (hover, seleção, voltar).
@onready var hover_sound_player:  AudioStreamPlayer = $Sounds/HoverSoundPlayer
@onready var select_sound_player: AudioStreamPlayer = $Sounds/SelectSoundPlayer
@onready var back_sound_player:   AudioStreamPlayer = $Sounds/BackSoundPlayer

# Controles dentro do menu de configurações.
# Inclui slider de volume e botão para acessar os controles.
@onready var settings_master_volume_slider: HSlider   = $SettingsMenu/MarginContainer/ButtonsContainer/MasterVolumeSlider
@onready var settings_music_volume_slider: HSlider = $SettingsMenu/MarginContainer/ButtonsContainer/MusicVolumeSlider
@onready var settings_sfx_volume_slider: HSlider = $SettingsMenu/MarginContainer/ButtonsContainer/SFXVolumeSlider
@onready var settings_controls_btn: BaseButton = $SettingsMenu/MarginContainer/ButtonsContainer/ControlsButton

var on_settings_back: Callable = Callable(Singleton, "open_main_menu")
var black_hole_warning_tween: Tween = null
var black_hole_warning_sources : int = 0


# Elementos do HUD principal do jogo.
# Exibem informações como XP, pontuação, tempo, portal ativo e status de god mode.
@onready var hud_xp: ProgressBar = $GameHud/HudXP
@onready var hud_score_label: Label = $GameHud/HudScoreLabel
@onready var hud_timer_bar: ProgressBar = $GameHud/HudTimerBar
@onready var hud_timer_text: Label = $GameHud/HudTimerText
@onready var hud_portal_active: Label = $GameHud/HudPortalActive
@onready var hud_god_mode: Label = $GameHud/HudGodMode
@onready var level_up_notification_label: Label = $GameHud/LevelUpNotificationLabel
@onready var black_hole_warning_label: Label = $GameHud/BlackHoleWarningLabel

# Elementos exibidos na tela de Game Over.
@onready var game_over_label: Label = $GameOverScreen/ColorRect/GameOverLabel
@onready var game_over_restart_button: Button = $GameOverScreen/GameOverRestartButton

# Elementos do Level Menu
@onready var levels_container: VBoxContainer = $LevelsMenu/ScrollContainer/LevelsContainer
@onready var back_to_main_menu_button: Button = $LevelsMenu/VBoxContainer/BackToMainMenuButton

@onready var upgrades_menu: CanvasLayer = $UpgradesMenu

var is_paused: bool = false


# ------------------------------------------------------------
# Inicialização da interface.
# - Configura Singleton
# - Define process_mode para funcionar mesmo em pausa
# - Define o estado inicial de cada camada
# - Toca a música do menu principal
# - Marca botões em grupos para controle posterior
# - Conecta sinais genéricos de botões
# ------------------------------------------------------------
func _ready() -> void:
	Singleton.gui_manager = self
	
	hover_sound_player.bus  = "SFX"
	select_sound_player.bus = "SFX"
	back_sound_player.bus   = "SFX"
	
	AudioPlayer._play_menu_music()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	
	hover_sound_player.process_mode  = Node.PROCESS_MODE_ALWAYS
	select_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS
	back_sound_player.process_mode   = Node.PROCESS_MODE_ALWAYS
	
	settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	input_settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	main_menu_layer.visible  = true
	credits_layer.visible    = false
	settings_layer.visible   = false
	input_settings_layer.visible = false
	game_hud_layer.visible = false
	game_over_screen.visible = false
	pause_menu_layer.visible = false
	levels_menu_layer.visible = false
	black_hole_warning_label.visible = false
	stats_table_layer.visible = false
	black_hole_warning_label.modulate.a = 0.0

	
	_tag_buttons_in_tree(main_menu_layer,  MAIN_MENU_BUTTON_GROUP)
	_tag_buttons_in_tree(credits_layer,    CREDITS_BUTTON_GROUP)
	_tag_buttons_in_tree(settings_layer,   SETTINGS_BUTTON_GROUP)
	_tag_buttons_in_tree(input_settings_layer, INPUT_SETTINGS_BUTTON_GROUP)
	_tag_buttons_in_tree(game_over_screen, GAME_OVER_SCREEN_GROUP)
	_tag_buttons_in_tree(pause_menu_layer, PAUSE_MENU_GROUP)
	_tag_buttons_in_tree(levels_menu_layer, LEVELS_MENU_GROUP)
	_tag_buttons_in_tree(stats_table_layer, STATS_TABLE_GROUP)
	
	_connect_button_signals_recursively(self)
	_connect_signal_safe(settings_master_volume_slider, "value_changed", Callable(self, "_on_settings_master_volume_changed"))
	_connect_signal_safe(settings_music_volume_slider, "value_changed", Callable(self, "_on_settings_music_volume_changed"))
	_connect_signal_safe(settings_sfx_volume_slider, "value_changed", Callable(self, "_on_settings_sfx_volume_changed"))
	
	_focus_first_button_in(main_menu_layer)
	
	Singleton._ensure_settings_icon(self)
	
	upgrades_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	var picker := upgrades_menu.get_node_or_null("SelectUpgrades")
	if picker:
		picker.process_mode = Node.PROCESS_MODE_ALWAYS

		if picker.has_signal("closed") and not picker.is_connected("closed", Callable(self, "_on_upgrades_picker_closed")):
			picker.closed.connect(_on_upgrades_picker_closed)
		# começa escondido
		picker.visible = false
	upgrades_menu.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# ignora se estamos em Main Menu ou Game Over
		if main_menu_layer.visible or game_over_screen.visible:
			return

		if is_paused:
			# fecha overlays por cima do pause, se houver
			if settings_layer.visible: settings_layer.visible = false
			if input_settings_layer.visible: input_settings_layer.visible = false
			if credits_layer.visible: credits_layer.visible = false
			if stats_table_layer.visible: stats_table_layer.visible = false
			hide_pause_menu()
			AudioPlayer.on_pause_exited()
		else:
			show_pause_menu()
			AudioPlayer.on_pause_entered()


# ------------------------------------------------------------
# Conecta sinais de forma segura, evitando duplicação de conexões.
# ------------------------------------------------------------
func _connect_signal_safe(emitter: Object, signal_name: String, callable: Callable) -> void:
	if not emitter.is_connected(signal_name, callable):
		emitter.connect(signal_name, callable)


# ------------------------------------------------------------
# Conecta sinais genéricos de botões (hover, foco e clique) em toda a árvore de nós.
# ------------------------------------------------------------
func _connect_button_signals_recursively(parent_node: Node) -> void:
	for ui_button in _collect_buttons_in_tree(parent_node):
		_connect_signal_safe(ui_button, "mouse_entered", _on_any_button_mouse_entered.bind(ui_button))
		_connect_signal_safe(ui_button, "focus_entered", _on_any_button_focus_entered.bind(ui_button))
		_connect_signal_safe(ui_button, "pressed",       _on_any_button_pressed.bind(ui_button))


# ------------------------------------------------------------
# Define o foco inicial no primeiro botão encontrado dentro de um nó.
# ------------------------------------------------------------
func _focus_first_button_in(root_node: Node) -> void:
	var buttons_in_root := _collect_buttons_in_tree(root_node)
	if buttons_in_root.size() > 0:
		buttons_in_root[0].grab_focus()


# ------------------------------------------------------------
# Coleta recursivamente todos os nós filhos que sejam botões (BaseButton).
# ------------------------------------------------------------
func _collect_buttons_in_tree(root_node: Node) -> Array[BaseButton]:
	var collected_buttons: Array[BaseButton] = []
	
	if root_node is BaseButton:
		collected_buttons.append(root_node)
	
	for child_node in root_node.get_children():
		collected_buttons.append_array(_collect_buttons_in_tree(child_node))
	
	return collected_buttons


# ------------------------------------------------------------
# Marca todos os botões dentro de um nó com um grupo específico.
# ------------------------------------------------------------
func _tag_buttons_in_tree(root_node: Node, group_name: String) -> void:
	for ui_button in _collect_buttons_in_tree(root_node):
		if not ui_button.is_in_group(group_name):
			ui_button.add_to_group(group_name)


# ------------------------------------------------------------
# Evento disparado ao passar o mouse por cima de um botão.
# Força o botão a receber foco.
# ------------------------------------------------------------
func _on_any_button_mouse_entered(hovered_button: BaseButton) -> void:
	if hovered_button.focus_mode != Control.FOCUS_NONE:
		hovered_button.grab_focus()


# ------------------------------------------------------------
# Evento disparado quando um botão recebe foco.
# Toca o som de hover.
# ------------------------------------------------------------
func _on_any_button_focus_entered(_focused_button: BaseButton) -> void:
	if hover_sound_player.playing:
		hover_sound_player.stop()
	
	hover_sound_player.play()


# ------------------------------------------------------------
# Toca som de seleção ao pressionar botão.
# ------------------------------------------------------------
func _play_select_sound() -> void:
	if select_sound_player.playing:
		select_sound_player.stop()
	
	select_sound_player.play()


# ------------------------------------------------------------
# Toca som de voltar ao pressionar botão.
# ------------------------------------------------------------
func _play_back_sound() -> void:
	if back_sound_player.playing:
		back_sound_player.stop()
	
	back_sound_player.play()


# ------------------------------------------------------------
# Evento disparado quando qualquer botão é pressionado.
# Verifica a qual grupo o botão pertence e chama o método correspondente.
# ------------------------------------------------------------
func _on_any_button_pressed(pressed_button: BaseButton) -> void:
	_play_select_sound()
	
	if pressed_button.is_in_group(MAIN_MENU_BUTTON_GROUP):
		_on_main_menu_button_pressed(pressed_button)
	elif pressed_button.is_in_group(CREDITS_BUTTON_GROUP):
		_on_credits_button_pressed(pressed_button)
	elif pressed_button.is_in_group(SETTINGS_BUTTON_GROUP):
		_on_settings_button_pressed(pressed_button)
	elif pressed_button.is_in_group(INPUT_SETTINGS_BUTTON_GROUP):
		_on_input_settings_button_pressed(pressed_button)
	elif pressed_button.is_in_group(GAME_OVER_SCREEN_GROUP):
		_on_game_over_screen_button_pressed(pressed_button)
	elif pressed_button.is_in_group(PAUSE_MENU_GROUP):
		_on_pause_menu_button_pressed(pressed_button)
	elif pressed_button.is_in_group(LEVELS_MENU_GROUP):
		_on_levels_menu_button_pressed(pressed_button)


# Ações de botões do menu principal.
func _on_main_menu_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"NewGameButton":
			_show_levels_menu()
		"ContinueGameButton":
			Singleton.continue_game()
		"LoadGameButton":
			Singleton.load_game()
		"SaveGameButton":
			Singleton.save_game()
		"SettingsButton":
			Singleton.open_settings()
		"CreditsButton":
			Singleton.open_credits()
		"StatsButton":
			_show_stats()
		"QuitButton":
			Singleton.quit_game_from_menu()


# Ações de botões da tela de créditos.
func _on_credits_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"Back":
			_play_back_sound()
			Singleton.open_main_menu()


func _on_settings_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"ControlsButton":
			Singleton.open_controls()
		"Back":
			_play_back_sound()
			AudioPlayer.save_volumes()
			settings_layer.visible = false
			on_settings_back.call()
			on_settings_back = Callable(Singleton, "open_main_menu")


# ------------------------------------------------------------
# Chamados ao alterar o valor do slider de volume.
# ------------------------------------------------------------
func _on_settings_master_volume_changed(db: float) -> void:
	AudioPlayer.set_master_volume_db(db)


func _on_settings_music_volume_changed(db: float) -> void:
	AudioPlayer.set_music_volume_db(db)


func _on_settings_sfx_volume_changed(db: float) -> void:
	AudioPlayer.set_sfx_volume_db(db)



# Ações de botões na tela de configurações de input.
func _on_input_settings_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"BackToSettingsButton":
			_play_back_sound()
			show_settings()


# Ações de botões da tela de Game Over.
func _on_game_over_screen_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"GameOverRestartButton":
			Singleton.restart_game()


# Ações de botões da tela de Pause.
func _on_pause_menu_button_pressed(pressed_button: BaseButton) -> void:
	match  pressed_button.name:
		"ContinueGameButton":
			Singleton.continue_game()
		"RestartGameButton":
			Singleton.restart_game()
		"LoadGameButton":
			pass
		"SaveGameButton":
			pass
		"OpenSettingsButton":
			Singleton.open_settings()
		"QuitToMainMenuButton":
			Singleton.open_main_menu()
		"QuitToDesktopButton":
			Singleton.quit_to_desktop_from_game()


# Ações de botões do menu de level
func _on_levels_menu_button_pressed(pressed_button : BaseButton) -> void:
	match  pressed_button.name:
		"BackToMainMenuButton":
			Singleton.open_main_menu()


# ------------------------------------------------------------
# Exibe o menu de seleção de fases.
#   - Esconde o Main Menu.
#   - Limpa quaisquer botões de fases previamente gerados.
#   - Regenera a lista de botões com base em Singleton.levels.
#   - Mostra a camada de Levels e coloca foco no botão "Voltar".
#   - Reseta o conteúdo de `levels_container`.
# ------------------------------------------------------------
func _show_levels_menu() -> void:
	main_menu_layer.visible = false
	
	for levels in levels_container.get_children():
		levels.queue_free()
	
	_generate_level_buttons()
	
	levels_menu_layer.visible = true
	back_to_main_menu_button.grab_focus()


# ------------------------------------------------------------
# Gera dinamicamente os botões de níveis.
#   - Limpa o container antes de gerar novos botões.
#   - Verifica se o nível está desbloqueado.
#   - Se desbloqueado: habilita o botão.
#   - Se bloqueado: desabilita o botão e exibe apenas o rótulo.
#   - Popula `levels_container` com novos botões.
# ------------------------------------------------------------
func _generate_level_buttons():
	
	for levels in levels_container.get_children():
		levels.queue_free()
	
	var level_keys = Singleton.levels.keys()
	#level_keys.sort()
	
	for level_id in level_keys:
		var level_data = Singleton.levels[level_id]
		var label = level_data["label"]
		var _level_path = "res://levels/" + level_data["url"]
		
		var button = Button.new()
		var level_is_unlocked = Singleton.level_is_unlocked(level_id)
		
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if level_is_unlocked:
			button.text = " " + label + " " 
			button.disabled = false
			button.pressed.connect(func():
				levels_menu_layer.visible = false
				Singleton.change_level(level_data["url"])
				Singleton.start_game()
			)
		else:
			button.text = label
			button.disabled = true
		
		levels_container.add_child(button)


# Métodos chamados externamente via Singleton
# Controlam a visibilidade das telas principais do jogo.
func show_main_menu() -> void:
	credits_layer.visible   = false
	settings_layer.visible  = false
	levels_menu_layer.visible = false
	stats_table_layer.visible = false
	main_menu_layer.visible = true
	_focus_first_button_in(main_menu_layer)


func show_settings() -> void:
	if is_paused:
		pause_menu_layer.visible = false
	
	main_menu_layer.visible = false
	credits_layer.visible   = false
	settings_layer.visible  = true
	input_settings_layer.visible = false
	stats_table_layer.visible = false
	settings_controls_btn.grab_focus()
	
	# sincroniza sliders com os buses
	settings_master_volume_slider.value = AudioPlayer.get_master_volume_db()
	settings_music_volume_slider.value = AudioPlayer.get_music_volume_db()
	settings_sfx_volume_slider.value   = AudioPlayer.get_sfx_volume_db()


func show_credits() -> void:
	main_menu_layer.visible = false
	settings_layer.visible  = false
	credits_layer.visible   = true
	_focus_first_button_in(credits_layer)


func _show_stats() -> void:
	main_menu_layer.visible = false
	stats_table_layer.visible = true
	_focus_first_button_in(stats_table_layer)


func show_input_settings() -> void:
	main_menu_layer.visible   = false
	credits_layer.visible     = false
	settings_layer.visible    = false
	input_settings_layer.visible = true
	_focus_first_button_in(input_settings_layer)


func show_pause_menu() -> void:
	get_tree().paused = true
	pause_menu_layer.visible = true
	is_paused = true
	_focus_first_button_in(pause_menu_layer)


func hide_pause_menu() -> void:
	get_tree().paused = false
	pause_menu_layer.visible = false
	is_paused = false


# ------------------------------------------------------------
# Esconde apenas o overlay do menu de pausa.
# - Não altera o estado de pausa do jogo (get_tree().paused permanece como está)
# - Não modifica a flag interna is_paused nem outras camadas/menus
# - Útil quando você quer mostrar outra UI por cima (ex.: Settings) mantendo o jogo pausado
# ------------------------------------------------------------
func hide_pause_overlay_only() -> void:
	pause_menu_layer.visible = false


# ------------------------------------------------------------
# Exibe apenas o overlay do menu de pausa.
# - Não altera o estado de pausa do jogo (get_tree().paused permanece como está)
# - Não modifica a flag interna is_paused nem outras camadas/menus
# - Útil para retornar do Settings/Credits ao overlay de pausa, mantendo a partida congelada
# ------------------------------------------------------------
func show_pause_overlay_only() -> void:
	pause_menu_layer.visible = true


# ------------------------------------------------------------
# Exibe uma notificação de "Level Up" no HUD.
# Parâmetros:
#   - message: Texto a ser mostrado na notificação.
#
# Comportamento:
# - Garante que o Label `level_up_notification_label` é válido.
# - Atualiza o texto do Label e o torna visível, mas inicialmente
#   com alpha = 0 (invisível).
# - Cria uma animação (Tween) que faz:
#     1. Fade in rápido (0.15s).
#     2. Pausa (1.0s).
#     3. Fade out suave (0.35s).
# - Quando o Tween termina, esconde novamente o Label
#   para evitar que permaneça visível.
# ------------------------------------------------------------
func show_level_up_notice(message: String) -> void:
	if not is_instance_valid(level_up_notification_label):
		return
	
	level_up_notification_label.text = message
	level_up_notification_label.visible = true
	level_up_notification_label.modulate.a = 0.0
	
	var fade_tween := get_tree().create_tween()
	fade_tween.tween_property(level_up_notification_label, "modulate:a", 1.0, 0.15)
	fade_tween.tween_interval(1.0)
	fade_tween.tween_property(level_up_notification_label, "modulate:a", 0.0, 0.35)
	
	fade_tween.finished.connect(func ():
		if is_instance_valid(level_up_notification_label):
			level_up_notification_label.visible = false
	)


func open_upgrades_picker() -> void:
	if not is_instance_valid(upgrades_menu):
		return
	var picker := upgrades_menu.get_node_or_null("SelectUpgrades")
	if picker == null:
		push_error("SelectUpgrades não está como filho de UpgradesMenu.")
		return
	
	upgrades_menu.visible = true
	picker.visible = true
	
	upgrades_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	picker.process_mode = Node.PROCESS_MODE_ALWAYS
	picker._populate_random(3)
	
	get_tree().paused = true


func _on_upgrades_picker_closed(track: int) -> void:
	get_tree().paused = false
	
	if is_instance_valid(Singleton.player):
		match track:
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_1:
				Singleton.player.set_selected_weapon(1)
			PlayerUpgrades.UpgradeTrack.ACTIVE_WEAPON_2:
				Singleton.player.set_selected_weapon(2)
			PlayerUpgrades.UpgradeTrack.PASSIVE_SHIELD, PlayerUpgrades.UpgradeTrack.PASSIVE_SPEED:
				pass
	
	var picker := upgrades_menu.get_node_or_null("SelectUpgrades")
	if picker:
		picker.visible = false
	upgrades_menu.visible = false
func notify_black_hole_warning(active: bool) -> void:
	# Agrega múltiplas fontes de aviso (vários buracos negros próximos).
	if active:
		black_hole_warning_sources += 1
		if black_hole_warning_sources == 1:
			_start_black_hole_blink()
	else:
		black_hole_warning_sources = max(0, black_hole_warning_sources - 1)
		if black_hole_warning_sources == 0:
			_stop_black_hole_blink()


func _start_black_hole_blink() -> void:
	if not is_instance_valid(black_hole_warning_label):
		return
	
	black_hole_warning_label.visible = true
	
	# Recria tween em loop para piscar
	if black_hole_warning_tween:
		black_hole_warning_tween.kill()
	black_hole_warning_tween = get_tree().create_tween().set_loops()
	black_hole_warning_tween.tween_property(black_hole_warning_label, "modulate:a", 1.0, 0.35)
	black_hole_warning_tween.tween_property(black_hole_warning_label, "modulate:a", 0.2, 0.35)


func _stop_black_hole_blink() -> void:
	if black_hole_warning_tween:
		black_hole_warning_tween.kill()
		black_hole_warning_tween = null
	
	if is_instance_valid(black_hole_warning_label):
		black_hole_warning_label.visible = false
		black_hole_warning_label.modulate.a = 1.0
