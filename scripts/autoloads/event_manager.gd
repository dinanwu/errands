extends Node

## Manages event pools, rolls random events, and spawns prompts.
## EventTrigger zones in the level call try_spawn_event().
## Player calls handle_interact() when E is pressed.
##
## event_spawned / event_resolved are reserved for future systems (HUD juice, scoring).

signal event_spawned(event_data: Resource, event_node: Node)
signal event_resolved(event_data: Resource, was_acted_on: bool)
signal good_deed_prompt_shown(event_data: Resource)
signal good_deed_completed(event_data: Resource)
signal good_deed_expired(event_data: Resource)

## Filtered pool for the current errand. Roll events from here.
var good_event_pool: Array[Resource] = []
var recent_events: Array[StringName] = []

var _active_event: EventData = null
var _prompt_instance: Node = null

## Full pool loaded from disk — source of truth for load_for_errand().
var _all_good_events: Array[Resource] = []

const RECENT_EVENTS_MAX = 3
const GOOD_DEED_PROMPT_SCENE = preload("res://scenes/events/good_deed_prompt.tscn")


func _ready() -> void:
	_load_events()


func _load_events() -> void:
	var dir = DirAccess.open("res://data/events/good/")
	if dir == null:
		return
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".tres"):
			var resource = load("res://data/events/good/".path_join(filename))
			if resource != null:
				_all_good_events.append(resource)
		filename = dir.get_next()
	dir.list_dir_end()
	good_event_pool = _all_good_events.duplicate()


func load_for_errand(errand: ErrandData) -> void:
	## Filter the event pool to only the events listed in the errand definition.
	good_event_pool = _all_good_events.filter(func(e: Resource) -> bool:
		return e.id in errand.good_event_ids
	)
	recent_events.clear()


func try_spawn_event() -> bool:
	## Returns true if an event was spawned, false if skipped (already active or empty pool).
	if _active_event != null:
		return false
	var event = _roll_event()
	if event == null:
		return false
	_active_event = event
	_track_recent(event.id)
	_spawn_prompt(event)
	good_deed_prompt_shown.emit(event)
	event_spawned.emit(event, _prompt_instance)
	return true


func handle_interact() -> void:
	if _active_event == null:
		return
	var event = _active_event
	_dismiss_prompt()
	GameManager.add_karma(event.karma_reward)
	good_deed_completed.emit(event)
	event_resolved.emit(event, true)


func _roll_event() -> EventData:
	if good_event_pool.is_empty():
		return null
	var available = good_event_pool.filter(func(e: Resource) -> bool:
		return not (e.id in recent_events)
	)
	if available.is_empty():
		available = good_event_pool
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
	add_child(_prompt_instance)       # @onready vars assigned here
	_prompt_instance.setup(event)     # safe to call after add_child


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
