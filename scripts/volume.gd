extends Control

@onready var back = $Back as Button

func _ready():
	back.grab_focus()

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value)
func _on_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0,toggled_on)

func _on_back_pressed() -> void:
	$select_sound.play()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_back_mouse_entered() -> void:
	$down_sound.play()
