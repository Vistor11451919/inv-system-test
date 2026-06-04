class_name JumpState
extends State

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	player.jumps_used += 1
	player.velocity.y = player.jump_velocity
	player._visual.add_mark("anim", 2, {"name": "jump"})
	player._coyote_timer = 0.0

func physics_update(_delta: float):
	var player: Player = _actor

	if player._input.is_action_just_released("jump") and player.velocity.y < 0:
		player.velocity.y *= 0.5

	var dir = player._input.get_move_direction()
	if dir != 0:
		player.velocity.x = dir * player.move_speed
		player.set_facing(1 if dir > 0 else -1)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.move_speed * 4 * _delta)
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
	if player.velocity.y >= 0:
		_sm.transition_to("Fall")
		return
