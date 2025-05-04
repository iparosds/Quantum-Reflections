extends Control

@onready var player: CharacterBody2D = %Player

@onready var weapons = get_node("/root/Game/Weapons")

@onready var option_buttons = [
	$PanelContainer/VBoxContainer/Option1,
	$PanelContainer/VBoxContainer/Option2,
	$PanelContainer/VBoxContainer/Option3
]

func setup_random_options():
	var shuffled = weapons.weapons.duplicate()
	shuffled.shuffle()
	
	# Verifica se há armas suficientes para preencher os botões
	var min_size = min(option_buttons.size(), shuffled.size())

	for i in range(min_size):
		var weapon = shuffled[i]
		option_buttons[i].text = weapon.name
		option_buttons[i].icon = weapon.icon
		option_buttons[i].set_meta("weapon_script", weapon.script)

		# Verifica se o sinal já está conectado
		# if not option_buttons[i].is_connected("pressed", Callable(self, "_on_weapon_selected")):
		#	option_buttons[i].connect("pressed", Callable(self, "_on_weapon_selected").bind(option_buttons[i]))

#func _on_weapon_selected(button):
func on_weapon_selected():
	print("select weapon")
	#var weapon_script = button.get_meta("weapon_script")
	#player.add_weapon(weapon_script)
	hide()  # Esconde o menu
	get_tree().paused = false


func _on_option_1_pressed() -> void:
	print("select weapon")
	hide()  # Esconde o menu
	get_tree().paused = false
