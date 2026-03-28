extends Resource
class_name ErrandData

## Schema for an errand. Create .tres instances in data/errands/ — no code changes needed.

@export var id: StringName = ""
@export var display_name: String = ""
@export var description: String = ""
@export var player_mode: StringName = &"pedestrian"  # "pedestrian", "bike", "car"
@export var street_length: int = 30
@export var destination_name: String = ""
@export var bad_event_ids: Array[StringName] = []
@export var good_event_ids: Array[StringName] = []
