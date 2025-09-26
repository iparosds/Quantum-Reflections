class_name Player extends CharacterBody2D

const BLACK_HOLE = preload("res://scenes/game/black_hole.tscn")
const DAMAGE_RATE = 500.0
const MAX_ACCELERATION = 1000.0

@onready var turrets: Dictionary = {
	"N":  %TurretN,
	"E":  %TurretE,
	"S":  %TurretS,
	"W":  %TurretW,
	"NE": %TurretNE,
	"NW": %TurretNW,
	"SE": %TurretSE,
	"SW": %TurretSW,
}

# Tabela de níveis (em ordem). Ao alcançar "min_score", ganhe as turrets em "unlock".
# Obs: o nível 0 liga a turret "E" por padrão (também forçada no _ready).
const PLAYER_LEVELS := [
	{"min_score": 0,   "unlock": ["E"]},
	{"min_score": 10,  "unlock": ["W"]},
	{"min_score": 50,  "unlock": ["S"]},
	{"min_score": 100, "unlock": ["N"]},
	{"min_score": 200, "unlock": ["NW"]},
	{"min_score": 400, "unlock": ["SE"]},
	{"min_score": 600, "unlock": ["NE"]},
	{"min_score": 800, "unlock": ["SW"]},
]

# Estado de progressão
var current_level_index: int = -1
var health = 100.0
var acceleration = 0.0
var accelelariting = false
var boosting = false
var stopping = false
var rotating_right = false
var rotating_left = false
var level
var dying_to_black_hole := false
var max_health: float = 100.0
var selected_weapon_id: int = 1

signal health_depleted


# ------------------------------------------------------------
# Inicialização do Player quando a cena é carregada.
# - Registra o Player atual no Singleton para acesso global.
# - Desativa todas as turrets (impede disparo inicial).
# - Garante que a turret "E" esteja ativa como arma padrão do nível 0.
# - Usa `call_deferred` para agendar a chamada de `_init_level_progress()`
#   após o término do `_ready()` do Level, evitando problemas de ordem
#   de inicialização entre Player e Level.
# ------------------------------------------------------------
func _ready():
	Singleton.player = self
	
	for turret in turrets.values():
		if is_instance_valid(turret):
			turret.current_bullet = 0
	
	call_deferred("_init_level_progress")
	 
	if get_tree().root.has_node("PlayerUpgrades"):
		PlayerUpgrades.stats_updated.connect(_on_upgrades_changed)
	
	_apply_health_from_upgrades(true, true)
	_apply_speed_from_upgrades()


func _on_upgrades_changed() -> void:
	_apply_health_from_upgrades()
	_apply_speed_from_upgrades()
	
	# DEBUG: ver multiplicadores atuais sempre que um upgrade é aplicado
	if PlayerUpgrades:
		print("[UPGR] W1 L=", PlayerUpgrades.active_weapon_1_level,
			" mult=", PlayerUpgrades.get_active_damage_multiplier(1),
			" | W2 L=", PlayerUpgrades.active_weapon_2_level,
			" mult=", PlayerUpgrades.get_active_damage_multiplier(2))


func is_player():
	return true


func world_limit(size):
	var player_position = global_position
	var vx = 563 - player_position.x
	var vy = 339 - player_position.y
	var length = sqrt(vx*vx + vy*vy)
	global_position.x = vx / length * size + 563
	global_position.y = vy / length * size + 339


# ------------------------------------------------------------
# Randomiza o tipo de disparo das turrets ativas quando o
# jogador entra em um portal.
# 	- Itera sobre todas as turrets existentes.
# 	- Se a turret estiver válida e ativa (current_bullet != 0),
#   	redefine seu `current_bullet` para um valor aleatório (1 ou 2).
# 	- Essa rotação cria variedade no comportamento das turrets
#   	após a interação com o portal.
func portal():
	for turret in turrets.values():
		if is_instance_valid(turret) and turret.current_bullet != 0:
			turret.current_bullet = randi_range(1, 2)


# ------------------------
# SISTEMA DE LEVEL UP
# ------------------------

# ------------------------------------------------------------
# Inicializa a progressão de nível do jogador com base no score atual.
# - Verifica se o Level já está válido no Singleton e expõe `get_score`.
# - Lê o score do Level ativo.
# - Calcula o índice de nível correspondente ao score via `_level_for_score`.
# - Aplica as turrets desbloqueadas até esse nível chamando
#   `_apply_level_up_to`, mas com `notify = false` para não exibir aviso
#   (evita mostrar "Level Up!" logo no início do jogo).
# - Atualiza o `current_level_index` para refletir o nível carregado.
# ------------------------------------------------------------
func _init_level_progress() -> void:
	if is_instance_valid(Singleton.level) and Singleton.level.has_method("get_score"):
		var score = Singleton.level.get_score()
		var level_index := _level_for_score(score)
		
		_apply_level_up_to(level_index, false)
		current_level_index = level_index


func _update_level_from_score(score: int) -> void:
	var target_index := _level_for_score(score)
	
	if current_level_index < 0:
		_apply_level_up_to(target_index, false)
		current_level_index = target_index
		return
	
	if target_index > current_level_index:
		_apply_level_up_to(target_index, true)
		current_level_index = target_index
		
		if target_index >= 1:
			_open_upgrade_picker()


# ------------------------------------------------------------
# Atualiza a progressão de nível com base no score atual.
# 	- Calcula o índice de nível correspondente ao score via `_level_for_score`.
# 	- Se o índice calculado (`target_index`) for maior que o `current_level_index`,
#   	significa que o jogador avançou para um novo nível.
# 	- Nesse caso, chama `_apply_level_up_to` passando `notify = true` para
#   	habilitar as turrets desbloqueadas e exibir a mensagem de Level Up.
# 	- Atualiza `current_level_index` para refletir o nível recém-alcançado.
# ------------------------------------------------------------
func _level_for_score(current_score: int) -> int:
	var highest_unlocked_index := -1
	for level_index in range(PLAYER_LEVELS.size()):
		if current_score >= int(PLAYER_LEVELS[level_index]["min_score"]):
			highest_unlocked_index = level_index
		else:
			break
	return highest_unlocked_index


# ------------------------------------------------------------
# Aplica os desbloqueios de turrets até o nível especificado.
# Parâmetros:
#   - target_level_index: índice máximo de nível a ser aplicado.
#   - notify: se true, mostra uma mensagem de Level Up ao desbloquear.
#
# Comportamento:
# - Itera por todos os níveis do índice 0 até `target_level_index`.
# - Para cada nível, percorre a lista de turrets em `unlock` e habilita 
#   (define `current_bullet = 1`) as turrets correspondentes no dicionário `turrets`.
# - Se `notify` for true e o nível possuir `min_score > 0`, gera uma mensagem
#   descrevendo quais turrets foram adicionadas e chama `show_level_up_notice`
#   no `gui_manager` para exibir o aviso na tela.
func _apply_level_up_to(target_level_index: int, notify: bool = true) -> void:
	for level_index in range(target_level_index + 1):
		var turrets_to_unlock: Array = PLAYER_LEVELS[level_index]["unlock"]
		
		for turret_direction in turrets_to_unlock:
			var turret_node = turrets.get(turret_direction, null)
			if is_instance_valid(turret_node):
				if turret_node.current_bullet == 0:
					turret_node.current_bullet = selected_weapon_id
		
		if (
			notify
			and int(PLAYER_LEVELS[level_index]["min_score"]) > 0
			and is_instance_valid(Singleton.gui_manager)
			and Singleton.gui_manager.has_method("show_level_up_notice")
		):
			var unlocked_parts: Array[String] = []
			for turret_direction in turrets_to_unlock:
				unlocked_parts.append("Turret " + String(turret_direction) + " Added!")
			
			var message := "Level up! " + ", ".join(unlocked_parts)
			Singleton.gui_manager.show_level_up_notice(message)


func _physics_process(delta):
	_update_level_from_score(Singleton.level.get_score())
	
	var cap := _get_speed_cap()
	
	if Singleton.quantum == false:
		%Ship.play("default")
	else:
		%Ship.play("quantum")
	
	accelelariting = Input.is_action_pressed("move_up")
	boosting = Input.is_action_pressed("boost")
	stopping = Input.is_action_pressed("move_down")
	rotating_right = Input.is_action_pressed("move_right")
	rotating_left = Input.is_action_pressed("move_left")
	
	if accelelariting == true && stopping == false && acceleration < cap:
		acceleration += 1
	if boosting == true && stopping == false && acceleration < (cap - 10.0):
		acceleration += 5
	
	if stopping == true && accelelariting == false && acceleration > 10:
		acceleration -= 5
	if stopping == false && accelelariting == false && acceleration > 0:
		acceleration -= 1
	
	if rotating_right == true && boosting == false:
		%Ship.rotation += (cap - (acceleration/2))/10000.0
	if rotating_left == true && boosting == false:
		%Ship.rotation -= (cap - (acceleration/2))/10000.0
	
	if acceleration > cap:
		acceleration = cap
	
	if acceleration > 0:
		var direction2 = Vector2.UP.rotated(%Ship.rotation)
		position += direction2 * (acceleration/2) * delta
		%SpeedBar.value = acceleration/10
	
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	for mob in overlapping_mobs:
		if mob.has_method("player_collision"):
			var damage = acceleration/30
			if damage <= 10:
				damage = 10
			health -= damage
			if Singleton.level.quantum == true:
				Singleton.display_number(damage, position, "#2f213b")
			else:
				Singleton.display_number(damage, position, "#7c7ea1")
			
			print_rich("[HP] ", snapped(health, 0.1), "/", max_health)
			
			mob.player_collision()
	
	var overlapping_ores = %CollectOre.get_overlapping_bodies()
	for mob in overlapping_ores:
		if mob.has_method("is_coin"):
			Singleton.level.add_ore()
			mob.queue_free()
	
	if health <= 0.0:
		health = max_health
		Singleton.level.quantum = true
		
		var new_black_hole = BLACK_HOLE.instantiate()
		new_black_hole.position = position
		
		Singleton.level.add_child(new_black_hole)
		health_depleted.emit()
	
	%ProgressBar.value = health


# ----------------------------------------------------------------------------
# CONTROLES DE ANIMAÇOES
# ----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Anima a morte do player.
# Fluxo:
#   1) Evita reentrância (só roda uma vez por vida).
#   2) Interrompe a música (faz fade se disponível via AudioPlayer.fade_out_and_stop).
#   3) Bloqueia input e física do player; desabilita a colisão.
#   4) Executa uma animação de sucção: move até o centro do buraco, gira N voltas
#      e encolhe com curvas de easing internas.
#   5) Ao terminar: remove o player da cena e aciona Game Over.
# Parâmetros:
#   - black_hole_center (Vector2): posição-alvo (centro do buraco negro).
#   - consume_duration (float, seg): duração total da animação de sucção.
#   - total_spins (float): quantas voltas completas o visual da nave dará.
# -----------------------------------------------------------------------------
func start_black_hole_death(
	black_hole_center: Vector2,
	consume_duration : float = 1.5,
	total_spins : float = 13.0
) -> void:
	if Singleton.god_mode:
		return
	if dying_to_black_hole:
		return
	
	dying_to_black_hole = true
	
	_disable_all_turrets()
	%ProgressBar.visible = false
	%SpeedBar.visible = false
	
	if AudioPlayer and AudioPlayer.has_method("fade_out_and_stop"):
		AudioPlayer.fade_out_and_stop(3.0)
	else:
		AudioPlayer.stop_music()
	
	set_process_input(false)
	set_physics_process(false)
	
	if has_node("CollisionShape2D"):
		var collision_shape := $CollisionShape2D
		if collision_shape is CollisionShape2D:
			collision_shape.set_deferred("disabled", true)
	
	var ship_visual: Node2D = self
	
	if has_node("Ship"):
		ship_visual = get_node("Ship") as Node2D
	
	var initial_position := global_position
	var initial_rotation := ship_visual.rotation
	var initial_scale    := scale
	
	# Tween "custom": t vai de 0 -> 1; aplicamos as curvas dentro do método alvo
	var consume_tween := get_tree().create_tween()
	consume_tween.tween_method(
		Callable(self, "_black_hole_consume_step")
			.bind(
				initial_position, 
				black_hole_center, 
				initial_rotation, 
				initial_scale, 
				float(total_spins), ship_visual
			),
		0.0, 1.0, consume_duration
	)
	
	consume_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	
	await consume_tween.finished
	queue_free()
	Singleton.game_over()


# -----------------------------------------------------------------------------
# Passo da animação de “consumo” pelo buraco negro.
# Chamado por tween_method a partir de start_black_hole_death(), este método
# aplica, em cada tick do tween, easings independentes para posição, rotação
# e escala da nave com base em `progress`.
#
# Parâmetros:
#   progress (float) .......... Progresso temporal do tween no intervalo [0.0, 1.0].
#   initial_position (Vector2)  Posição onde a nave iniciou a sucção.
#   black_hole_center (Vector2) Posição alvo (centro do buraco negro).
#   initial_rotation (float)    Rotação inicial do nó visual da nave.
#   initial_scale (Vector2)     Escala inicial da nave.
#   total_spins (float) ....... Número total de voltas completas ao longo da animação.
#   ship_visual (Node2D) ...... Nó visual que efetivamente gira (ex.: %Ship). Pode ser nulo.
#
# Curvas de easing empregadas:
#   - Posição:  t^3   (começa lenta e acelera forte ao final)
#   - Rotação:  t^2   (acelera suavemente o giro)
#   - Escala:   t^2.5 (encolhe mais rapidamente na etapa final)
# -----------------------------------------------------------------------------
func _black_hole_consume_step(
	progress: float,
	initial_position: Vector2,
	black_hole_center: Vector2,
	initial_rotation: float,
	initial_scale: Vector2,
	total_spins: float,
	ship_visual: Node2D
) -> void:
	var eased_position_progress := pow(progress, 3.0)
	var eased_rotation_progress := pow(progress, 2.0)
	var eased_scale_progress := pow(progress, 2.5)
	
	global_position = initial_position.lerp(black_hole_center, eased_position_progress)
	
	if ship_visual:
		ship_visual.rotation = initial_rotation + TAU * total_spins * eased_rotation_progress
	
	scale = initial_scale.lerp(Vector2.ZERO, eased_scale_progress)


# -----------------------------------------------------------------------------
# Desabilita todas as torres (turrets) do player.
# Comportamento:
#   - Itera sobre cada turret conhecido (N, S, E, W, NE, NW, SE, SW).
#   - Se a instância ainda for válida:
#       • Zera `current_bullet`, impedindo disparos futuros.
#       • Se a torre possuir um Timer chamado "ShootingInterval",
#         interrompe-o para garantir que o disparo periódico pare imediatamente.
# -----------------------------------------------------------------------------
func _disable_all_turrets() -> void:
	for direction in turrets.keys():
		var turret = turrets[direction]
		if is_instance_valid(turret):
			turret.current_bullet = 0
			
			if turret.has_node("ShootingInterval"):
				var shoot_timer := turret.get_node("ShootingInterval") as Timer
				if shoot_timer:
					shoot_timer.stop()


func _get_max_health() -> float:
	if get_tree().root.has_node("PlayerUpgrades"):
		max_health = PlayerUpgrades.get_effective_health()
	return max_health


func _apply_health_from_upgrades(preserve_ratio := true, heal_to_full := false) -> void:
	var new_max := _get_max_health()
	var old_max := max_health
	max_health = new_max
	
	# ajusta o HP atual
	if preserve_ratio:
		var ratio := 0.0
		if old_max > 0.0:
			ratio = health / old_max
		if heal_to_full:
			health = new_max
		else:
			health = clamp(ratio * new_max, 0.0, new_max)
	else:
		if health > new_max:
			health = new_max
	
	# sincroniza a barra
	if %ProgressBar:
		%ProgressBar.max_value = new_max
	
	# log de debug
	var bonus := 0.0
	if get_tree().root.has_node("PlayerUpgrades"):
		bonus = PlayerUpgrades.get_shield_bonus()
	
	print("[HEALTH] bonus=", bonus, " max=", new_max, " current=", health)


func _get_speed_cap() -> float:
	var cap := MAX_ACCELERATION
	if get_tree().root.has_node("PlayerUpgrades"):
		cap = PlayerUpgrades.get_effective_max_acceleration()
	return cap


func _apply_speed_from_upgrades() -> void:
	var cap := _get_speed_cap()
	if %SpeedBar:
		%SpeedBar.max_value = cap / 10.0
	var bonus := 0.0
	if get_tree().root.has_node("PlayerUpgrades"):
		bonus = PlayerUpgrades.get_speed_bonus()
	print("[SPEED] bonus=", bonus, " cap=", cap)


func _open_upgrade_picker() -> void:
	if is_instance_valid(Singleton.gui_manager) and Singleton.gui_manager.has_method("open_upgrades_picker"):
		Singleton.gui_manager.open_upgrades_picker()
	else:
		var ui := preload("res://scenes/game/select_upgrades_scene.tscn").instantiate()
		get_tree().root.add_child(ui)
		get_tree().paused = true


func set_selected_weapon(weapon_id: int) -> void:
	selected_weapon_id = clamp(weapon_id, 1, 2)
	_set_all_active_turrets_bullet(selected_weapon_id)


func _set_all_active_turrets_bullet(bullet_id: int) -> void:
	for turret in turrets.values():
		if is_instance_valid(turret) and turret.current_bullet != 0:
			turret.current_bullet = bullet_id
