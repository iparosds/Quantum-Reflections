class_name Player extends CharacterBody2D

const BLACK_HOLE = preload("res://scenes/game/black_hole.tscn")
const DAMAGE_RATE = 500.0
const MAX_ACCELERATION = 1000.0

# Mapa de direção -> nó da turret
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
	
	if is_instance_valid(turrets["E"]):
		turrets["E"].current_bullet = 1
	
	call_deferred("_init_level_progress")


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
	
	if target_index > current_level_index:
		_apply_level_up_to(target_index, true)
		current_level_index = target_index


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
				turret_node.current_bullet = 1
		
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
			mob.player_collision()
	
	var overlapping_ores = %CollectOre.get_overlapping_bodies()
	for mob in overlapping_ores:
		if mob.has_method("is_coin"):
			Singleton.level.add_ore()
			mob.queue_free()
	
	if health <= 0.0:
		health = 100
		Singleton.level.quantum = true
		var new_black_hole = BLACK_HOLE.instantiate()
		new_black_hole.position = position
		Singleton.level.add_child(new_black_hole)
		health_depleted.emit()
	
	%ProgressBar.value = health
