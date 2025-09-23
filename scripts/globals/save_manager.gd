class_name GlobalSaveManager extends Node

const SAVE_PATH := "user://savegame.json"
const SCHEMA_VERSION := 1

# Participantes que querem salvar estado adicionam-se a este grupo e expõem uma mini-interface:
#   func _get_save_id() -> String
#   func _save_state() -> Dictionary
#   func _load_state(data: Dictionary) -> void
const PARTICIPANT_GROUP := "save_participant"
const AUTOSAVE_INTERVAL_SEC := 10.0

var autosave_timer : Timer
var dirty_data : bool = false

# Snapshot atual mantido em memória
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
		},
		"session": {
			"score": 0,
			"play_time_seconds": 0.0,
			"enemies_killed": 0,
			"stage_started": false,
			"black_holes_opened": 0,
		},
	},
	# Estados arbitrários dos "participantes de save"
	"participants": {
		# "some_id": { ...state... }
	},
}

# Controle interno: acumular tempo mesmo com jogo pausado/menus
var _track_time: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_from_disk()
	
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL_SEC
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	# ALWAYS garante que o timer continua rodando mesmo com pause,
	# mas a gente filtra no callback pra só salvar se o jogo estiver “rolando”.
	autosave_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timeout)


func _on_autosave_timeout() -> void:
	# Só autosave durante gameplay
	if not profile.user.session.stage_started:
		return
	if get_tree().paused:
		return
	if not (is_instance_valid(Singleton) and is_instance_valid(Singleton.level)):
		return
	if not dirty_data:
		return
	
	save_to_disk()
	dirty_data = false
	print("[SaveManager] Autosave @ ", Time.get_datetime_string_from_system(true))



func _process(delta: float) -> void:
	# Conta tempo de jogo apenas quando há Level válido e o jogo não está pausado
	if _track_time and not get_tree().paused and is_instance_valid(Singleton) and is_instance_valid(Singleton.level):
		profile.user.session.play_time_seconds += delta
		dirty_data = true


# ---------------------------
# API de contadores da sessão
# ---------------------------
func add_score(value : int) -> void:
	profile.user.session.score += max(0, value)
	dirty_data = true


func on_enemy_killed(amount: int = 1) -> void:
	profile.user.session.enemies_killed += max(0, amount)
	dirty_data = true


func on_stage_started() -> void:
	if not profile.user.session.stage_started:
		profile.user.session.stage_started = true
		profile.user.session.play_time_seconds = 0.0
		profile.user.session.score = 0
		profile.user.session.enemies_killed = 0
		profile.user.session.black_holes_opened = 0
		profile.user.totals.stages_played += 1
		dirty_data = true


func on_stage_ended(won : bool) -> void:
	if not profile.user.session.stage_started:
		return
	
	profile.user.session.stage_started = false
	profile.user.totals.score += profile.user.session.score
	profile.user.totals.play_time_seconds += profile.user.session.play_time_seconds
	profile.user.totals.enemies_killed += profile.user.session.enemies_killed
	profile.user.totals.black_holes_opened += profile.user.session.black_holes_opened
	
	if won:
		profile.user.totals.stages_won += 1
	else:
		profile.user.totals.stages_lost += 1
	
	dirty_data = false
	save_to_disk() 


func on_black_hole_opened(amount: int = 1) -> void:
	var opened_times = max(0, amount)
	profile.user.session.black_holes_opened += opened_times 
	dirty_data = true


# ---------------------------
# Persistência
# ---------------------------
func save_to_disk() -> void:
	# Antes de salvar, coleta estados dos participantes
	var participants_state := {}
	for node in get_tree().get_nodes_in_group(PARTICIPANT_GROUP):
		if node and node.has_method("_get_save_id") and node.has_method("_save_state"):
			var pid := String(node._get_save_id())
			if pid != "":
				participants_state[pid] = node._save_state()
	
	profile.participants = participants_state
	if profile.created_at == "":
		profile.created_at = Time.get_datetime_string_from_system(true)
	
	profile.updated_at = Time.get_datetime_string_from_system(true)
	
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
		# migração simples por versão (se precisar no futuro)
		profile = parse
		# aplica estados aos participantes já presentes na árvore
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


# Debug opcional (exibir no console)
func debug_print_profile() -> void:
	print(JSON.stringify(profile, "\t"))
