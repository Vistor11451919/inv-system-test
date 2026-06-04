class_name FallState
extends State

func enter(_prev_state: String, _params: Dictionary = {}):
	_actor._visual.add_mark("anim", 2, {"name": "fall"})

func physics_update(_delta: float):
	var player: Player = _actor

	if player._input.consume_action("jump") and player.can_coyote_jump():
		player.consume_coyote()
		_sm.transition_to("Jump")
		return

	if player._input.consume_action("jump") and AbilityRegistry.has_ability("double_jump") and player.jumps_used < 2:
		_sm.transition_to("Jump")
		return

	var dir = player._input.get_move_direction()
	if dir != 0:
		player.velocity.x = dir * player.move_speed
		player.set_facing(1 if dir > 0 else -1)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.move_speed * 3 * _delta)
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

	if player.is_on_floor():
		_sm.transition_to("Idle")
		return

	if AbilityRegistry.has_ability("wall_jump") and _can_wall_slide(player, dir):
		_sm.transition_to("WallSlide")
		return

func _can_wall_slide(player: Player, dir: float) -> bool:
	if dir == 0:
		return false
	if not player.is_on_wall():
		return false
	var normal = player.get_wall_normal()
	return sign(normal.x) != sign(dir)
