extends Node

## Tracks karma, weapon unlocks, and errand state.
## Central signal hub — other systems connect to signals here.

signal karma_changed(new_total: int, delta: int)
signal weapon_unlocked(weapon_id: StringName)
signal weapon_selected(weapon_id: StringName)
signal weapon_used(weapon_id: StringName)
signal weapon_cooldown_finished(weapon_id: StringName)
signal errand_started(errand_id: StringName)
signal errand_completed(errand_id: StringName)

var karma_points: int = 0
var unlocked_weapons: Array[StringName] = []
var current_errand_id: StringName = ""
var errand_progress: float = 0.0
var weapon_cooldowns: Dictionary = {}
var selected_weapon: StringName = &""

## weapon_id → WeaponData, loaded from res://data/weapons/ on startup.
var _weapon_registry: Dictionary = {}


func _ready() -> void:
	_load_weapons()


func _process(delta: float) -> void:
	_tick_cooldowns(delta)


func add_karma(amount: int) -> void:
	karma_points += amount
	karma_changed.emit(karma_points, amount)
	_check_weapon_unlocks()


func spend_karma(amount: int) -> bool:
	if karma_points < amount:
		return false
	karma_points -= amount
	karma_changed.emit(karma_points, -amount)
	return true


func is_weapon_unlocked(weapon_id: StringName) -> bool:
	return weapon_id in unlocked_weapons


func unlock_weapon(weapon_id: StringName) -> void:
	if not is_weapon_unlocked(weapon_id):
		unlocked_weapons.append(weapon_id)
		weapon_unlocked.emit(weapon_id)
		# Auto-select the first weapon unlocked
		if selected_weapon == &"":
			selected_weapon = weapon_id
			weapon_selected.emit(selected_weapon)


func select_weapon(weapon_id: StringName) -> void:
	if weapon_id == selected_weapon:
		selected_weapon = &""  # Toggle off
	elif is_weapon_unlocked(weapon_id):
		selected_weapon = weapon_id
	weapon_selected.emit(selected_weapon)


func can_use_weapon(weapon_id: StringName) -> bool:
	return is_weapon_unlocked(weapon_id) and not weapon_cooldowns.has(weapon_id)


func use_weapon(weapon_id: StringName) -> WeaponData:
	if not can_use_weapon(weapon_id):
		return null
	var data: WeaponData = _weapon_registry[weapon_id]
	weapon_cooldowns[weapon_id] = data.cooldown_seconds
	weapon_used.emit(weapon_id)
	return data


func get_weapon_data(weapon_id: StringName) -> WeaponData:
	return _weapon_registry.get(weapon_id)


func start_errand(errand_id: StringName) -> void:
	current_errand_id = errand_id
	errand_progress = 0.0
	errand_started.emit(errand_id)


func complete_errand() -> void:
	var id = current_errand_id
	errand_progress = 1.0
	current_errand_id = ""
	errand_completed.emit(id)


func _load_weapons() -> void:
	var dir = DirAccess.open("res://data/weapons/")
	if dir == null:
		return
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".tres"):
			var resource = load("res://data/weapons/".path_join(filename))
			if resource is WeaponData:
				_weapon_registry[resource.id] = resource
		filename = dir.get_next()
	dir.list_dir_end()


func _check_weapon_unlocks() -> void:
	for weapon_id in _weapon_registry:
		if not is_weapon_unlocked(weapon_id):
			var data: WeaponData = _weapon_registry[weapon_id]
			if karma_points >= data.karma_cost:
				unlock_weapon(weapon_id)


func _tick_cooldowns(delta: float) -> void:
	var finished: Array[StringName] = []
	for weapon_id in weapon_cooldowns:
		weapon_cooldowns[weapon_id] -= delta
		if weapon_cooldowns[weapon_id] <= 0.0:
			finished.append(weapon_id)
	for weapon_id in finished:
		weapon_cooldowns.erase(weapon_id)
		weapon_cooldown_finished.emit(weapon_id)
