class_name GuiManager
extends Node2D

const MAIN_MENU_BUTTON_GROUP := "main_menu_button"
const CREDITS_BUTTON_GROUP   := "credits_menu_button"
const SETTINGS_BUTTON_GROUP  := "settings_menu_button"
const INPUT_SETTINGS_BUTTON_GROUP := "input_settings_button"

# Layers
@onready var main_menu_layer: CanvasLayer  = $MainMenu
@onready var credits_layer: CanvasLayer    = $Credits
@onready var settings_layer: CanvasLayer   = $SettingsMenu
@onready var input_settings_layer: CanvasLayer = $InputSettings

# Sounds
@onready var hover_sound_player:  AudioStreamPlayer = $Sounds/HoverSoundPlayer
@onready var select_sound_player: AudioStreamPlayer = $Sounds/SelectSoundPlayer
@onready var back_sound_player:   AudioStreamPlayer = $Sounds/BackSoundPlayer

# Controles de Settings
@onready var settings_volume_slider: HSlider   = $SettingsMenu/MarginContainer/ButtonsContainer/Volume
@onready var settings_controls_btn: BaseButton = $SettingsMenu/MarginContainer/ButtonsContainer/ControlsButton


func _ready() -> void:
	Singleton.gui_manager = self

	get_tree().paused = false
	hover_sound_player.process_mode  = Node.PROCESS_MODE_ALWAYS
	select_sound_player.process_mode = Node.PROCESS_MODE_ALWAYS
	back_sound_player.process_mode   = Node.PROCESS_MODE_ALWAYS

	# Estado inicial
	main_menu_layer.visible  = true
	credits_layer.visible    = false
	settings_layer.visible   = false
	input_settings_layer.visible = false
	AudioPlayer._play_menu_music()

	# Tag de grupos por camada
	_tag_buttons_in_tree(main_menu_layer,  MAIN_MENU_BUTTON_GROUP)
	_tag_buttons_in_tree(credits_layer,    CREDITS_BUTTON_GROUP)
	_tag_buttons_in_tree(settings_layer,   SETTINGS_BUTTON_GROUP)
	_tag_buttons_in_tree(input_settings_layer, INPUT_SETTINGS_BUTTON_GROUP)

	# Conecta sinais genéricos para todos os botões
	_connect_button_signals_recursively(self)
	_connect_signal_safe(settings_volume_slider, "value_changed", Callable(self, "_on_settings_volume_changed"))
	_focus_first_button_in(main_menu_layer)


func _unhandled_input(event: InputEvent) -> void:
	# Tecla "back" volta ao MainMenu a partir de Settings/Credits
	if event.is_action_pressed("back"):
		if credits_layer.visible or settings_layer.visible:
			_play_back_sound()
			Singleton.open_main_menu()


# Evita tentativa de conexoes de sinais simultaneos dos botoes
func _connect_signal_safe(emitter: Object, signal_name: String, callable: Callable) -> void:
	if not emitter.is_connected(signal_name, callable):
		emitter.connect(signal_name, callable)


#Conexões genéricas de botões
func _connect_button_signals_recursively(parent_node: Node) -> void:
	for ui_button in _collect_buttons_in_tree(parent_node):
		_connect_signal_safe(ui_button, "mouse_entered", _on_any_button_mouse_entered.bind(ui_button))
		_connect_signal_safe(ui_button, "focus_entered", _on_any_button_focus_entered.bind(ui_button))
		_connect_signal_safe(ui_button, "pressed",       _on_any_button_pressed.bind(ui_button))


func _focus_first_button_in(root_node: Node) -> void:
	var buttons_in_root := _collect_buttons_in_tree(root_node)
	if buttons_in_root.size() > 0:
		buttons_in_root[0].grab_focus()


# Percorre recursivamente uma árvore de nós a partir de `root_node`
# e coleta todos os nós que sejam do tipo BaseButton.
func _collect_buttons_in_tree(root_node: Node) -> Array[BaseButton]:
	var collected_buttons: Array[BaseButton] = []
	
	if root_node is BaseButton:
		collected_buttons.append(root_node)
	
	for child_node in root_node.get_children():
		collected_buttons.append_array(_collect_buttons_in_tree(child_node))
	
	return collected_buttons


# Marca todos os botões encontrados dentro de `root_node` 
# (via _collect_buttons_in_tree) com um grupo específico.
func _tag_buttons_in_tree(root_node: Node, group_name: String) -> void:
	for ui_button in _collect_buttons_in_tree(root_node):
		if not ui_button.is_in_group(group_name):
			ui_button.add_to_group(group_name)


# Som / Foco
func _on_any_button_mouse_entered(hovered_button: BaseButton) -> void:
	if hovered_button.focus_mode != Control.FOCUS_NONE:
		hovered_button.grab_focus()


func _on_any_button_focus_entered(_focused_button: BaseButton) -> void:
	if hover_sound_player.playing:
		hover_sound_player.stop()
	
	hover_sound_player.play()


func _play_select_sound() -> void:
	if select_sound_player.playing:
		select_sound_player.stop()
	
	select_sound_player.play()


func _play_back_sound() -> void:
	if back_sound_player.playing:
		back_sound_player.stop()
	
	back_sound_player.play()


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


# Main Menu
func _on_main_menu_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"NewGameButton":
			Singleton.start_game()
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
		"QuitButton":
			Singleton.quit_game()


#Credits
func _on_credits_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"Back":
			_play_back_sound()
			Singleton.open_main_menu()


# Settings
func _on_settings_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"ControlsButton":
			Singleton.open_controls()
		"Back":
			_play_back_sound()
			Singleton.open_main_menu()


func _on_settings_volume_changed(new_value_db: float) -> void:
	Singleton.set_master_volume_db(new_value_db)


# Input Settings
func _on_input_settings_button_pressed(pressed_button: BaseButton) -> void:
	match pressed_button.name:
		"BackToSettingsButton":
			_play_back_sound()
			show_settings()


# Singleton
func show_main_menu() -> void:
	credits_layer.visible   = false
	settings_layer.visible  = false
	main_menu_layer.visible = true
	_focus_first_button_in(main_menu_layer)


func show_settings() -> void:
	main_menu_layer.visible = false
	credits_layer.visible   = false
	settings_layer.visible  = true
	input_settings_layer.visible = false
	settings_controls_btn.grab_focus()


func show_credits() -> void:
	main_menu_layer.visible = false
	settings_layer.visible  = false
	credits_layer.visible   = true
	_focus_first_button_in(credits_layer)


func show_input_settings() -> void:
	main_menu_layer.visible   = false
	credits_layer.visible     = false
	settings_layer.visible    = false
	input_settings_layer.visible = true
	_focus_first_button_in(input_settings_layer)
