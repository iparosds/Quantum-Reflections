extends Control

@onready var resolutions = $MarginContainer/VBoxContainer/Resolutions as OptionButton
@onready var back = $Back as OptionButton


func _ready():
	$menu_music.play()
	resolutions.grab_focus()

func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600,980))
		2:
			DisplayServer.window_set_size(Vector2i(1280,720))
		3:
			DisplayServer.window_set_size(Vector2i(1152,648))

func _on_back_pressed() -> void:
	$select_sound.play()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
func _on_back_mouse_entered() -> void:
	$down_sound.play()
