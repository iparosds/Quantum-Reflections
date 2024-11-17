extends AudioStreamPlayer

const menu_music = preload("res://assets/sounds/MENU MUSIC.wav")

func _play_music (music: AudioStream, volume = 0.0):
	if stream == music:
		return
	
	stream = music
	volume_db = volume
	play()
	
func _play_level_music():
	_play_music(menu_music) 
