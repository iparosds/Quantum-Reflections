extends CharacterBody2D;

signal health_depleted;

var health = 100.0;
const DAMAGE_RATE = 500.0;
const VELOCITY = 600;

func _physics_process(delta):
	var direction = Input.get_vector(
		"move_left", 
		"move_right", 
		"move_up", 
		"move_down"
	);
	velocity = direction * VELOCITY;
	move_and_slide();

	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		%ProgressBar.value = health
		if health <= 0.0:
			health_depleted.emit()
