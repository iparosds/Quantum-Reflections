extends Node2D

@onready var back = $Back as Button

func _ready():
	back.grab_focus()
	
func _on_back_pressed() -> void:
	$select_sound.play()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_back_mouse_entered() -> void:
	$down_sound.play()
