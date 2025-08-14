extends Control

@onready var input_button_scene := preload("res://scenes/input_button.tscn")
@onready var action_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ActionList

var is_remapping: bool = false
var action_to_remap: String = ""
var remapping_button: Node = null
const SAVE_PATH := "user://input_settings.cfg"

var input_actions := {
	"move_up": "Move up",
	"move_right": "Move right",
	"move_down": "Move down",
	"move_left": "Move left",
	"pause": "Pause",
	"enter": "Enter",
	"back": "Back",
	"boost": "Boost",
	"god": "God",
}

func _ready() -> void:
	_load_input_map()        # aplica do arquivo, se existir
	_create_action_list()    # só constrói a UI (NÃO reseta o InputMap)

# ---------- UI ----------
func _create_action_list() -> void:
	for item in action_list.get_children():
		item.queue_free()

	for action in input_actions:
		var button := input_button_scene.instantiate()
		var action_label := button.find_child("LabelAction")
		var input_label := button.find_child("LabelInput")
		action_label.text = input_actions[action]

		var events := InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""

		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))

func _on_input_button_pressed(button: Node, action: String) -> void:
	if not is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press key to bind..."

func _input(event: InputEvent) -> void:
	if is_remapping and (event is InputEventKey or (event is InputEventMouseButton and event.pressed)):
		if event is InputEventMouseButton and event.double_click:
			event.double_click = false

		InputMap.action_erase_events(action_to_remap)
		InputMap.action_add_event(action_to_remap, event)
		_update_action_list(remapping_button, event)

		is_remapping = false
		action_to_remap = ""
		remapping_button = null
		accept_event()

func _update_action_list(button: Node, event: InputEvent) -> void:
	var label := button.find_child("LabelInput")
	label.text = event.as_text().trim_suffix(" (Physical)")

func _on_reset_button_pressed() -> void:
	# Volta aos padrões do projeto
	InputMap.load_from_project_settings()
	_delete_user_file()
	_create_action_list()

# ---------- Persistência ----------
func _save_input_map(clear_file: bool = false) -> void:
	var cfg := ConfigFile.new()
	if not clear_file:
		for action in input_actions.keys():
			var arr: Array = []
			for e in InputMap.action_get_events(action):
				if e is InputEventKey:
					arr.append({
						"type": "key",
						"physical_keycode": e.physical_keycode,
						"keycode": e.keycode,
						"alt": e.alt_pressed,
						"shift": e.shift_pressed,
						"ctrl": e.ctrl_pressed,
						"meta": e.meta_pressed,
					})
				elif e is InputEventMouseButton:
					arr.append({
						"type": "mouse",
						"button_index": e.button_index,
					})
			cfg.set_value("input", action, arr)
	cfg.save(SAVE_PATH)
	# DEBUG opcional
	#print("Salvo em: ", SAVE_PATH)

func _load_input_map() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # primeira execução: nada salvo ainda

	for action in input_actions.keys():
		if cfg.has_section_key("input", action):
			InputMap.action_erase_events(action)
			var arr: Array = cfg.get_value("input", action, [])
			for d in arr:
				var ev: InputEvent = null
				match d.get("type", ""):
					"key":
						var k := InputEventKey.new()
						k.physical_keycode = int(d.get("physical_keycode", 0))
						k.keycode = int(d.get("keycode", 0))
						k.alt_pressed = bool(d.get("alt", false))
						k.shift_pressed = bool(d.get("shift", false))
						k.ctrl_pressed = bool(d.get("ctrl", false))
						k.meta_pressed = bool(d.get("meta", false))
						ev = k
					"mouse":
						var m := InputEventMouseButton.new()
						m.button_index = int(d.get("button_index", 1))
						ev = m
				if ev != null:
					InputMap.action_add_event(action, ev)

# ---------- Utilidades ----------
func _delete_user_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# (opcional) logar no console o que está carregado
func _debug_dump_map() -> void:
	for action in input_actions.keys():
		var texts := []
		for e in InputMap.action_get_events(action):
			texts.append(e.as_text())
		print(action, " => ", texts)


func _on_save_config_button_pressed() -> void:
	_save_input_map()
	print("Configurações de controles salvas em: ", SAVE_PATH)


func _on_back_to_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_menu.tscn")
