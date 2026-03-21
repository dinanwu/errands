extends Node

## Manages transitions between major scenes (title, level, complete, shop).
## Swaps child nodes under Main/CurrentScene.

var _current_scene: Node = null


func change_scene(scene_path: String, data: Dictionary = {}) -> void:
	# Defer so we don't disrupt the current frame
	call_deferred("_deferred_change", scene_path, data)


func _deferred_change(scene_path: String, data: Dictionary) -> void:
	var main = get_tree().root.get_node("Main")
	var container = main.get_node("CurrentScene")

	# Remove old scene
	if _current_scene:
		_current_scene.queue_free()
		_current_scene = null

	# Load and instance new scene
	var new_scene_resource = load(scene_path)
	if not new_scene_resource:
		push_error("SceneManager: Failed to load scene: " + scene_path)
		return

	_current_scene = new_scene_resource.instantiate()
	container.add_child(_current_scene)

	# Pass data if the scene has a setup method
	if _current_scene.has_method("setup"):
		_current_scene.setup(data)
