extends Node2D

var quantum = false;
var closestDistance = 1000
@onready var closestEnemy = find_closest_enemy()

func display_number(value: int, text_position: Vector2, text_color: String):
	var number = Label.new()
	number.global_position = text_position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	number.label_settings.font_color = text_color
	number.label_settings.font_size = 16
	call_deferred("add_child", number)

	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 12, 0.25
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		number, "position:y", number.position.y, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(
		number, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number.queue_free()

func find_closest_enemy() -> Object:
	var all_enemy = get_tree().get_nodes_in_group("asteroid")
	for enemy in all_enemy:
		var gun2enemy_distance = position.distance_to(enemy.position)
		if gun2enemy_distance < closestDistance:
			closestDistance = gun2enemy_distance
			closestEnemy = enemy
	return closestEnemy

func _process(_delta):
	closestEnemy = find_closest_enemy()
