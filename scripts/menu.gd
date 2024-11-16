class_name Menu
extends Control

@onready var new_game_button =preload("res://scenes/game.tscn") as PackedScene
@onready var settings = $MarginContainer/VBoxContainer/Settings as Button
@onready var rewards = $MarginContainer/VBoxContainer/Rewards as Button
@onready var credits = $MarginContainer/VBoxContainer/Credits as Button
@onready var start = $"MarginContainer/VBoxContainer/START!" as Button
@onready var quit = $MarginContainer/VBoxContainer/Quit as Button

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_packed(new_game_button)

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
