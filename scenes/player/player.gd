extends CharacterBody2D

## Player character with isometric WASD movement and click-to-move.

@export var speed: float = 200.0

## Click-to-move target (null when not active)
var _move_target: Variant = null

# Isometric transform: converts screen-space input to isometric world-space
# Screen right → iso east (down-right), Screen up → iso north (up-right)
const ISO_MATRIX = Transform2D(
	Vector2(1.0, 0.5),   # screen X → iso
	Vector2(-1.0, 0.5),  # screen Y → iso
	Vector2.ZERO
)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_move_target = get_global_mouse_position()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			EventManager.handle_interact()


func _physics_process(_delta: float) -> void:
	var input_dir = _get_keyboard_input()

	if input_dir != Vector2.ZERO:
		# Keyboard input cancels any click-to-move
		_move_target = null
		# Transform screen-space input to isometric
		var iso_dir = (ISO_MATRIX * input_dir).normalized()
		velocity = iso_dir * speed
	elif _move_target != null:
		# Click-to-move
		var to_target = _move_target - global_position
		if to_target.length() < 5.0:
			# Arrived at click target
			_move_target = null
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _get_keyboard_input() -> Vector2:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	return dir
