extends Node2D

## The core gameplay scene. Contains the street, player, camera, and event triggers.
## Designed to be reusable across different errands.

@onready var player: CharacterBody2D = $Entities/Player
@onready var camera: Camera2D = $Camera2D


func _unhandled_input(event: InputEvent) -> void:
	# Debug: K adds 10 karma for testing HUD and unlock thresholds
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			GameManager.add_karma(10)


func _physics_process(delta: float) -> void:
	# Smooth camera follow (delta-scaled so it's frame-rate independent)
	camera.position = camera.position.lerp(player.position, 1.0 - exp(-10.0 * delta))
