extends Node2D

## Milkshake projectile. Flies from origin to target, then signals hit.

signal hit


func fire(from: Vector2, to: Vector2) -> void:
	global_position = from
	var tween = create_tween()
	tween.tween_property(self, "global_position", to, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_arrived)


func _on_arrived() -> void:
	hit.emit()
	# Splash: expand and fade
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
