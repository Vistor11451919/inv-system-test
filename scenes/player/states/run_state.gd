class_name RunState
extends State

var _dir_buffer: float = 0.0
const _DIR_BUFFER_MAX: float = 0.06

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	player.jumps_used = 0
	player._visual.add_mark("anim", 2, {"name": "run"})
	_dir_buffer = 0.0

func physics_update(delta: float):
	var player: Player = _actor
	var dir = player._input.get_move_direction()

	if dir == 0:
		_dir_buffer += delta
		if _dir_buffer < _DIR_BUFFER_MAX:
			dir = player.facing_direction
		else:
			_sm.transition_to("Idle")
			return
	else:
		_dir_buffer = 0.0

	if player._input.consume_action("jump"):
		_sm.transition_to("Jump")
		return
	if player._input.consume_action("attack"):
		_sm.transition_to("Attack")
		return
	if player._input.consume_action("dash") and AbilityRegistry.has_ability("dash"):
		_sm.transition_to("Dash")
		return
	if player._input.consume_action("ninja_art_1"):
		var art = DataManager.get_equipped_ninja_art(0)
		if art:
			_sm.transition_to("NinjaArt", {"art": art})
			return
	if player._input.consume_action("ninja_art_2"):
		var art = DataManager.get_equipped_ninja_art(1)
		if art:
			_sm.transition_to("NinjaArt", {"art": art})
			return
	if player._input.consume_action("crouch"):
		if AbilityRegistry.has_ability("slide"):
			_sm.transition_to("Slide")
		else:
			_sm.transition_to("Crouch")
		return
	if not player.is_on_floor():
		_sm.transition_to("Fall")
		return

	var speed = player.move_speed
	var anim_name = "run"
	if Input.is_action_pressed("walk_modifier"):
		speed *= 0.4
		anim_name = "walk"
	player._visual.add_mark("anim", 2, {"name": anim_name})
	player.velocity.x = dir * speed
	player.set_facing(1 if dir > 0 else -1)
