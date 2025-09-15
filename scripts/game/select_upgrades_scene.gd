extends Control

@onready var upgrade_card_container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	get_tree().paused = true
	for node in upgrade_card_container.get_children():
		Singleton.upgrades_card.upgrade_selected.connect(_quit)


func _input(event: InputEvent) -> void:
	var mousePosition = get_global_mouse_position()
	
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
		for node in upgrade_card_container.get_children():
			if node.get_global_rect().has_point(mousePosition):
				Singleton.upgrades_card.apply_upgrade()


func _quit():
	get_tree().paused = false
	queue_free()
