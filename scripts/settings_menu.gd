extends Control

@onready var controls =$MarginContainer/VBoxContainer/Controls as Button
@onready var volume = $MarginContainer/VBoxContainer/Volume as Button
@onready var back = $MarginContainer/VBoxContainer/Back as Button

func _ready():
	$menu_music.play()
	controls.grab_focus()

func _on_controls_pressed() -> void:
	pass # Replace with function body.

func _on_volume_pressed() -> void:
	pass # Replace with function body.

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _physics_process(delta):
	if Input.is_action_just_pressed("move_up"):
		$up_sound.play()
	if Input.is_action_just_pressed("move_down"):
		$down_sound.play()
	if Input.is_action_just_pressed("enter"):
		$select_sound.play()
	if Input.is_action_just_pressed("back"):
		$back_sound.play()
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
