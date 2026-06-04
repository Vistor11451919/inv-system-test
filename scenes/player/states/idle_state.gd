class_name IdleState
extends State

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	player.jumps_used = 0
	player._visual.add_mark("anim", 2, {"name": "idle"})

func physics_update(_delta: float):
	var player: Player = _actor
	if player._input.is_move_pressed():
		_sm.transition_to("Run")
		return
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
	if player._input.is_crouch_pressed():
		_sm.transition_to("Crouch")
		return
	if not player.is_on_floor():
		_sm.transition_to("Fall")
		return
	player.velocity.x = move_toward(player.velocity.x, 0, player.move_speed * 8 * _delta)
