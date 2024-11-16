extends CharacterBody2D;

signal health_depleted;

var health = 100.0;
const DAMAGE_RATE = 500.0;
var acceleration = 0;
var accelelariting = false;
var stopping = false;
var rotating_right = false;
var rotating_left = false;

func _physics_process(delta):
	if Input.is_action_just_released("move_up"):
		accelelariting = false
	if Input.is_action_just_pressed("move_up"):
		accelelariting = true
	if accelelariting == true && acceleration < 2000:
		acceleration += 1
	if Input.is_action_just_released("move_down"):
		stopping = false
	if Input.is_action_just_pressed("move_down"):
		stopping = true
	if stopping == true && acceleration > 0:
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

	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	for mob in overlapping_mobs:
		health -= DAMAGE_RATE * delta
		mob.queue_free()
	if health <= 0.0:
		health_depleted.emit()
	%ProgressBar.value = health
