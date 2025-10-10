class_name SoundIcon extends CanvasLayer

const MASTER_BUS_NAME := "Master"
const ICON_OFF := preload("res://assets/sprites/icons/sound-off.svg")
const ICON_ON := preload("res://assets/sprites/icons/sound-loud.svg")

@onready var sound_toggle_button : TextureButton = $VBoxContainer/Sound_Toggle_Button
@onready var master_bus_index : int = AudioServer.get_bus_index(MASTER_BUS_NAME)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_icon(_is_master_muted())
	


func _on_sound_toggle_button_pressed() -> void:
	_set_master_muted(not _is_master_muted())
	_update_icon(_is_master_muted())


func _is_master_muted() -> bool:
	return AudioServer.is_bus_mute(master_bus_index)


func _set_master_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(master_bus_index, muted)


func _update_icon(is_muted: bool) -> void:
	sound_toggle_button.texture_normal = ICON_OFF if is_muted else ICON_ON
