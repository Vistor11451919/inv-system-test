class_name InputHandler
extends Node

const BUFFER_WINDOW: float = 0.15

var _buffer: Dictionary = {}
var _move_direction: float = 0.0
var _is_input_enabled: bool = true

func _process(delta: float):
	# 递减缓冲计时器
	var expired: Array[String] = []
	for action in _buffer:
		_buffer[action] -= delta
		if _buffer[action] <= 0.0:
			expired.append(action)
	for action in expired:
		_buffer.erase(action)

func _physics_process(_delta):
	_update_move()

func _update_move():
	_move_direction = Input.get_axis("move_left", "move_right")

func buffer_action(action: String):
	_buffer[action] = BUFFER_WINDOW

func consume_action(action: String) -> bool:
	if not _is_input_enabled:
		return false
	if _buffer.has(action) and _buffer[action] > 0:
		_buffer.erase(action)
		return true
	var pressed = Input.is_action_just_pressed(action)
	return pressed

func flush_all():
	var move = _move_direction
	_buffer.clear()
	_move_direction = move

func set_input_enabled(enabled: bool):
	_is_input_enabled = enabled
	if not enabled:
		_buffer.clear()

func is_input_enabled() -> bool:
	return _is_input_enabled

func get_move_direction() -> float:
	return _move_direction if _is_input_enabled else 0.0

func is_action_just_released(action: String) -> bool:
	if not _is_input_enabled:
		return false
	return Input.is_action_just_released(action)

func is_move_pressed() -> bool:
	return abs(get_move_direction()) > 0.1

func is_crouch_pressed() -> bool:
	if not _is_input_enabled:
		return false
	return Input.is_action_pressed("crouch")
