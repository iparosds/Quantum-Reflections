extends CanvasLayer

@onready var volume: HSlider = $MarginContainer/ButtonsContainer/Volume
@onready var back: Button = $MarginContainer/ButtonsContainer/Back


func _ready():
	back.grab_focus()


func _on_volume_pressed() -> void:
	$select_sound.play()


func _on_volume_mouse_entered() -> void:
	$down_sound.play()


func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,value)


func _on_back_pressed() -> void:
	$select_sound.play()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_back_mouse_entered() -> void:
	$down_sound.play()


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
