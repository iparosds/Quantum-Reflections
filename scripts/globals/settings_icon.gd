class_name SettingsIcon extends CanvasLayer

@onready var toggle_settings_button: TextureButton = $VBoxContainer/ToggleSettingsButton


# ------------------------------------------------------------
# Handler do clique no ícone de Settings.
# - Registra este ícone no Singleton (para controle global de visibilidade/estado).
# - Define process_mode como ALWAYS para que o ícone responda mesmo com o jogo pausado.
# - Abre diretamente a tela de Settings
# ------------------------------------------------------------
func _on_toggle_settings_button_pressed() -> void:
	Singleton.settings_icon = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	Singleton.open_settings_from_icon()
