class_name InputSettings extends Control

const SAVE_PATH := "user://input_settings.cfg"
const CONFIG_SECTION_INPUT := "input"

@onready var input_button_scene := preload("res://scenes/menus/input_button.tscn")
@onready var action_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ActionList
@onready var save_config_button: Button = $PanelContainer/MarginContainer/VBoxContainer/SaveConfigButton

var is_remapping: bool = false
var action_to_remap: String = ""
var remapping_button: Node = null
var remap_armed : bool = false

# Obs.: o InputMap precisa ter essas ações preventiamente criadas (Project Settings).
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
		remap_armed = false
		action_to_remap = action
		remapping_button = button
		
		# limpa estado visual anterior, se houver
		_set_error_ui(button, false)
		button.find_child("LabelInput").text = "Press key to bind..."
		call_deferred("_enable_remap_capture")


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
	# só captura se estiver remapeando
	if not is_remapping or not remap_armed:
		return
	
	# --- Allowlist dos tipos aceitos ---
	var is_key := event is InputEventKey
	var is_mouse_btn := event is InputEventMouseButton
	var is_pad_btn := event is InputEventJoypadButton
	
	if not (is_key or is_mouse_btn or is_pad_btn):
		return
	
	if is_key and not event.pressed:
		return
	if is_mouse_btn and not event.pressed:
		return
	if is_pad_btn and not event.pressed:
		return
	
	# evita duplicidade por double click no mouse
	if is_mouse_btn and event.double_click:
		event.double_click = false
	
	var conflict_with := _is_event_in_use(event, action_to_remap)
	if conflict_with != "":
		if remapping_button:
			var label := remapping_button.find_child("LabelInput")
			if label:
				label.text = "Shortcut already in use. Try another one."
			_set_error_ui(remapping_button, true)
		
		accept_event()
		return
	
	# aplica o novo atalho
	InputMap.action_erase_events(action_to_remap)
	InputMap.action_add_event(action_to_remap, event)
	_update_action_list(remapping_button, event)
	
	# restaura UI (cor padrão + largura original)
	if remapping_button:
		_set_error_ui(remapping_button, false)
		
	# encerra remapeamento
	is_remapping = false
	remap_armed = false
	action_to_remap = ""
	remapping_button = null
	
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


# -----------------------------------------------------------------------------
# Ativa a captura de entradas no próximo frame para o fluxo de remapeamento.
# Contexto:
#   - Deve ser chamada via `call_deferred("_enable_remap_capture")` logo após
#     o usuário clicar no botão de remap (evita capturar o próprio clique/motion).
# Efeito:
#   - Define `remap_armed = true`, habilitando o `_input()` a processar a próxima
#     tecla/botão pressionado como novo atalho.
# -----------------------------------------------------------------------------
func _enable_remap_capture() -> void:
	remap_armed = true


# -----------------------------------------------------------------------------
# Gera uma “assinatura” estável para um InputEvent, usada na detecção de conflitos.
# Parâmetros:
#   - event (InputEvent): evento capturado pelo Godot.
# Retorno:
#   - String: assinatura normalizada (ex.: "key:87:0:0:0:0" ou "mouse:1:0").
# Observações:
#   - Posição/velocidade de mouse NÃO entram no cálculo (evita falsos positivos).
# -----------------------------------------------------------------------------
func _event_signature(event: InputEvent) -> String:
	if event is InputEventKey:
		return "key:%d:%d:%d:%d:%d" % [
			int(event.physical_keycode),
			int(event.alt_pressed),
			int(event.shift_pressed),
			int(event.ctrl_pressed),
			int(event.meta_pressed),
		]
	elif event is InputEventMouseButton:
		return "mouse:%d:%d" % [
			int(event.button_index),
			int(event.double_click)
		]
	return "unknown"


# -----------------------------------------------------------------------------
# Verifica se um determinado evento já está em uso por alguma ação (conflito).
#   - Calcula a assinatura do `new_event`.
#   - Percorre todas as ações em `input_actions` (exceto `except_action`) e
#     compara com as assinaturas dos eventos registrados no InputMap.
# Parâmetros:
#   - new_event (InputEvent): evento que se deseja atribuir.
#   - except_action (String): nome da ação atualmente sendo remapeada (ignorada).
# Retorno:
#   - String: nome da ação em conflito (se houver), ou "" se não houver conflito.
# -----------------------------------------------------------------------------
func _is_event_in_use(new_event: InputEvent, except_action: String) -> String:
	var target_signature := _event_signature(new_event)
	for action_name in input_actions.keys():
		if action_name == except_action:
			continue
		for event in InputMap.action_get_events(action_name):
			if _event_signature(event) == target_signature:
				return action_name
	return ""


# -----------------------------------------------------------------------------
# Liga/Desliga o estado visual de erro na linha (botão/row) do remapeamento.
# Parâmetros:
#   - line_button (Node): nó raiz da linha/botão que contém "LabelInput" e "LeftColumn".
#   - is_error (bool): true para aplicar estilo de erro; false para restaurar.
#   - A expansão usa `custom_minimum_size.x` e dispara novo layout automaticamente.
# -----------------------------------------------------------------------------
func _set_error_ui(line_button: Node, is_error: bool) -> void:
	var label: Label = line_button.find_child("LabelInput")
	var left_column: Control = line_button.find_child("LeftColumn")

	if is_error:
		if label:
			label.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
		if left_column:
			# guarda o tamanho original uma única vez
			if not left_column.has_meta("orig_min_x"):
				left_column.set_meta("orig_min_x", left_column.custom_minimum_size.x)
			# garante espaço pro texto de erro
			var padding := 16.0
			var needed = (label if label else line_button).get_minimum_size().x + padding
			left_column.custom_minimum_size.x = max(left_column.custom_minimum_size.x, needed)
	else:
		if label:
			# volta à cor padrão do tema
			label.remove_theme_color_override("font_color") 
		if left_column and left_column.has_meta("orig_min_x"):
			left_column.custom_minimum_size.x = float(left_column.get_meta("orig_min_x"))
			left_column.remove_meta("orig_min_x")
