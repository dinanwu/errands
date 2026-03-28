extends Resource
class_name WeaponData

## Schema for a weapon. Create .tres instances in data/weapons/ — no code changes needed.

@export var id: StringName = ""
@export var display_name: String = ""
@export var description: String = ""
@export var karma_cost: int = 0
@export var cooldown_seconds: float = 5.0
@export var effect_scene_path: String = ""
@export var tier: int = 1
