extends Node2D

@onready var closest_enemy := find_closest_enemy()
const SETTINGS_ICON := preload("res://scenes/globals/settings_icon.tscn")

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

# Dicionário com os níveis disponíveis e seus caminhos
var levels: Dictionary = {
	"level01": {
		"path": "res://levels/level_01.tscn",
	},
}


# ---------------------
# FUNÇÕES DE INTERFACE
# ---------------------

# Inicia o jogo carregando o nível padrão
func start_game() -> void:
	get_tree().paused = false
	if gui_manager:
		gui_manager.main_menu_layer.visible = false
		gui_manager.game_hud_layer.visible = true
	
	var default_id := "level01"
	var path = levels[default_id]["path"]
	change_level(path)


func continue_game() -> void:
	if not gui_manager.is_paused:
		return
	
	gui_manager.hide_pause_menu()


func load_game() -> void:
	pass


func save_game() -> void:
	pass


func open_settings() -> void:
	if gui_manager:
		if gui_manager.is_paused:
			gui_manager.on_settings_back = Callable(gui_manager, "show_pause_overlay_only")
			gui_manager.hide_pause_overlay_only()
		else:
			gui_manager.on_settings_back = Callable(self, "open_main_menu")
		
		gui_manager.show_settings()


# ------------------------------------------------------------
# Abre a tela de Settings a partir do ícone in-game (sem passar pelo overlay do Pause).
# 	- Garante que o jogo fique pausado.
# 	- Define o callback de retorno do Settings para reabrir o Pause menu, 
#		de forma que o botão “Back” do Settings volte ao Pause ao invés do Main Menu.
# 	- Faz early-return se o gui_manager ainda não estiver disponível.
# ------------------------------------------------------------
func open_settings_from_icon() -> void:
	if not gui_manager:
		return
	
	get_tree().paused = true
	gui_manager.is_paused = true
	gui_manager.hide_pause_overlay_only()
	
	# quando o usuário apertar "Back" no Settings, volta para o Pause menu
	gui_manager.on_settings_back = Callable(gui_manager, "show_pause_menu")
	
	gui_manager.show_settings()


func open_credits() -> void:
	if gui_manager:
		gui_manager.show_credits()


# Abre o Main Menu com teardown seguro do gameplay.
# 	Pausa a árvore para impedir ticks/resíduos durante a desmontagem.
# 	Se o fluxo veio do Pause, esconde apenas o overlay de pausa (sem despausar).
# 	Caso exista um Level ativo, limpa referências globais, faz queue_free nele
# 		e aguarda um frame para a remoção efetivar.
# 	Remove sobras que possam ter ficado fora do Level (grupos "asteroid" e "ore").
func open_main_menu() -> void:
	get_tree().paused = true

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

	get_tree().paused = false


func open_controls() -> void:
	if gui_manager:
		gui_manager.show_input_settings()


# Ajusta o volume geral do jogo
func set_master_volume_db(db_value: float) -> void:
	AudioServer.set_bus_volume_db(0, db_value)


func quit_game_from_menu() -> void:
	get_tree().quit()


func quit_to_desktop_from_game() -> void:
	if not gui_manager.is_paused:
		return
	
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause() -> void:
	if gui_manager.main_menu_layer.visible || gui_manager.game_over_screen.visible:
		return
	
	if gui_manager.is_paused:
		gui_manager.hide_pause_menu()
	else:
		gui_manager.show_pause_menu()


# Reinicia a partida com teardown seguro e restaura o HUD.
func restart_game() -> void:
	if current_level_path == null or current_level_path == "":
		return
	
	get_tree().paused = true
	
	if gui_manager:
		gui_manager.game_over_screen.visible = false
	
	change_level(current_level_path)
	await get_tree().process_frame
	
	reset_game_state()
	
	if gui_manager:
		gui_manager.hud_portal_active.visible = false
		gui_manager.hud_timer_bar.get("theme_override_styles/fill").bg_color = Color(0.129, 0.259, 0.42)
	
	get_tree().paused = false
	start_game()
	
	if gui_manager and gui_manager.is_paused:
		gui_manager.hide_pause_menu()


# Reseta variáveis de estado do jogo (pontuação, XP etc.)
func reset_game_state():
	if gui_manager:
		score = 0
		gui_manager.hud_score_label.text = "0 ores"
		gui_manager.hud_xp.value = 0


func game_over():
	if god_mode == false:
		get_tree().paused = true
		gui_manager.game_over_screen.visible = true
		gui_manager.game_over_label.text = "Game over!"
		gui_manager.hud_portal_active.visible = false
		settings_icon.visible = false


# ---------------------
# FUNÇÕES DE NÍVEL
# ---------------------

# Troca o nível atual por outro
func change_level(load_level: String) -> void:
	var level_path: String = load_level if load_level.begins_with("res://") else "res://levels/%s" % load_level
	
	# Verifica se o arquivo do nível existe
	if not ResourceLoader.exists(level_path):
		push_error("Level não encontrado: %s" % level_path)
		return
	
	# Carrega recurso do nível
	var scene_res: PackedScene = ResourceLoader.load(level_path) as PackedScene
	if scene_res == null:
		push_error("Falha ao carregar: %s (não é PackedScene)" % level_path)
		return
	
	# Instancia novo nível
	var new_level: Level = scene_res.instantiate() as Level
	
	# Remove o nível anterior, se existir
	if level != null and is_instance_valid(level):
		level.queue_free()
	
	# Define onde o nível será anexado
	var parent: Node = level_manager if level_manager != null else get_tree().current_scene
	parent.add_child(new_level)
	
	level = new_level
	
	# remove ícone anterior (se existir) e cria um novo para este level
	if is_instance_valid(settings_icon):
		settings_icon.queue_free()

	settings_icon = SETTINGS_ICON.instantiate()
	settings_icon.process_mode = Node.PROCESS_MODE_ALWAYS
	level.add_child(settings_icon)
	
	# Atualiza variáveis de controle do nível atual
	current_level_path = level_path
	for id in levels.keys():
		var path: String = ""
		var url: String = ""
		if levels[id].has("path"):
			path = String(levels[id]["path"])
		if levels[id].has("url"):
			url = "res://levels/%s" % String(levels[id]["url"])
		if path == level_path or url == level_path:
			current_level = String(id)
			break


# ---------------------
# FUNÇÕES UTILITÁRIAS
# ---------------------

# Exibe número animado na tela (pontuação, dano etc.)
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


# Retorna o inimigo mais próximo do player
func find_closest_enemy() -> Object:
	var all_enemy := get_tree().get_nodes_in_group("asteroid")
	
	for enemy in all_enemy:
		var gun2enemy_distance := position.distance_to(enemy.position)
		if gun2enemy_distance < closest_distance:
			closest_distance = gun2enemy_distance
			closest_enemy = enemy
	
	return closest_enemy


# Chamado a cada frame para atualizar o inimigo mais próximo
func _process(_delta: float) -> void:
	closest_enemy = find_closest_enemy()
