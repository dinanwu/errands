extends Node

## Tracks karma, weapon unlocks, and errand state.
## Central signal hub — other systems connect to signals here.

signal karma_changed(new_total: int, delta: int)
signal weapon_unlocked(weapon_id: StringName)
signal weapon_used(weapon_id: StringName)
signal weapon_cooldown_finished(weapon_id: StringName)
signal errand_started(errand_id: StringName)
signal errand_completed(errand_id: StringName)

var karma_points: int = 0
var unlocked_weapons: Array[StringName] = []
var current_errand_id: StringName = ""
var errand_progress: float = 0.0
var weapon_cooldowns: Dictionary = {}


func add_karma(amount: int) -> void:
	karma_points += amount
	karma_changed.emit(karma_points, amount)


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


func start_errand(errand_id: StringName) -> void:
	current_errand_id = errand_id
	errand_progress = 0.0
	errand_started.emit(errand_id)


func complete_errand() -> void:
	var id = current_errand_id
	errand_progress = 1.0
	current_errand_id = ""
	errand_completed.emit(id)
