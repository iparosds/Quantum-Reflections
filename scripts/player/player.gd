class_name Player extends CharacterBody2D;

const BLACK_HOLE = preload("res://scenes/game/black_hole.tscn")
const DAMAGE_RATE = 500.0;
const MAX_ACCELERATION = 1000.0

var health = 100.0;
var acceleration = 0.0;
var accelelariting = false;
var boosting = false;
var stopping = false;
var rotating_right = false;
var rotating_left = false;
var level

signal health_depleted;


func _ready():
	Singleton.player = self
	
	%TurretN.current_bullet = 0
	%TurretE.current_bullet = 1
	%TurretS.current_bullet = 0
	%TurretW.current_bullet = 0
	%TurretNE.current_bullet = 0
	%TurretNW.current_bullet = 0
	%TurretSE.current_bullet = 0
	%TurretSW.current_bullet = 0


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
	if %TurretN.current_bullet != 0:
		%TurretN.current_bullet = randi_range(1,2)
	if %TurretE.current_bullet != 0:
		%TurretE.current_bullet = randi_range(1,2)
	if %TurretS.current_bullet != 0:
		%TurretS.current_bullet = randi_range(1,2)
	if %TurretW.current_bullet != 0:
		%TurretW.current_bullet = randi_range(1,2)
	if %TurretNE.current_bullet != 0:
		%TurretNE.current_bullet = randi_range(1,2)
	if %TurretNW.current_bullet != 0:
		%TurretNW.current_bullet = randi_range(1,2)
	if %TurretSE.current_bullet != 0:
		%TurretSE.current_bullet = randi_range(1,2)
	if %TurretSW.current_bullet != 0:
		%TurretSW.current_bullet = randi_range(1,2)
	pass


func add_turrets():
	if Singleton.level.get_score() > 10:
		%TurretW.current_bullet = 1
	if Singleton.level.get_score() > 50:
		%TurretS.current_bullet = 1
	if Singleton.level.get_score() > 100:
		%TurretN.current_bullet = 1
	if Singleton.level.get_score() > 200:
		%TurretNW.current_bullet = 1
	if Singleton.level.get_score() > 400:
		%TurretSE.current_bullet = 1
	if Singleton.level.get_score() > 600:
		%TurretNE.current_bullet = 1
	if Singleton.level.get_score() > 800:
		%TurretSW.current_bullet = 1


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
