extends CanvasLayer

@onready var sound_toggle_button: TextureButton = $VBoxContainer/Sound_Toggle_Button
var sound_muted: bool = false
const ICON_OFF := preload("res://assets/sprites/sound-off.svg")
const ICON_ON  := preload("res://assets/sprites/sound-loud.svg")


func _ready() -> void:
	var is_muted := AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	_sync(is_muted)


func _on_sound_toggle_button_pressed() -> void:
	var next := !AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), next)
	_sync(next)


func _sync(is_muted: bool) -> void:
	if is_muted:
		sound_toggle_button.texture_normal = ICON_OFF
	else:
		sound_toggle_button.texture_normal = ICON_ON
