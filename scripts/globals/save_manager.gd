class_name GlobalSaveManager extends Node

const SAVE_PATH := "user://save_game.json"
const SCHEMA_VERSION := 1

# Participantes que querem salvar estado adicionam-se a este grupo e expõem uma mini-interface:
#   func _get_save_id() -> String
#   func _save_state() -> Dictionary
#   func _load_state(data: Dictionary) -> void
const PARTICIPANT_GROUP := "save_participant"
const AUTOSAVE_INTERVAL_SEC := 10.0
const BR_TZ_OFFSET_SEC := -3 * 3600  # Brasil (sem horário de verão)

var autosave_timer : Timer
var dirty_data : bool = false
var _track_time: bool = true
var profile : Dictionary = {
	"schema" : SCHEMA_VERSION,
	"created_at" : "",
	"updated_at" : "",
	"user" : {
		"totals" : {
			"score": 0,
			"play_time_seconds": 0.0,
			"enemies_killed": 0,
			"stages_played": 0,
			"stages_won": 0,
			"stages_lost": 0,
			"black_holes_opened": 0,
			# derivado (preenchido ao salvar):
			"play_time_hms": "00:00:00",
		},
		"session": {
			"score": 0,
			"play_time_seconds": 0.0,
			"enemies_killed": 0,
			"stage_started": false,
			"black_holes_opened": 0,
			# derivado (preenchido ao salvar):
			"play_time_hms": "00:00:00",
		},
	},
	# Estados arbitrários dos "participantes de save"
	"participants": {
		# "some_id": { ...state... }
	},
}
# Snapshot do último autosave para calcular delta de sessão -> totals
var _last_session_snapshot := {
	"score": 0,
	"play_time_seconds": 0.0,
	"enemies_killed": 0,
	"black_holes_opened": 0,
}


# ---------------------------
# Helpers (data/hora e formatos)
# ---------------------------
func _now_br_string() -> String:
	var unix := Time.get_unix_time_from_system()
	var date_time := Time.get_datetime_dict_from_unix_time(unix + BR_TZ_OFFSET_SEC)
	return "%02d-%02d-%04d %02d:%02d:%02d -03:00" % [
		date_time.day, date_time.month, date_time.year, date_time.hour, date_time.minute, date_time.second
	]


func _seconds_to_hms(seconds: float) -> String:
	var total := int(seconds)
	var hour := total / 3600
	var minute := (total % 3600) / 60
	var second := total % 60
	return "%02d:%02d:%02d" % [hour, minute, second]


# Garante inteiros nos contadores
func _normalize_counters() -> void:
	# session
	profile.user.session.score = int(profile.user.session.score)
	profile.user.session.enemies_killed = int(profile.user.session.enemies_killed)
	profile.user.session.black_holes_opened = int(profile.user.session.black_holes_opened)
	# totals
	profile.user.totals.score = int(profile.user.totals.score)
	profile.user.totals.enemies_killed = int(profile.user.totals.enemies_killed)
	profile.user.totals.stages_played = int(profile.user.totals.stages_played)
	profile.user.totals.stages_won = int(profile.user.totals.stages_won)
	profile.user.totals.stages_lost = int(profile.user.totals.stages_lost)
	profile.user.totals.black_holes_opened = int(profile.user.totals.black_holes_opened)


# ---------------------------
# Lifecycle
# ---------------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_from_disk()
	add_to_group("save_manager")
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL_SEC
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	autosave_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timeout)


func _process(delta: float) -> void:
	if _track_time and not get_tree().paused and is_instance_valid(Singleton) and is_instance_valid(Singleton.level):
		profile.user.session.play_time_seconds += delta
		dirty_data = true


func _on_autosave_timeout() -> void:
	if not profile.user.session.stage_started:
		return
	if get_tree().paused:
		return
	if not (is_instance_valid(Singleton) and is_instance_valid(Singleton.level)):
		return

	# Aplica delta da sessão aos totals
	var totals_changed := _rollup_session_into_totals()

	# Só salva se algo mudou (tempo/score/kills/black holes) ou se já estava dirty
	if not totals_changed and not dirty_data:
		return

	save_to_disk()
	dirty_data = false


# ---------------------------
# API de contadores da sessão
# ---------------------------
func add_score(value : int) -> void:
	profile.user.session.score = int(profile.user.session.score) + max(0, value)
	dirty_data = true


func on_enemy_killed(amount: int = 1) -> void:
	profile.user.session.enemies_killed = int(profile.user.session.enemies_killed) + max(0, amount)
	dirty_data = true


func on_stage_started() -> void:
	if not profile.user.session.stage_started:
		profile.user.session.stage_started = true
		profile.user.session.play_time_seconds = 0.0
		profile.user.session.score = 0
		profile.user.session.enemies_killed = 0
		profile.user.session.black_holes_opened = 0
		profile.user.totals.stages_played = int(profile.user.totals.stages_played) + 1
		dirty_data = true
		
		# zera snapshot para iniciar contagem de delta
		_last_session_snapshot = {
			"score": 0,
			"play_time_seconds": 0.0,
			"enemies_killed": 0,
			"black_holes_opened": 0,
		}


func on_stage_ended(won : bool) -> void:
	if not profile.user.session.stage_started:
		return
	
	profile.user.session.stage_started = false
	
	if won:
		profile.user.totals.stages_won  = int(profile.user.totals.stages_won) + 1
	else:
		profile.user.totals.stages_lost = int(profile.user.totals.stages_lost) + 1
	
	# **sempre** zera a sessão ao terminar/fechar
	profile.user.session.score = 0
	profile.user.session.play_time_seconds = 0.0
	profile.user.session.enemies_killed = 0
	profile.user.session.black_holes_opened = 0
	profile.user.session.stage_started = false
	_last_session_snapshot = {
		"score": 0,
		"play_time_seconds": 0.0,
		"enemies_killed": 0,
		"black_holes_opened": 0,
	}
	
	dirty_data = false
	_normalize_counters()
	save_to_disk()
	_rollup_session_into_totals()


func on_black_hole_opened(amount: int = 1) -> void:
	var opened_times = max(0, amount)
	profile.user.session.black_holes_opened = int(profile.user.session.black_holes_opened) + opened_times
	dirty_data = true


# ---------------------------
# Persistência
# ---------------------------
func save_to_disk() -> void:
	var participants_state := {}
	for node in get_tree().get_nodes_in_group(PARTICIPANT_GROUP):
		if node and node.has_method("_get_save_id") and node.has_method("_save_state"):
			var pid := String(node._get_save_id())
			if pid != "":
				participants_state[pid] = node._save_state()
		elif node and node is InputSettings:
			var key := "input_settings"
			var bindings := {}
			for action_name in node.input_actions.keys():
				var array := []
				for input_event in InputMap.action_get_events(action_name):
					var data = node._serialize_event(input_event)
					if data.size() > 0:
						array.append(data)
				bindings[action_name] = array
			participants_state[key] = {
				"bindings": bindings,
			}
	
	profile.participants = participants_state
	_rollup_session_into_totals()
	_normalize_counters()
	if profile.created_at == "":
		profile.created_at = _now_br_string()
	profile.updated_at = _now_br_string()
	profile.user.session.play_time_hms = _seconds_to_hms(profile.user.session.play_time_seconds)
	profile.user.totals.play_time_hms  = _seconds_to_hms(profile.user.totals.play_time_seconds)
	profile.user.session.play_time_seconds = snappedf(profile.user.session.play_time_seconds, 0.01)
	profile.user.totals.play_time_seconds  = snappedf(profile.user.totals.play_time_seconds, 0.01)
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(profile, "\t"))
		file.close()
	else:
		push_warning("SaveManager: não foi possível abrir arquivo para escrita: " + SAVE_PATH)


func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	
	var parse = JSON.parse_string(text)
	if typeof(parse) == TYPE_DICTIONARY:
		profile = parse
	
		if profile.user.has("participants") and typeof(profile.user.participants) == TYPE_DICTIONARY:
			profile.participants = profile.user.participants
			profile.user.erase("participants")
		
		_normalize_counters()
		_apply_participants_state()


func _apply_participants_state() -> void:
	if not profile.has("participants"):
		return

	var participants_state: Dictionary = profile.participants
	for node in get_tree().get_nodes_in_group(PARTICIPANT_GROUP):
		if node and node.has_method("_get_save_id") and node.has_method("_load_state"):
			var pid := String(node._get_save_id())
			if participants_state.has(pid):
				node._load_state(participants_state[pid])
		elif node and node is InputSettings:
			var key := "input_settings"
			if not participants_state.has(key):
				continue
			var bindings: Dictionary = participants_state[key].get("bindings", {})
			for action_name in node.input_actions.keys():
				InputMap.action_erase_events(action_name)
				if bindings.has(action_name):
					for event_data in bindings[action_name]:
						var event = node._deserialize_event(event_data)
						if event != null:
							InputMap.action_add_event(action_name, event)


# Debug
func debug_print_profile() -> void:
	print(JSON.stringify(profile, "\t"))


# Soma nos totals apenas o que mudou na sessão desde o último snapshot.
# Retorna true se houve algum delta aplicado.
func _rollup_session_into_totals() -> bool:
	var current_session = profile.user.session
	var snap := _last_session_snapshot
	
	var date_score := int(current_session.score) - int(snap.score)
	var date_time := float(current_session.play_time_seconds) - float(snap.play_time_seconds)
	var date_kills := int(current_session.enemies_killed) - int(snap.enemies_killed)
	var date_black_holes := int(current_session.black_holes_opened) - int(snap.black_holes_opened)
	
	var changed = (date_score != 0) or (abs(date_time) > 0.0001) or (date_kills != 0) or (date_black_holes != 0)
	if changed:
		profile.user.totals.score = int(profile.user.totals.score) + max(0, date_score)
		profile.user.totals.play_time_seconds += max(0.0, date_time)
		profile.user.totals.enemies_killed = int(profile.user.totals.enemies_killed) + max(0, date_kills)
		profile.user.totals.black_holes_opened = int(profile.user.totals.black_holes_opened) + max(0, date_black_holes)
		
		# Atualiza snapshot para o estado atual da sessão
		_last_session_snapshot.score = int(current_session.score)
		_last_session_snapshot.play_time_seconds = float(current_session.play_time_seconds)
		_last_session_snapshot.enemies_killed = int(current_session.enemies_killed)
		_last_session_snapshot.black_holes_opened = int(current_session.black_holes_opened)
	
	return changed
