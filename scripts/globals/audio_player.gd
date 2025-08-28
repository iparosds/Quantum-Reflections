extends AudioStreamPlayer

const MENU_MUSIC = preload("res://assets/sounds/menus/MENU MUSIC.wav")
const LEVEL_MUSIC = preload("res://assets/sounds/in_game/GAMEPLAY SONG MASTER.mp3")

const BUS_MASTER := "Master"
const BUS_MUSIC  := "Music"
const BUS_SFX    := "SFX"

# Posição onde a música do level foi pausada
var _last_level_pos: float = 0.0
var _current_track: String = ""


# -----------------------------------------------------------------------------
# Inicializa o player de música:
# - Envia este AudioStreamPlayer para o bus "Music"
# - Mantém o processamento mesmo com o jogo pausado
# - Garante que as trilhas (menu/level) estejam com loop habilitado
# - Carrega e aplica volumes salvos (Master/Music/SFX)
# - Conecta um fallback para reiniciar a faixa quando terminar (se o recurso não estiver em loop)
# -----------------------------------------------------------------------------
func _ready() -> void:
	bus = BUS_MUSIC
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_enable_looping() 
	load_volumes()
	
	# fallback: se por algum motivo o loop do stream não estiver ativo, reinicia ao terminar
	if not is_connected("finished", Callable(self, "_on_finished")):
		connect("finished", Callable(self, "_on_finished"))


# -----------------------------------------------------------------------------
# Habilita loop nas duas trilhas conhecidas deste player (menu e level).
# Obs: isso altera as propriedades do recurso em runtime (não persiste no arquivo).
# -----------------------------------------------------------------------------
func _enable_looping() -> void:
	_force_stream_loop(MENU_MUSIC)
	_force_stream_loop(LEVEL_MUSIC)


# -----------------------------------------------------------------------------
# Força um AudioStream específico a tocar em loop, respeitando o tipo do recurso.
# - WAV: define loop_mode = LOOP_FORWARD
# - OGG/MP3: define loop = true
# Parâmetros:
#   stream (AudioStream): recurso de áudio a ajustar
# -----------------------------------------------------------------------------
func _force_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD


# -----------------------------------------------------------------------------
# Fallback chamado quando a reprodução termina.
# Se a trilha atual for a de menu/level e não estiver em loop, reinicia do 0.
# -----------------------------------------------------------------------------
func _on_finished() -> void:
	if stream == MENU_MUSIC or stream == LEVEL_MUSIC:
		play(0.0)


# -----------------------------------------------------------------------------
# Toca um AudioStream com volume e posição inicial opcionais.
# Evita reiniciar se o mesmo stream já estiver tocando.
# Parâmetros:
#   music (AudioStream): faixa a tocar
#   volume (float): volume em dB (0.0 = unidade)
#   from_pos (float): posição inicial em segundos
# -----------------------------------------------------------------------------
func _play_music(music: AudioStream, volume: float = 0.0, from_pos: float = 0.0) -> void:
	if stream == music and playing:
		return
	
	stream = music
	volume_db = volume
	play(from_pos)


# -----------------------------------------------------------------------------
# Inicia a música do menu.
# Se estava tocando a música do level, salva a posição para retomar depois.
# -----------------------------------------------------------------------------
func _play_menu_music() -> void:
	if _current_track == "level" and playing:
		_last_level_pos = get_playback_position()
	
	_current_track = "menu"
	_play_music(MENU_MUSIC)


# -----------------------------------------------------------------------------
# Inicia a música do level.
# Se resume=true, começa da última posição salva; caso contrário, do início.
# Parâmetros:
#   resume (bool): retomar de onde parou (padrão: true)
# -----------------------------------------------------------------------------
func _play_level_music(resume: bool = true) -> void:
	_current_track = "level"
	var start_pos := _last_level_pos if resume else 0.0
	_play_music(LEVEL_MUSIC, 0.0, start_pos)


func stop_music() -> void:
	stop()


# -----------------------------------------------------------------------------
# Se a trilha atual for a do level, salva a posição de reprodução e para.
# -----------------------------------------------------------------------------
func remember_level_position_and_stop() -> void:
	if _current_track == "level" and playing:
		_last_level_pos = get_playback_position()
	
	stop()


# -----------------------------------------------------------------------------
# Handler para quando o jogo entra no pause:
# - Salva a posição do level (se aplicável) e para
# - Troca para a música de menu
# -----------------------------------------------------------------------------
func on_pause_entered() -> void:
	remember_level_position_and_stop()
	_play_menu_music()



func on_pause_exited() -> void:
	_play_level_music(true)


# -----------------------------------------------------------------------------
# Handler para restart do level:
# - Zera a posição salva e reinicia a música do level do começo
# -----------------------------------------------------------------------------
func on_level_restart() -> void:
	_last_level_pos = 0.0
	stop()
	_play_level_music(false)


# ---------- Volumes (Master / Music / SFX) ----------
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


# -----------------------------------------------------------------------------
# Salva os volumes atuais (Master/Music/SFX) em user://audio.cfg.
# -----------------------------------------------------------------------------
func save_volumes():
	var config := ConfigFile.new()
	config.set_value("audio", "master_db", get_master_volume_db())
	config.set_value("audio", "music_db",  get_music_volume_db())
	config.set_value("audio", "sfx_db",    get_sfx_volume_db())
	config.save("user://audio.cfg")


# -----------------------------------------------------------------------------
# Carrega e aplica volumes de user://audio.cfg (se existir).
# Usa 0.0 dB como padrão quando não houver valor salvo.
# -----------------------------------------------------------------------------
func load_volumes():
	var config := ConfigFile.new()
	if config.load("user://audio.cfg") == OK:
		set_master_volume_db(float(config.get_value("audio", "master_db", 0.0)))
		set_music_volume_db(float(config.get_value("audio", "music_db", 0.0)))
		set_sfx_volume_db(float(config.get_value("audio", "sfx_db", 0.0)))


# -----------------------------------------------------------------------------
# Faz um fade-out da trilha atual e para a reprodução ao final.
# Comportamento:
#   - Se nada estiver tocando (`playing == false`), sai imediatamente.
#   - Cria um Tween que reduz `volume_db` gradualmente até −80 dB no tempo dado.
#   - Aguarda o término do Tween, chama `stop()` e, por fim, restaura `volume_db`
#     para 0 dB (para que a próxima faixa comece em volume normal).
# Parâmetros:
#   duration (float) ... Duração do fade-out em segundos (padrão: 0.8).
# -----------------------------------------------------------------------------
func fade_out_and_stop(duration: float = 0.8) -> void:
	if not playing:
		return
	
	var audio_tween := get_tree().create_tween()
	audio_tween.tween_property(self, "volume_db", -80.0, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await audio_tween.finished
	stop()
	
	volume_db = 0.0
