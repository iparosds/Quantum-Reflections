class_name Turret extends Area2D

const BULLET_1 = preload("res://scenes/game/bullet.tscn")
const BULLET_2 = preload("res://scenes/game/bullet_2.tscn")

@export var projectile : Projectile
@export var projectiles_parent_group = "projectile_parent"

var projectiles_node : Node
var cooldown = false
var current_bullet = 0;


func try_shoot() -> bool:
	push_error("Not implemented")
	return false


func _ready() -> void:
	projectiles_node = get_tree().get_first_node_in_group(projectiles_parent_group)
	assert(projectiles_node != null, "Projectiles node is required")


func shoot(target_enemy):
	var shot_stream: AudioStream = $AudioStreamPlayer2D.stream
	AudioPlayer.play_shot(shot_stream, true, 6.0)
	$AudioStreamPlayer2D.stop()
	
	var new_bullet = projectile.scene.instantiate()
	if current_bullet == 1:
		new_bullet = BULLET_1.instantiate()
	else:
		new_bullet = BULLET_2.instantiate()
	#new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.position = %ShootingPoint.position
	new_bullet.rotation = %ShootingPoint.rotation
	new_bullet.target = target_enemy
	%ShootingPoint.add_child(new_bullet)
	#projectiles_node.add_child(new_bullet)

func _physics_process(_delta):
	if cooldown == false && current_bullet != 0:
		var enemies_in_range = get_overlapping_bodies()
		if enemies_in_range.size() > 0:
			var target_enemy = enemies_in_range.front()
			shoot(target_enemy)
			$ShootingInterval.start()
			cooldown = true
			#look_at(target_enemy.global_position)

func _on_timer_timeout():
	cooldown = false
