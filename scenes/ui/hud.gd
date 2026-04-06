extends CanvasLayer

## HUD overlay. Displays karma, errand progress, and weapon bar.
## Listens to GameManager signals — never references GameManager methods directly
## (except for initial state and weapon selection).

@onready var karma_label: Label = $TopBar/KarmaLabel
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var weapon_bar: HBoxContainer = $WeaponBar

## Ordered list of unlocked weapon IDs (matches button order in weapon bar).
var _weapon_order: Array[StringName] = []
var _weapon_buttons: Dictionary = {}


func _ready() -> void:
	GameManager.karma_changed.connect(_on_karma_changed)
	GameManager.weapon_unlocked.connect(_on_weapon_unlocked)
	GameManager.weapon_used.connect(_on_weapon_used)
	GameManager.weapon_cooldown_finished.connect(_on_weapon_cooldown_finished)
	GameManager.weapon_selected.connect(_on_weapon_selected)
	karma_label.text = "Karma: %d" % GameManager.karma_points


func _process(_delta: float) -> void:
	_update_cooldown_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_num = event.keycode - KEY_0
		if key_num >= 1 and key_num <= _weapon_order.size():
			GameManager.select_weapon(_weapon_order[key_num - 1])


func _on_karma_changed(new_total: int, _delta: int) -> void:
	karma_label.text = "Karma: %d" % new_total


func _on_weapon_unlocked(weapon_id: StringName) -> void:
	var data = GameManager.get_weapon_data(weapon_id)
	if data == null:
		return
	_weapon_order.append(weapon_id)
	var idx = _weapon_order.size()
	var btn = Button.new()
	btn.text = "%d: %s" % [idx, data.display_name]
	btn.pressed.connect(func(): GameManager.select_weapon(weapon_id))
	weapon_bar.add_child(btn)
	_weapon_buttons[weapon_id] = btn
	_update_selection()


func _on_weapon_used(weapon_id: StringName) -> void:
	var btn: Button = _weapon_buttons.get(weapon_id)
	if btn:
		btn.disabled = true


func _on_weapon_cooldown_finished(weapon_id: StringName) -> void:
	var btn: Button = _weapon_buttons.get(weapon_id)
	if btn:
		btn.disabled = false


func _on_weapon_selected(_weapon_id: StringName) -> void:
	_update_selection()


func _update_selection() -> void:
	for wid in _weapon_buttons:
		var btn: Button = _weapon_buttons[wid]
		btn.modulate = Color(1, 1, 0.6) if wid == GameManager.selected_weapon else Color.WHITE


func _update_cooldown_labels() -> void:
	for i in _weapon_order.size():
		var wid = _weapon_order[i]
		var btn: Button = _weapon_buttons[wid]
		var data = GameManager.get_weapon_data(wid)
		var remaining: float = GameManager.weapon_cooldowns.get(wid, 0.0)
		if remaining > 0:
			btn.text = "%s (%.1fs)" % [data.display_name, remaining]
		else:
			btn.text = "%d: %s" % [i + 1, data.display_name]
