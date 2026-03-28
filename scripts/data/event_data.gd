extends Resource
class_name EventData

## Schema for a street event. Create .tres instances in data/events/ — no code changes needed.

@export var id: StringName = ""
@export var event_type: StringName = &"good_deed"  # "good_deed" or "bad_actor"
@export var display_name: String = ""
@export var description: String = ""
@export var prompt_text: String = ""
@export var karma_reward: int = 0
@export var weight: float = 1.0
@export var npc_scene_path: String = ""
