class_name Turret
extends Area2D

@export var projectile : Projectile
@export var projectiles_parent_group = "projectile_parent"
var projectiles_node : Node

@onready var game = get_node("/root/Game")
const BULLET_1 = preload("res://scenes/bullet.tscn")
const BULLET_2 = preload("res://scenes/bullet_2.tscn")
var current_bullet = 0;

func try_shoot() -> bool:
	push_error("Not implemented")
	return false

func _ready() -> void:
	projectiles_node = get_tree().get_first_node_in_group(projectiles_parent_group)
	assert(projectiles_node != null, "Projectiles node is required")

func shoot():
	var new_bullet = projectile.scene.instantiate()
	if current_bullet == 1:
		new_bullet = BULLET_1.instantiate()
	else:
		new_bullet = BULLET_2.instantiate()
	#projectiles_node.add_child(new_bullet)
	#new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.position = %ShootingPoint.position
	new_bullet.rotation = %ShootingPoint.rotation
	%ShootingPoint.add_child(new_bullet)

func _physics_process(delta):
	if current_bullet != 0:
		var enemies_in_range = get_overlapping_bodies()
		if enemies_in_range.size() > 0:
			var target_enemy = enemies_in_range.front()
			#look_at(target_enemy.global_position)

func _on_timer_timeout():
	if current_bullet != 0:
		shoot()
