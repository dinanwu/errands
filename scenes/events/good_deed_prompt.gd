extends CanvasLayer

## Temporary prompt shown when the player enters an event trigger zone.
## Auto-expires after DURATION seconds. Freed immediately on completion or expiry.

signal expired

@onready var event_label: Label = $Panel/VBox/EventLabel
@onready var prompt_label: Label = $Panel/VBox/PromptLabel

const DURATION: float = 8.0
var _timer: float = 0.0
var _expired: bool = false


func setup(data: EventData) -> void:
	event_label.text = data.display_name
	prompt_label.text = data.prompt_text


func _process(delta: float) -> void:
	if _expired:
		return
	_timer += delta
	if _timer >= DURATION:
		_expired = true
		expired.emit()
		queue_free()
