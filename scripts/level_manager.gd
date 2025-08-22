class_name LevelManager extends Node2D


# Responsável apenas por servir como container dos levels.
# O Singleton irá adicionar os levels como filhos desse nó.

func _ready():
	Singleton.level_manager = self
