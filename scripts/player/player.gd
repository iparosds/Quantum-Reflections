class_name Player extends CharacterBody2D;

const BLACK_HOLE = preload("res://scenes/game/black_hole.tscn")
const DAMAGE_RATE = 500.0;
const MAX_ACCELERATION = 1000.0

# thresholds para “ligar” cada turret conforme o score
const TURRET_THRESHOLDS: Dictionary = {
	"W":  10,
	"S":  50,
	"N":  100,
	"NW": 200,
	"SE": 400,
	"NE": 600,
	"SW": 800,
}

@onready var turrets: Dictionary = {
	"N":  %TurretN,
	"E":  %TurretE,
	"S":  %TurretS,
	"W":  %TurretW,
	"NE": %TurretNE,
	"NW": %TurretNW,
	"SE": %TurretSE,
	"SW": %TurretSW
}

var health = 100.0;
var acceleration = 0.0;
var accelelariting = false;
var boosting = false;
var stopping = false;
var rotating_right = false;
var rotating_left = false;
var level
var dying_to_black_hole := false

signal health_depleted;


func _ready():
	Singleton.player = self
	
	for turret in turrets.values():
		if is_instance_valid(turret):
			turret.current_bullet = 0
	
	if is_instance_valid(turrets["E"]):
		turrets["E"].current_bullet = 1


func is_player():
	return true;


func world_limit(size):
	var player_position = global_position
	var vx = 563 - player_position.x
	var vy = 339 - player_position.y
	var length = sqrt(vx*vx + vy*vy)
	global_position.x = vx / length * size + 563
	global_position.y = vy / length * size + 339


func portal():
	for turret in turrets.values():
		if is_instance_valid(turret) and turret.current_bullet != 0:
			turret.current_bullet = randi_range(1, 2)


func add_turrets():
	var score = Singleton.level.get_score()
	for direction in TURRET_THRESHOLDS.keys():
		var turret = turrets[direction]
		if is_instance_valid(turret) and score > TURRET_THRESHOLDS[direction]:
			turret.current_bullet = 1


func _physics_process(delta):
	add_turrets()
	
	if Singleton.quantum == false:
		%Ship.play("default")
	else:
		%Ship.play("quantum")	
	if Input.is_action_just_released("move_up"):
		accelelariting = false
	if Input.is_action_just_pressed("move_up"):
		accelelariting = true
	if Input.is_action_just_released("boost"):
		boosting = false
	if Input.is_action_just_pressed("boost"):
		boosting = true
	if accelelariting == true && stopping == false && acceleration < 1000:
		acceleration += 1
	if boosting == true && stopping == false && acceleration < 990:
		acceleration += 5
	if Input.is_action_just_released("move_down"):
		stopping = false
	if Input.is_action_just_pressed("move_down"):
		stopping = true
	if stopping == true && accelelariting == false && acceleration > 10:
		acceleration -= 5
	if stopping == false && accelelariting == false && acceleration > 0:
		acceleration -= 1
	if Input.is_action_just_pressed("move_right"):
		rotating_right = true
	if Input.is_action_just_released("move_right"):
		rotating_right = false
	if Input.is_action_just_pressed("move_left"):
		rotating_left = true
	if Input.is_action_just_released("move_left"):
		rotating_left = false
	if rotating_right == true && boosting == false:
		%Ship.rotation += (1000-(acceleration/2))/10000.0
	if rotating_left == true && boosting == false:
		%Ship.rotation -= (1000-(acceleration/2))/10000.0
		
	if acceleration > 0:
		var direction2 = Vector2.UP.rotated(%Ship.rotation)
		$".".position += direction2 * (acceleration/2) * delta
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
			mob.player_collision()
#		mob.queue_free()
	var overlapping_ores = %CollectOre.get_overlapping_bodies()
	for mob in overlapping_ores:
		if mob.has_method("is_coin"):
			Singleton.level.add_ore()
			mob.queue_free()
	if health <= 0.0:
		health = 100
		Singleton.level.quantum = true
		var new_black_hole = BLACK_HOLE.instantiate()
		new_black_hole.position = $".".position
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
