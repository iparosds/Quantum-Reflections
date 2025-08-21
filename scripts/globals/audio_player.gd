extends AudioStreamPlayer

const MENU_MUSIC = preload("res://assets/sounds/menus/MENU MUSIC.wav")
const LEVEL_MUSIC = preload("res://assets/sounds/in_game/GAMEPLAY SONG MASTER.mp3")


func _play_music (music: AudioStream, volume = 0.0):
	if stream == music:
		return
	
	stream = music
	volume_db = volume
	play()
	
func _play_menu_music():
	_play_music(MENU_MUSIC) 


func _play_level_music():
	_play_music(LEVEL_MUSIC) 
