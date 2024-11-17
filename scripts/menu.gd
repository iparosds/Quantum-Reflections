class_name Menu
extends Control

@onready var new_game_button =$MarginContainer/VBoxContainer/New_Game as Button
@onready var settings = $MarginContainer/VBoxContainer/Settings as Button
@onready var rewards = $MarginContainer/VBoxContainer/Rewards as Button
@onready var credits = $MarginContainer/VBoxContainer/Credits as Button
@onready var start = $"MarginContainer/VBoxContainer/START!" as Button
@onready var quit = $MarginContainer/VBoxContainer/Quit as Button
@onready var start_game =preload("res://scenes/game.tscn") as PackedScene

func _ready():
	$menu_music.play()
	new_game_button.grab_focus()

func _on_new_game_pressed() -> void:
	$select_sound.play()
	get_tree().change_scene_to_packed(start_game)

func _on_settings_pressed() -> void:
	$select_sound.play()
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")

func _on_rewards_pressed() -> void:
	$select_sound.play()

func _on_credits_pressed() -> void:
	$select_sound.play()

func _on_start_pressed() -> void:
	$select_sound.play()

func _on_quit_pressed() -> void:
	$select_sound.play()
	get_tree().quit()


func _physics_process(delta):
	if Input.is_action_just_pressed("move_up"):
		$up_sound.play()
	if Input.is_action_just_pressed("move_down"):
		$down_sound.play()
	if Input.is_action_just_pressed("enter"):
		$select_sound.play()


func _on_new_game_mouse_entered() -> void:
	$down_sound.play()
func _on_settings_mouse_entered() -> void:
	$down_sound.play()
func _on_rewards_mouse_entered() -> void:
	$down_sound.play()
func _on_credits_mouse_entered() -> void:
	$down_sound.play()
func _on_start_mouse_entered() -> void:
	$down_sound.play()
func _on_quit_mouse_entered() -> void:
	$down_sound.play()
