class_name Menu
extends Control

@onready var start_level = preload("res://scenes/game.tscn") as PackedScene

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_packed(start_level)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")

func _on_rewards_pressed() -> void:
	pass # Replace with function body.

func _on_credits_pressed() -> void:
	pass # Replace with function body.

func _on_start_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	get_tree().quit()
