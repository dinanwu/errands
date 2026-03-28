extends CanvasLayer

## HUD overlay. Displays karma, errand progress, and weapon bar.
## Listens to GameManager signals — never references GameManager methods directly.

@onready var karma_label: Label = $TopBar/KarmaLabel
@onready var progress_label: Label = $TopBar/ProgressLabel


func _ready() -> void:
	GameManager.karma_changed.connect(_on_karma_changed)
	karma_label.text = "Karma: %d" % GameManager.karma_points


func _on_karma_changed(new_total: int, _delta: int) -> void:
	karma_label.text = "Karma: %d" % new_total
