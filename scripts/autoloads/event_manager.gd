extends Node

## Manages event pools, rolls random events, and spawns prompts / bad actors.
## EventTrigger zones in the level call try_spawn_event().
## Player calls handle_interact() when E is pressed.

signal event_spawned(event_data: Resource, event_node: Node)
signal event_resolved(event_data: Resource, was_acted_on: bool)
signal good_deed_prompt_shown(event_data: Resource)
signal good_deed_completed(event_data: Resource)
signal good_deed_expired(event_data: Resource)
signal bad_actor_spawned(event_data: Resource, actor_node: Node)
signal bad_actor_punished(event_data: Resource)

var good_event_pool: Array[Resource] = []
var bad_event_pool: Array[Resource] = []
var recent_events: Array[StringName] = []

var _active_event: EventData = null
var _prompt_instance: Node = null
var _bad_actor_instance: Node = null

## Set by errand_level.gd — parent node for spawning bad actor NPCs (Y-sorted).
var spawn_parent: Node2D = null

var _all_good_events: Array[Resource] = []
var _all_bad_events: Array[Resource] = []

const RECENT_EVENTS_MAX = 3
const GOOD_DEED_PROMPT_SCENE = preload("res://scenes/events/good_deed_prompt.tscn")


func _ready() -> void:
	_load_events()


func _load_events() -> void:
	_all_good_events = _load_events_from_dir("res://data/events/good/")
	_all_bad_events = _load_events_from_dir("res://data/events/bad/")
	good_event_pool = _all_good_events.duplicate()
	bad_event_pool = _all_bad_events.duplicate()


func _load_events_from_dir(path: String) -> Array[Resource]:
	var events: Array[Resource] = []
	var dir = DirAccess.open(path)
	if dir == null:
		return events
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".tres"):
			var resource = load(path.path_join(filename))
			if resource != null:
				events.append(resource)
		filename = dir.get_next()
	dir.list_dir_end()
	return events


func load_for_errand(errand: ErrandData) -> void:
	good_event_pool = _all_good_events.filter(func(e: Resource) -> bool:
		return e.id in errand.good_event_ids
	)
	bad_event_pool = _all_bad_events.filter(func(e: Resource) -> bool:
		return e.id in errand.bad_event_ids
	)
	recent_events.clear()


func try_spawn_event(trigger_position: Vector2 = Vector2.ZERO) -> bool:
	## Returns true if an event was spawned, false if skipped.
	if _active_event != null:
		return false
	var event = _roll_event()
	if event == null:
		return false
	_active_event = event
	_track_recent(event.id)

	if event.event_type == &"good_deed":
		_spawn_prompt(event)
		good_deed_prompt_shown.emit(event)
	elif event.event_type == &"bad_actor":
		_spawn_bad_actor(event, trigger_position)
		bad_actor_spawned.emit(event, _bad_actor_instance)

	var active_node = _prompt_instance if _prompt_instance else _bad_actor_instance
	event_spawned.emit(event, active_node)
	return true


func handle_interact() -> void:
	if _active_event == null or _active_event.event_type != &"good_deed":
		return
	var event = _active_event
	_dismiss_prompt()
	GameManager.add_karma(event.karma_reward)
	good_deed_completed.emit(event)
	event_resolved.emit(event, true)


func _roll_event() -> EventData:
	var combined: Array[Resource] = []
	combined.append_array(good_event_pool)
	combined.append_array(bad_event_pool)
	if combined.is_empty():
		return null
	var available = combined.filter(func(e: Resource) -> bool:
		return not (e.id in recent_events)
	)
	if available.is_empty():
		available = combined
	return _weighted_pick(available)


func _weighted_pick(pool: Array) -> EventData:
	var total_weight: float = 0.0
	for e in pool:
		total_weight += e.weight
	var roll := randf() * total_weight
	for e in pool:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return pool[-1]


func _track_recent(event_id: StringName) -> void:
	recent_events.append(event_id)
	if recent_events.size() > RECENT_EVENTS_MAX:
		recent_events.pop_front()


func _spawn_prompt(event: EventData) -> void:
	_prompt_instance = GOOD_DEED_PROMPT_SCENE.instantiate()
	_prompt_instance.expired.connect(_on_prompt_expired)
	add_child(_prompt_instance)
	_prompt_instance.setup(event)


func _spawn_bad_actor(event: EventData, spawn_pos: Vector2) -> void:
	if not is_instance_valid(spawn_parent):
		return
	var scene = load(event.npc_scene_path)
	if scene == null:
		return
	_bad_actor_instance = scene.instantiate()
	_bad_actor_instance.global_position = spawn_pos
	_bad_actor_instance.resolved.connect(_on_bad_actor_resolved)
	spawn_parent.add_child(_bad_actor_instance)
	_bad_actor_instance.setup(event)


func _dismiss_prompt() -> void:
	_active_event = null
	if is_instance_valid(_prompt_instance):
		_prompt_instance.queue_free()
	_prompt_instance = null


func _on_prompt_expired() -> void:
	var event = _active_event
	_active_event = null
	_prompt_instance = null
	good_deed_expired.emit(event)
	event_resolved.emit(event, false)


func _on_bad_actor_resolved(was_punished: bool) -> void:
	var event = _active_event
	_active_event = null
	_bad_actor_instance = null
	if was_punished:
		bad_actor_punished.emit(event)
	event_resolved.emit(event, was_punished)
