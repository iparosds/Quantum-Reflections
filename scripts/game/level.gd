class_name Level extends Node2D

const ASTEROID = preload("res://scenes/game/asteroid.tscn")
const PORTAL = preload("res://scenes/game/portal.tscn")

@export var level_duration_seconds: float = 180.0
@export var portal_duration_seconds: float = 20.0

# Margem mínima entre o centro do portal e o centro de um BlackHole,
# além do raio dele + "meio tamanho" do portal.
@export var portal_safe_margin: float = 100.0
@export var portal_half_size: float = 5.0

var game_paused = false
var quantum = false
var portal_active = false
var score = 0;
var quantum_roll = 0	
var portal_timer: float = 0.0
var portal_node: Node2D = null


func _ready():
	Singleton.level = self
	AudioPlayer._play_level_music()
	
	# inicia o cronômetro com a duração configurada
	portal_timer = level_duration_seconds
	Singleton.gui_manager.hud_timer_bar.max_value = level_duration_seconds
	
	_update_xp_label_text()


func _world_center() -> Vector2:
	if $World.has_node("CollisionShape2D"):
		return $World/CollisionShape2D.global_position
	return $World.global_position


func _world_radius() -> float:
	var radius := 1000.0  # fallback
	if $World.has_node("CollisionShape2D"):
		var collision_shape := $World/CollisionShape2D
		if collision_shape is CollisionShape2D and (collision_shape as CollisionShape2D).shape is CircleShape2D:
			radius = ((collision_shape as CollisionShape2D).shape as CircleShape2D).radius
			# considera escala global (supondo escala uniforme)
			radius *= abs($World.global_scale.x)
	return radius


func _world_radius_effective() -> float:
	# tira metade do tamanho do portal + margem para não colar na borda
	return max(0.0, _world_radius() - (portal_half_size + portal_safe_margin))


func _is_inside_world(calculated_position: Vector2) -> bool:
	return calculated_position.distance_to(_world_center()) <= _world_radius_effective()


func _clamp_inside_world(calculated_position: Vector2) -> Vector2:
	var world_center := _world_center()
	var center_direction := calculated_position - world_center
	var distance := center_direction.length()
	if distance <= 0.0001:
		return world_center + Vector2(_world_radius_effective(), 0)
	return world_center + center_direction * (_world_radius_effective() / distance)


# -------------------------
# UTIL: tenta inferir o "raio" efetivo do BlackHole
# -------------------------
func _black_hole_radius(black_hole: Node2D) -> float:
	var fallback := 64.0 # caso não exista CollisionShape2D/CircleShape2D
	if not is_instance_valid(black_hole):
		return fallback
	
	if black_hole.has_node("CollisionShape2D"):
		var collision_shape := black_hole.get_node("CollisionShape2D")
		if collision_shape is CollisionShape2D and (collision_shape as CollisionShape2D).shape is CircleShape2D:
			var circle := ((collision_shape as CollisionShape2D).shape as CircleShape2D)
			# considera o scale do BlackHole
			return circle.radius * black_hole.scale.x
	return fallback


# -------------------------
# Checa se posição é segura (não “em cima” de um buraco negro)
# -------------------------
func _is_safe_portal_position(calculated_position: Vector2) -> bool:
	var black_holes := get_tree().get_nodes_in_group("black_holes")
	for black_hole in black_holes:
		if not (black_hole is Node2D):
			continue
		var min_separation := _black_hole_radius(black_hole) + portal_half_size + portal_safe_margin
		if calculated_position.distance_to((black_hole as Node2D).global_position) < min_separation:
			return false
	return true


# -------------------------
# Encontra o Black Hole mais próximo de uma posição
# -------------------------
func _nearest_black_hole(calculated_position: Vector2) -> Node2D:
	var black_holes := get_tree().get_nodes_in_group("black_holes")
	var nearest_black_hole: Node2D = null
	var best_distance := INF
	for black_hole in black_holes:
		if not (black_hole is Node2D):
			continue
		var distance := calculated_position.distance_to((black_hole as Node2D).global_position)
		if distance < best_distance:
			best_distance = distance
			nearest_black_hole = black_hole
	return nearest_black_hole


# -------------------------
# Escolhe uma posição segura para o portal ao longo do Path2D
# - Faz tentativas aleatórias no PathFollow2D.
# - Se todas falharem, “empurra” para longe do Black Hole mais próximo.
## -------------------------
func _find_safe_portal_position() -> Vector2:
	var attempts := 32
	var candidate_position = %PathFollow2D.global_position
	
	for i in range(attempts):
		%PathFollow2D.progress_ratio = randf()
		candidate_position = %PathFollow2D.global_position
		
		# garante que a posicao está dentro do mundo
		if not _is_inside_world(candidate_position):
			candidate_position = _clamp_inside_world(candidate_position)
		
		if _is_safe_portal_position(candidate_position):
			return candidate_position
	
	# Fallback: não achou posição segura dentro das tentativas.
	# Empurra para fora do BH mais próximo a partir do último candidato.
	var nearest_black_hole := _nearest_black_hole(candidate_position)
	if is_instance_valid(nearest_black_hole):
		var push_away_distance = (candidate_position - nearest_black_hole.global_position).normalized()
		var min_separation := _black_hole_radius(nearest_black_hole) + portal_half_size + portal_safe_margin
		candidate_position = nearest_black_hole.global_position + push_away_distance * min_separation
		
		# garante dentro do mundo
		candidate_position = _clamp_inside_world(candidate_position)
		
		# se ainda não for seguro contra TODOS os BHs, varre alguns ângulos no mesmo raio
		if not _is_safe_portal_position(candidate_position):
			var world_center := _world_center()
			var center_direction = candidate_position - world_center
			var distance = center_direction.length()
			for k in range(16):
				var angle := TAU * float(k + 1) / 16.0
				var try_position = world_center + center_direction.rotated(angle)
				try_position = _clamp_inside_world(try_position)
				if _is_safe_portal_position(try_position):
					return try_position
		
		return candidate_position
	
	# último recurso: ao menos dentro do mundo
	return _clamp_inside_world(candidate_position)


func _open_portal():
	portal_node = PORTAL.instantiate()
	
	portal_node.global_position = _find_safe_portal_position()
	
	add_child(portal_node)
	portal_node.add_to_group("portal")
	
	get_tree().call_group("asteroids", "on_portal_opened", portal_node)


# ------------------------------------------------------------
# Finaliza o nível como vitória do jogador.
# ------------------------------------------------------------
func win():
	get_tree().paused = true
	Singleton.gui_manager.hud_portal_active.visible = false
	Singleton.gui_manager.game_over_screen.visible = true
	Singleton.gui_manager.game_over_label.text = "You win!"
	
	if is_instance_valid(Singleton.settings_icon):
		Singleton.settings_icon.visible = false


# ------------------------------------------------------------
# Instancia um novo asteroide em uma posição pseudoaleatória ao longo do Path2D via PathFollow2D.
# - Usa progress_ratio randômico para distribuir spawns pela trajetória
# - Adiciona o novo nó ao primeiro nó encontrado no grupo "asteroids" de forma adiada
# ------------------------------------------------------------
func spawn_asteroid():
	var new_asteroid = ASTEROID.instantiate()
	%PathFollow2D.progress_ratio = randf()
	var candidate_position = %PathFollow2D.global_position
	
	if not _is_inside_world(candidate_position):
		candidate_position = _clamp_inside_world(candidate_position)
		
	new_asteroid.global_position = candidate_position
	
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
		Singleton.god_mode = not Singleton.god_mode
		Singleton.gui_manager.hud_god_mode.visible = Singleton.god_mode
	
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
			portal_timer = portal_duration_seconds ### GPT
			Singleton.gui_manager.hud_portal_active.visible = true
			Singleton.gui_manager.hud_timer_bar.get("theme_override_styles/fill").bg_color = Color.hex(0xb4b542ff)
			_open_portal()
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
	
	if score <= 10:
		Singleton.gui_manager.hud_xp.max_value = 10
		Singleton.gui_manager.hud_xp.value = score
	elif score > 10 && score <= 50:
		Singleton.gui_manager.hud_xp.max_value = 50
		Singleton.gui_manager.hud_xp.value = score - 10
	elif score > 50 && score <= 100:
		Singleton.gui_manager.hud_xp.max_value = 100
		Singleton.gui_manager.hud_xp.value = score - 50
	elif score > 100 && score <= 200:
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
	
	_update_xp_label_text()


# ------------------------------------------------------------
# Atualiza o texto do HUD de XP exibido ao jogador.
# - Usa os thresholds definidos em Player.PLAYER_LEVELS (min_score).
# - Determina o nível atual com base na pontuação total do jogador.
# - Caso o jogador já tenha alcançado o último nível configurado,
#   exibe "Max level reached".
# ------------------------------------------------------------
func _update_xp_label_text() -> void:
	var level_thresholds: Array[int] = []
	for level_defined in Player.PLAYER_LEVELS:
		level_thresholds.append(int(level_defined["min_score"]))
	
	level_thresholds.sort()
	
	var total_points = score
	var current_level_index := 0
	
	for level in range(level_thresholds.size()):
		if total_points >= level_thresholds[level]:
			current_level_index = level
		else:
			break
	
	var level_number := current_level_index + 1
	var is_last := current_level_index >= level_thresholds.size() - 1
	
	if is_last:
		Singleton.gui_manager.hud_score_label.text = "Max level reached"
	else:
		var next_required := level_thresholds[current_level_index + 1]
		Singleton.gui_manager.hud_score_label.text = "Level %d: %d of %d to next level" % [
			level_number, total_points, next_required
		]


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


#===============================================
# Teclas para teste de spawn do portal
# NO TECLADO NUMERICO :
# 	1 - ABRE PORTAL
# 	2 - SPAWNA BURACO NEGRO
# 	3 - TESTA POSICAO CANDIDATA PARA O PORTAL E MOSTRA MSG NO OUTPUT
#================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_open_portal"):
		if portal_active == false:
			portal_active = true
			portal_timer = portal_duration_seconds
			Singleton.gui_manager.hud_portal_active.visible = true
			Singleton.gui_manager.hud_timer_bar.get("theme_override_styles/fill").bg_color = Color.hex(0xb4b542ff)
			_open_portal()
	
	if event.is_action_pressed("debug_spawn_black_hole"):
		var black_hole := preload("res://scenes/game/black_hole.tscn").instantiate()
		
		# posição candidata perto do Path
		%PathFollow2D.progress_ratio = randf()
		var base_position = %PathFollow2D.global_position
		var candidate_position = base_position + Vector2(randi_range(-120, 120), randi_range(-120, 120))
		
		# clamp para dentro do World, respeitando o raio do buraco negro
		var world_center := _world_center()
		var world_radius := _world_radius()
		var black_hole_radius := _black_hole_radius(black_hole)
		var center_direction = candidate_position - world_center
		var distance = center_direction.length()
		# garante black_hole inteiro dentro do mundo
		var max_radius = max(0.0, world_radius - black_hole_radius)
		
		if distance <= 0.0001:
			candidate_position = world_center + Vector2(max_radius, 0)
		elif distance > max_radius:
			candidate_position = world_center + center_direction * (max_radius / distance)
		
		black_hole.global_position = candidate_position
		add_child(black_hole)
	
	if event.is_action_pressed("debug_run_portal_test"):
		_run_portal_sanity_check(300)  # 300 tentativas


func _run_portal_sanity_check(attempts: int = 500) -> void:
	var failures := 0
	for i in range(attempts):
		# gera uma posição candidata como o _open_portal faz
		%PathFollow2D.progress_ratio = randf()
		var candidate := _find_safe_portal_position()
		if not _is_safe_portal_position(candidate):
			failures += 1
	
	if failures == 0:
		print("[PORTAL TEST] OK: ", attempts, " tentativas sem sobreposição.")
	else:
		push_error("[PORTAL TEST] Falhas: %d de %d" % [failures, attempts])
		assert(false, "Portal nasceu em zona insegura")
