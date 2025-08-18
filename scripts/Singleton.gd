extends Node2D

const GAME_SCENE := preload("res://scenes/game.tscn")

var gui_manager: GuiManager = null 
var quantum := false
var closest_distance := 1000

@onready var closest_enemy := find_closest_enemy()


# GUI
func start_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(GAME_SCENE)


func continue_game() -> void:
	pass


func load_game() -> void:
	pass


func save_game() -> void:
	pass


func open_settings() -> void:
	if gui_manager:
		gui_manager.show_settings()


func open_credits() -> void:
	if gui_manager:
		gui_manager.show_credits()


func open_main_menu() -> void:
	get_tree().paused = false
	if gui_manager:
		gui_manager.show_main_menu()
		AudioPlayer._play_menu_music()


func open_controls() -> void:
	get_tree().change_scene_to_file("res://scenes/input_settings.tscn")


func set_master_volume_db(db_value: float) -> void:
	AudioServer.set_bus_volume_db(0, db_value)


func quit_game() -> void:
	get_tree().quit()


func display_number(value: int, text_position: Vector2, text_color: String):
	var number := Label.new()
	number.global_position = text_position
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	number.label_settings.font_color = text_color
	number.label_settings.font_size = 16
	
	call_deferred("add_child", number)
	
	await number.resized
	number.pivot_offset = Vector2(number.size / 2)
	
	var tween := get_tree().create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y - 12, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "position:y", number.position.y, 0.25).set_ease(Tween.EASE_IN).set_delay(0.25)
	tween.tween_property(number, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN).set_delay(0.5)
	
	await tween.finished
	number.queue_free()


func find_closest_enemy() -> Object:
	var all_enemy := get_tree().get_nodes_in_group("asteroid")
	
	for enemy in all_enemy:
		var gun2enemy_distance := position.distance_to(enemy.position)
		if gun2enemy_distance < closest_distance:
			closest_distance = gun2enemy_distance
			closest_enemy = enemy
	
	return closest_enemy


func _process(_delta: float) -> void:
	closest_enemy = find_closest_enemy()
