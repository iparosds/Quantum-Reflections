extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
@onready var game = get_node("/root/Game")
var moving_speed = 0

func _physics_process(delta):
	if int(abs(global_position.distance_to(player.global_position))) < 50:
		game.add_ore()
		queue_free()
	if moving_speed == 0:
		var overlapping = $Hitbox.get_overlapping_bodies()
		for mob in overlapping:
			if mob.has_method("is_player"):
				moving_speed = 100
	elif moving_speed > 0:
		if moving_speed > 1000:
			moving_speed += 3000
		else:
			moving_speed += 300
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * (player.acceleration + moving_speed) * delta
		move_and_slide()

func is_coin():
	return true
