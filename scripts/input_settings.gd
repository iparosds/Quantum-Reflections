extends Control

const SAVE_PATH := "user://input_settings.cfg"
const CONFIG_SECTION_INPUT := "input"

@onready var input_button_scene := preload("res://scenes/input_button.tscn")
@onready var action_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ActionList
@onready var save_config_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SaveConfigButton

var is_remapping: bool = false
var action_to_remap: String = ""
var remapping_button: Node = null

# Obs.: o InputMap precisa ter essas ações previamente criadas (Project Settings).
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
	save_config_button.grab_focus()
	_load_input_map()
	_create_action_list()


func _on_save_config_button_pressed() -> void:
	_save_input_map()


func _on_reset_button_pressed() -> void:
	InputMap.load_from_project_settings()
	_delete_user_file()
	_create_action_list()


# ---------------------------------------------------------------------
# - Inicia o processo de remapeamento para a ação clicada.
# - Atualiza o label da linha para instruir o usuário.
# - Usa variáveis de estado para o _input() saber o que aplicar.
# ---------------------------------------------------------------------
func _on_input_button_pressed(button: Node, action: String) -> void:
	if not is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press key to bind..."


# ---------------------------------------------------------------------
# - Reconstrói a lista inteira:
#   * Remove linhas existentes.
#   * Instancia um botão/linha por ação.
#   * Preenche rótulos com o estado atual do InputMap.
#   * Conecta o sinal 'pressed' passando o botão e o nome da ação.
# ---------------------------------------------------------------------
func _create_action_list() -> void:
	for item in action_list.get_children():
		item.queue_free()
	
	for action in input_actions:
		var button := input_button_scene.instantiate()
		var action_label := button.find_child("LabelAction")
		var input_label := button.find_child("LabelInput")
		action_label.text = input_actions[action]
		
		# Pega os eventos atuais da ação.
		var events := InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
		
		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))


func _update_action_list(button: Node, event: InputEvent) -> void:
	var label := button.find_child("LabelInput")
	label.text = event.as_text().trim_suffix(" (Physical)")


# ---------------------------------------------------------------------
# - Se estamos em modo de remapeamento, captura a próxima tecla
#   (InputEventKey) ou clique de mouse (InputEventMouseButton).
# - Remove "double_click" para não duplicar o disparo com mouse.
# - Aplica no InputMap, atualiza a linha e sai do modo de remapeamento.
# ---------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if is_remapping and (event is InputEventKey or (event is InputEventMouseButton and event.pressed)):
		if event is InputEventMouseButton and event.double_click:
			event.double_click = false
		
		# substitui todos os eventos da ação
		InputMap.action_erase_events(action_to_remap)
		InputMap.action_add_event(action_to_remap, event)
		_update_action_list(remapping_button, event)
		
		is_remapping = false
		action_to_remap = ""
		remapping_button = null
		
		# evita propagação do input para outros nós
		accept_event()


# ---------------------------------------------------------------------
# - Salva o estado do InputMap para o arquivo SAVE_PATH.
# ---------------------------------------------------------------------
func _save_input_map(should_clear_file: bool = false) -> void:
	var config := ConfigFile.new()
	
	if not should_clear_file:
		for action_name in input_actions.keys():
			var serialized_events: Array = []
			for input_event in InputMap.action_get_events(action_name):
				# converte InputEvent -> Dictionary simples
				var data := _serialize_event(input_event)
				if data.size() > 0:
					serialized_events.append(data)
			config.set_value(CONFIG_SECTION_INPUT, action_name, serialized_events)
	
	config.save(SAVE_PATH)


# ---------------------------------------------------------------------
# - Lê o arquivo de configuração, e para cada ação encontrada:
#   * apaga eventos atuais da ação
#   * recria InputEvent(s) a partir dos dicionários salvos
# ---------------------------------------------------------------------
func _load_input_map() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	
	for action_name in input_actions.keys():
		if config.has_section_key(CONFIG_SECTION_INPUT, action_name):
			InputMap.action_erase_events(action_name)
			
			var serialized_events: Array = config.get_value(CONFIG_SECTION_INPUT, action_name, [])
			for event_data in serialized_events:
				# converte Dictionary para InputEvent
				var event_to_add := _deserialize_event(event_data)
				if event_to_add != null:
					InputMap.action_add_event(action_name, event_to_add)


# ---------------------------------------------------------------------
# - Transforma um InputEvent específico em Dictionary (somente tipos
#   suportados aqui: teclado e mouse).
# ---------------------------------------------------------------------
func _serialize_event(input_event: InputEvent) -> Dictionary:
	if input_event is InputEventKey:
		return {
			"type": "key",
			# scancode físico (layout independente)
			"physical_keycode": input_event.physical_keycode,
			# scancode lógico (respeita layout)
			"keycode": input_event.keycode,
			"alt": input_event.alt_pressed,
			"shift": input_event.shift_pressed,
			"ctrl": input_event.ctrl_pressed,
			"meta": input_event.meta_pressed,
		}
	elif input_event is InputEventMouseButton:
		return {
			"type": "mouse",
			"button_index": input_event.button_index,
		}
	
	# Caso não suportado: retorna vazio e é ignorado no save.
	return {}


# ---------------------------------------------------------------------
# - Reconstrói InputEvent a partir do Dictionary salvo no arquivo.
# - Retorna null em caso de tipo desconhecido (ignorado no load).
# ---------------------------------------------------------------------
func _deserialize_event(event_data: Dictionary) -> InputEvent:
	match event_data.get("type", ""):
		"key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(event_data.get("physical_keycode", 0))
			key_event.keycode = int(event_data.get("keycode", 0))
			key_event.alt_pressed = bool(event_data.get("alt", false))
			key_event.shift_pressed = bool(event_data.get("shift", false))
			key_event.ctrl_pressed = bool(event_data.get("ctrl", false))
			key_event.meta_pressed = bool(event_data.get("meta", false))
			return key_event
		"mouse":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = int(event_data.get("button_index", 1))
			return mouse_event
	return null


# ---------------------------------------------------------------------
# - Remove o arquivo de configuração do usuário, se existir.
# - Usado no reset para garantir retorno ao default sem resíduos.
# ---------------------------------------------------------------------
func _delete_user_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
