extends CharacterBody2D;

signal health_depleted;
const BLACK_HOLE = preload("res://scenes/black_hole.tscn")
@onready var game = get_node("/root/Game")
var health = 100.0;
const DAMAGE_RATE = 500.0;
var acceleration = 0;
var accelelariting = false;
var stopping = false;
var rotating_right = false;
var rotating_left = false;

func is_player():
	return true;

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
	if game.get_score() > 1:
		%TurretW.current_bullet = 2
	if game.get_score() > 10:
		%TurretS.current_bullet = 1
	if game.get_score() > 50:
		%TurretN.current_bullet = 1
	if game.get_score() > 100:
		%TurretNW.current_bullet = 1
	if game.get_score() > 200:
		%TurretSE.current_bullet = 1
	if game.get_score() > 400:
		%TurretNE.current_bullet = 1
	if game.get_score() > 800:
		%TurretSW.current_bullet = 1

func _ready():
	%TurretN.current_bullet = 0
	%TurretE.current_bullet = 1
	%TurretS.current_bullet = 0
	%TurretW.current_bullet = 0
	%TurretNE.current_bullet = 0
	%TurretNW.current_bullet = 0
	%TurretSE.current_bullet = 0
	%TurretSW.current_bullet = 0

func _physics_process(delta):
	add_turrets()
	if game.quantum == false:
		%Ship.play("default")
	else:
		%Ship.play("quantum")	
	if Input.is_action_just_released("move_up"):
		accelelariting = false
	if Input.is_action_just_pressed("move_up"):
		accelelariting = true
	if accelelariting == true && acceleration < 1000:
		acceleration += 1
	if Input.is_action_just_released("move_down"):
		stopping = false
	if Input.is_action_just_pressed("move_down"):
		stopping = true
	if stopping == true && acceleration > 0:
		acceleration -= 5
	if stopping == false && accelelariting == false && acceleration > 0:
		acceleration -= 1
	if Input.is_action_just_pressed("move_right"):
		rotating_right = true
	if Input.is_action_just_released("move_right"):
		rotating_right = false
	if rotating_right == true:
		%Ship.rotation += 0.1
	if Input.is_action_just_pressed("move_left"):
		rotating_left = true
	if Input.is_action_just_released("move_left"):
		rotating_left = false
	if rotating_left == true:
		%Ship.rotation -= 0.1
		
	if acceleration > 0:
		var direction2 = Vector2.UP.rotated(%Ship.rotation)
		$".".position += direction2 * acceleration * delta
		%SpeedBar.value = acceleration/10

	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	for mob in overlapping_mobs:
		health -= DAMAGE_RATE * delta
		mob.queue_free()
	var overlapping_ores = %CollectOre.get_overlapping_bodies()
	for mob in overlapping_ores:
		if mob.has_method("take_damage"):
			game.add_ore()
			mob.queue_free()
	if health <= 0.0:
		health = 100
		game.quantum = true
		var new_black_hole = BLACK_HOLE.instantiate()
		new_black_hole.position = $".".position
		game.add_child(new_black_hole)
		health_depleted.emit()
	%ProgressBar.value = health
