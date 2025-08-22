class_name Level extends Node2D;

const ASTEROID = preload("res://scenes/in_game/asteroid.tscn")
const PORTAL = preload("res://scenes/in_game/portal.tscn")

@export var level_duration_seconds: float = 180.0
@export var portal_duration_seconds: float = 20.0

var game_paused = false;
var quantum = false;
var god_mode = false;
var portal_active = false;
var score = 0;
var quantum_roll = 0
var portal_timer: float = 0.0
var portal_node: Node2D = null


func _ready():
	Singleton.level = self
	AudioPlayer._play_level_music()
	
	###GPT####
	# inicia o cronômetro com a duração configurada
	portal_timer = level_duration_seconds
	# garante que o HUD mostre o máximo correto desde o começo
	Singleton.gui_manager.hud_timer_bar.max_value = level_duration_seconds


#### GPT #####
func _open_portal():
	# Instancia o portal
	portal_node = PORTAL.instantiate()
	
	# Escolha uma posição. Exemplos:
	# portal_node.global_position = %PortalSpawn.global_position
	# ou:
	portal_node.global_position = %PathFollow2D.global_position
	
	add_child(portal_node)
	portal_node.add_to_group("portal")  # útil para buscas
	
	# Avisa todos os asteroides qual é o alvo do portal
	get_tree().call_group("asteroids", "on_portal_opened", portal_node)



# ------------------------------------------------------------
# Finaliza o nível como vitória do jogador.
# ------------------------------------------------------------
func win():
	get_tree().paused = true
	Singleton.gui_manager.hud_portal_active.visible = false
	Singleton.gui_manager.game_over_screen.visible = true
	Singleton.gui_manager.game_over_label.text = "You win!"


# ------------------------------------------------------------
# Instancia um novo asteroide em uma posição pseudoaleatória ao longo do Path2D via PathFollow2D.
# - Usa progress_ratio randômico para distribuir spawns pela trajetória
# - Adiciona o novo nó ao primeiro nó encontrado no grupo "asteroids" de forma adiada
# ------------------------------------------------------------
func spawn_asteroid():
	var new_asteroid = ASTEROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_asteroid.global_position = %PathFollow2D.global_position
	var asteroids_group = get_tree().get_first_node_in_group("asteroids")
	asteroids_group.call_deferred("add_child", new_asteroid)


# ------------------------------------------------------------
# Reavalia o estado do modo quantum.
# - Se quantum_roll >= 5 ou um sorteio de 1/6 ocorrer, desativa o modo e zera o contador
# - Caso contrário, incrementa o contador para prolongar o efeito por alguns ciclos
# ------------------------------------------------------------
func reset_quantum():
	if quantum_roll >= 5 || randi_range(0,5) == 0:
		quantum = false;
		quantum_roll = 0
	else:
		quantum_roll += 1


# ------------------------------------------------------------
# Loop de física do nível.
# - Alternar god_mode via ação "god" e refletir no HUD
# - Aplicar efeitos do modo quantum (time_scale e cor de clear)
# - Atualizar o cronômetro portal_timer e transicionar entre estados normal/portal
# - Atualizar HUD de tempo, barras e estilos conforme estado do portal
# ------------------------------------------------------------
func _physics_process(delta):
	if Input.is_action_just_released("god"):
		if god_mode == false:
			god_mode = true
			Singleton.gui_manager.hud_god_mode.visible = true
		else:
			god_mode = false
			Singleton.gui_manager.hud_god_mode.visible = false
	
	if quantum == true:
		Engine.time_scale = 0.8
		RenderingServer.set_default_clear_color(Color.hex(0x7c7ea1ff))
	else:
		Engine.time_scale = 1
		RenderingServer.set_default_clear_color(Color.hex(0x2f213bff))
	
	portal_timer -= delta
	var time_left = int(portal_timer)
	
	if time_left < 1:
		if portal_active == false:
			portal_active = true
			#portal_timer = 20.0
			portal_timer = portal_duration_seconds ### GPT
			Singleton.gui_manager.hud_portal_active.visible = true
			Singleton.gui_manager.hud_timer_bar.get("theme_override_styles/fill").bg_color = Color.hex(0xb4b542ff)
			_open_portal()  # <- instancie e anuncie o portal aqui
		else:
			Singleton.game_over()
	
	

	var portal_minutes = 0
	if time_left > 60:
		portal_minutes = time_left/60

	var portal_seconds = time_left
	if portal_minutes > 0:
		portal_seconds = time_left - portal_minutes * 60

	if portal_seconds < 10:
		Singleton.gui_manager.hud_timer_text.text = str(portal_minutes, ":0", portal_seconds)
	else:
		Singleton.gui_manager.hud_timer_text.text = str(portal_minutes, ":", portal_seconds)

	#if portal_active == true:
		#Singleton.gui_manager.hud_timer_bar.max_value = 20
	#else:
		#Singleton.gui_manager.hud_timer_bar.max_value = 150
	
	### GPT ###
	if portal_active == true:
		Singleton.gui_manager.hud_timer_bar.max_value = portal_duration_seconds
	else:
		Singleton.gui_manager.hud_timer_bar.max_value = level_duration_seconds
	
	
	Singleton.gui_manager.hud_timer_bar.value = int(portal_timer)


# ------------------------------------------------------------
# Incrementa a pontuação do jogador e atualiza o HUD de XP por “faixas”.
# - score é acumulado linearmente
# - hud_xp.max_value muda por milestones, e o value exibe o progresso relativo dentro da faixa atual
# ------------------------------------------------------------
func add_ore():
	score += 1
	Singleton.gui_manager.hud_score_label.text = str(score) + " ores"

	if score <= 10:
		Singleton.gui_manager.hud_xp.max_value = 10
		Singleton.gui_manager.hud_xp.value = score
	elif score > 10 && score <= 50:
		Singleton.gui_manager.hud_xp.max_value = 50
		Singleton.gui_manager.hud_xp.value = score - 10
	elif score > 50 && score <= 100:
		Singleton.gui_manager.hud_xp.max_value = 100
		Singleton.gui_manager.hud_xp.value = score - 50
	elif score > 100 && score <=200:
		Singleton.gui_manager.hud_xp.max_value = 200
		Singleton.gui_manager.hud_xp.value = score - 100
	elif score > 200 && score <= 400:
		Singleton.gui_manager.hud_xp.max_value = 400
		Singleton.gui_manager.hud_xp.value = score - 200
	elif score > 400 && score <= 600:
		Singleton.gui_manager.hud_xp.max_value = 600
		Singleton.gui_manager.hud_xp.value = score - 400
	elif score > 600 && score < 800:
		Singleton.gui_manager.hud_xp.max_value = 800
		Singleton.gui_manager.hud_xp.value = score - 600


# Fornece leitura da pontuação atual.
func get_score():
	return score;


# ------------------------------------------------------------
# Handler de saída de corpos dos limites do mundo.
# - Para o player: aplica world_limit baseado no raio da colisão do mundo
# - Para outros corpos: remove da cena para evitar vazamento e manter performance
# ------------------------------------------------------------
func _on_world_body_exited(body: Node2D) -> void:
	if body.has_method("is_player"):
		body.world_limit($World/CollisionShape2D.shape.radius)
	else:
		body.queue_free()


# ------------------------------------------------------------
# Timer principal de spawn e progressão do nível.
# - Enfileirar reset do estado quantum quando aplicável
# - Spawns escalonados de asteroides conforme marcos de score, aumentando dificuldade gradualmente
# ------------------------------------------------------------
func _on_time_timeout():
	if quantum == true:
		reset_quantum()

	spawn_asteroid() #10
	if score > 5:
		spawn_asteroid() #50
	if score > 10:
		spawn_asteroid() #100
	if score > 100:
		spawn_asteroid() #200
	if score > 200:
		spawn_asteroid() #400
	if score > 400:
		spawn_asteroid() #600
	if score > 600:
		spawn_asteroid() #800
