class_name Bullet4 extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spawn_timer: Timer = $SpawnTimer
@onready var sprite_2d: Sprite2D = $Sprite2D

var respawn_seconds: float = 0.5
var insta_kill_amount: float = 99999.0
var orbit_radius: float = 100.0
var angular_speed : float = 600.0
var angle_degree : float = 0.0
var player: Player
var active: bool = true


# Inicializa conexões e configurações do drone.
func _ready() -> void:
	spawn_timer.wait_time = respawn_seconds
	spawn_timer.one_shot = true
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	if player == null and is_instance_valid(Singleton.player):
		player = Singleton.player
	monitoring = true
	monitorable = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


# Atualiza a rotação e posição do drone ao redor do player a cada frame.
func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	angle_degree += angular_speed * delta
	if angle_degree >= 360.0:
		angle_degree -= 360.0
	# Gira em volta do player sem ser afetado pela rotação da nave
	global_position = player.global_position + Vector2.RIGHT.rotated(deg_to_rad(angle_degree)) * orbit_radius


# Detecta colisão com um corpo e aplica dano.
func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if body and body.has_method("take_damage"):
		active = false
		collision_shape.set_deferred("disabled", true)
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		body.take_damage(insta_kill_amount, 1.0)
		sprite_2d.hide()
		if spawn_timer.is_stopped():
			spawn_timer.start()


# Reativa o drone após o tempo de recarga do spawn_timer.
func _on_spawn_timer_timeout() -> void:
	active = true
	collision_shape.set_deferred("disabled", false)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	sprite_2d.show()
