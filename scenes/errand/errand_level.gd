extends Node2D

## The core gameplay scene. Contains the street, player, camera, and event triggers.
## Designed to be reusable across different errands.

@onready var player: CharacterBody2D = $Entities/Player
@onready var camera: Camera2D = $Camera2D


func _physics_process(delta: float) -> void:
	# Smooth camera follow (delta-scaled so it's frame-rate independent)
	camera.position = camera.position.lerp(player.position, 1.0 - exp(-10.0 * delta))
