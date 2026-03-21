extends Node


func _ready() -> void:
	# Phase 1: Jump straight to errand level
	# Phase 5 will change this to load title screen instead
	SceneManager.change_scene("res://scenes/errand/errand_level.tscn")
