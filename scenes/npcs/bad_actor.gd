extends CharacterBody2D

## A bad actor NPC performing a negative behavior on the street.
## Spawned by EventManager when a bad_actor event triggers.
## Player clicks to punish with their selected weapon.

signal resolved(was_punished: bool)

@onready var body: Polygon2D = $Body
@onready var behavior_label: Label = $BehaviorLabel
@onready var punishable_area: Area2D = $PunishableArea

var event_data: EventData = null
var _is_resolved: bool = false

const LINGER_DURATION: float = 15.0
var _linger_timer: float = 0.0


func setup(data: EventData) -> void:
	event_data = data
	behavior_label.text = data.display_name.to_upper()


func _ready() -> void:
	punishable_area.input_event.connect(_on_punishable_input)
	punishable_area.mouse_entered.connect(_on_mouse_entered)
	punishable_area.mouse_exited.connect(_on_mouse_exited)


func _process(delta: float) -> void:
	if _is_resolved:
		return
	_linger_timer += delta
	if _linger_timer >= LINGER_DURATION:
		_wander_off()


func _on_punishable_input(viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_resolved:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	# Always consume clicks on bad actors so player doesn't walk toward them
	viewport.set_input_as_handled()
	var weapon_id = GameManager.selected_weapon
	if weapon_id == &"" or not GameManager.can_use_weapon(weapon_id):
		return
	_punish(weapon_id)


func _punish(weapon_id: StringName) -> void:
	_is_resolved = true
	var weapon_data = GameManager.use_weapon(weapon_id)
	resolved.emit(true)

	# Spawn weapon projectile from player to this bad actor
	var player = get_tree().get_first_node_in_group("player")
	if weapon_data and weapon_data.effect_scene_path != "":
		var effect_scene = load(weapon_data.effect_scene_path)
		if effect_scene:
			var effect = effect_scene.instantiate()
			get_parent().add_child(effect)
			effect.hit.connect(_play_hit_reaction)
			effect.fire(player.global_position, global_position)
			return
	# No effect scene — play reaction immediately
	_play_hit_reaction()


func _play_hit_reaction() -> void:
	if not is_inside_tree():
		return
	behavior_label.visible = false
	var tween = create_tween()
	tween.tween_property(body, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(self, "position", position + Vector2(randf_range(-30, 30), -50), 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _wander_off() -> void:
	_is_resolved = true
	resolved.emit(false)
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(150, -75), 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)


func _on_mouse_entered() -> void:
	if not _is_resolved and GameManager.selected_weapon != &"":
		modulate = Color(1.3, 1.3, 1.3)


func _on_mouse_exited() -> void:
	if not _is_resolved:
		modulate = Color.WHITE
