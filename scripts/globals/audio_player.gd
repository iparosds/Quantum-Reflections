class_name GlobalAudioPlayer extends AudioStreamPlayer

const MENU_MUSIC = preload("res://assets/sounds/menus/MENU MUSIC.wav")
const LEVEL_MUSIC = preload("res://assets/sounds/in_game/GAMEPLAY SONG MASTER.mp3")

const BUS_MASTER := "Master"
const BUS_MUSIC  := "Music"
const BUS_SFX    := "SFX"

# -----------------------------------------------------------------------------
# Configurações do agregador de SFX (tiros)
# -----------------------------------------------------------------------------
const SFX_POOL_SIZE: int = 4
const SHOT_GROUPING_WINDOW_SECONDS: float = 0.04  # Janela para agrupar "mesmo disparo"
const SHOT_START_JITTER_SECONDS: float = 0.0      # 0–0.02 para desincronizar início
const BASE_SHOT_VOLUME_DB: float = 8.0           # Volume base de cada tiro
const DEFAULT_SHOT_EXTRA_GAIN_DB: float = 6.0  # ajuste fino só do tiro


# Pool de players SFX (não-posicionais) e histórico de disparos
var _sfx_players_pool: Array[AudioStreamPlayer] = []
var _recent_shot_timestamps_seconds: Array[float] = []

# -----------------------------------------------------------------------------
# Estado de música
# -----------------------------------------------------------------------------
var _last_level_music_position_seconds: float = 0.0
var _current_music_track_label: String = ""  # "menu" | "level"
var _music_fadeout_tween: Tween = null



func _ready() -> void:
	# Este AudioStreamPlayer toca música (bus Music).
	bus = BUS_MUSIC
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_enable_music_looping_on_known_tracks()
	_load_persisted_bus_volumes()
	
	# Reconexão segura do callback de término de música
	if not is_connected("finished", Callable(self, "_on_music_playback_finished")):
		connect("finished", Callable(self, "_on_music_playback_finished"))
	
	_initialize_sfx_players_pool()


# =============================================================================
# Música: preparação e loop
# =============================================================================
func _enable_music_looping_on_known_tracks() -> void:
	_force_stream_loop_on_resource(MENU_MUSIC)
	_force_stream_loop_on_resource(LEVEL_MUSIC)


func _force_stream_loop_on_resource(audio_stream: AudioStream) -> void:
	if audio_stream is AudioStreamMP3:
		(audio_stream as AudioStreamMP3).loop = true
	elif audio_stream is AudioStreamOggVorbis:
		(audio_stream as AudioStreamOggVorbis).loop = true
	elif audio_stream is AudioStreamWAV:
		(audio_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _on_music_playback_finished() -> void:
	# Fallback: se, por qualquer motivo, a faixa não estiver em loop, reinicia.
	if stream == MENU_MUSIC or stream == LEVEL_MUSIC:
		play(0.0)


# =============================================================================
# Música: controle de reprodução
# =============================================================================
func _play_music_stream(music_stream: AudioStream, start_volume_db: float = 0.0, start_position_seconds: float = 0.0) -> void:
	if stream == music_stream and playing:
		return
	
	_cancel_music_fade_out_if_running()
	
	stream = music_stream
	volume_db = start_volume_db
	play(start_position_seconds)


func _play_menu_music() -> void:
	if _current_music_track_label == "level" and playing:
		_last_level_music_position_seconds = get_playback_position()
	
	_current_music_track_label = "menu"
	_play_music_stream(MENU_MUSIC)


func _play_level_music(resume_from_last_position: bool = true) -> void:
	_current_music_track_label = "level"
	var start_pos := _last_level_music_position_seconds if resume_from_last_position else 0.0
	_play_music_stream(LEVEL_MUSIC, 0.0, start_pos)


func stop_music() -> void:
	stop()


func remember_level_position_and_stop() -> void:
	if _current_music_track_label == "level" and playing:
		_last_level_music_position_seconds = get_playback_position()
	stop()


func on_pause_entered() -> void:
	remember_level_position_and_stop()
	_play_menu_music()


func on_pause_exited() -> void:
	_play_level_music(true)


func on_level_restart() -> void:
	_last_level_music_position_seconds = 0.0
	_cancel_music_fade_out_if_running()
	stop()
	_play_level_music(false)


# =============================================================================
# Música: fade-out
# =============================================================================
func fade_out_and_stop(duration_seconds: float = 0.8) -> void:
	if not playing:
		return
	
	_cancel_music_fade_out_if_running()
	var stream_at_start: AudioStream = stream
	
	_music_fadeout_tween = get_tree().create_tween()
	_music_fadeout_tween.tween_property(self, "volume_db", -80.0, duration_seconds)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	_music_fadeout_tween.finished.connect(func ():
		_music_fadeout_tween = null
		if stream == stream_at_start:
			stop()
		volume_db = 0.0
	)


func _cancel_music_fade_out_if_running() -> void:
	if is_instance_valid(_music_fadeout_tween):
		_music_fadeout_tween.kill()
	_music_fadeout_tween = null
	volume_db = 0.0


# =============================================================================
# Volumes persistidos (buses)
# =============================================================================
func set_master_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), db)

func set_music_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), db)

func set_sfx_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), db)

func get_master_volume_db() -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER))

func get_music_volume_db() -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC))

func get_sfx_volume_db() -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(BUS_SFX))


func save_volumes() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_db", get_master_volume_db())
	config.set_value("audio", "music_db",  get_music_volume_db())
	config.set_value("audio", "sfx_db",    get_sfx_volume_db())
	config.save("user://audio.cfg")


func _load_persisted_bus_volumes() -> void:
	var config := ConfigFile.new()
	if config.load("user://audio.cfg") == OK:
		set_master_volume_db(float(config.get_value("audio", "master_db", 0.0)))
		set_music_volume_db(float(config.get_value("audio", "music_db", 0.0)))
		set_sfx_volume_db(float(config.get_value("audio", "sfx_db", 0.0)))


# =============================================================================
# Agregador de SFX (tiros)
# =============================================================================
func _initialize_sfx_players_pool() -> void:
	for pool_index in range(SFX_POOL_SIZE):
		var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
		sfx_player.bus = BUS_SFX
		sfx_player.volume_db = BASE_SHOT_VOLUME_DB
		add_child(sfx_player)
		_sfx_players_pool.append(sfx_player)


func _acquire_available_sfx_player() -> AudioStreamPlayer:
	for sfx_player in _sfx_players_pool:
		if not sfx_player.playing:
			return sfx_player
	# Se todos ocupados, reutiliza o primeiro (polifonia limitada)
	return _sfx_players_pool[0]


func _count_and_prune_recent_shots_in_window() -> int:
	var now_seconds := _get_now_seconds()
	_recent_shot_timestamps_seconds = _recent_shot_timestamps_seconds.filter(
		func(timestamp_seconds): return now_seconds - timestamp_seconds <= SHOT_GROUPING_WINDOW_SECONDS
	)
	return _recent_shot_timestamps_seconds.size()


# --- API pública para tiros ---------------------------------------------------
# debounce_enabled = true  => 1 som por janela (os demais são suprimidos)
# debounce_enabled = false => permite vários, com compensação de ganho automática
# permite dizer "quanto" subir só o tiro
func play_shot_sound_with_debounce(
	shot_stream: AudioStream,
	debounce_enabled: bool = true,
	extra_gain_db: float = DEFAULT_SHOT_EXTRA_GAIN_DB
) -> void:
	if shot_stream == null:
		return
	var now_seconds := _get_now_seconds()
	var shots_already_in_window := _count_and_prune_recent_shots_in_window()
	if debounce_enabled and shots_already_in_window > 0:
		return
	var loudness_compensation_db := 0.0
	if not debounce_enabled:
		loudness_compensation_db = -20.0 * _log10(float(shots_already_in_window + 1))
		loudness_compensation_db = clamp(loudness_compensation_db, -12.0, 0.0)
	var chosen_sfx_player := _acquire_available_sfx_player()
	chosen_sfx_player.stop()
	chosen_sfx_player.stream = shot_stream
	chosen_sfx_player.pitch_scale = randf_range(0.97, 1.03)
	# >>> só o tiro fica mais alto aqui:
	chosen_sfx_player.volume_db = BASE_SHOT_VOLUME_DB + extra_gain_db + loudness_compensation_db
	if SHOT_START_JITTER_SECONDS > 0.0:
		var random_start_delay := randf_range(0.0, SHOT_START_JITTER_SECONDS)
		await get_tree().create_timer(random_start_delay).timeout
	chosen_sfx_player.play()
	_recent_shot_timestamps_seconds.append(now_seconds)


# -----------------------------------------------------------------------------
# Alias de compatibilidade (antigo nome usado nas turrets)
# -----------------------------------------------------------------------------
func play_shot(stream: AudioStream, debounce: bool = true, extra_gain_db: float = DEFAULT_SHOT_EXTRA_GAIN_DB) -> void:
	play_shot_sound_with_debounce(stream, debounce, extra_gain_db)


# =============================================================================
# Utilidades internas
# =============================================================================
static func _log10(x: float) -> float:
	# GDScript não tem log10 nativo; converte via ln(x)/ln(10)
	return log(x) / log(10.0)


static func _get_now_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0
