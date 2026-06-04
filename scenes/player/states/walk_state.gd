class_name WalkState
extends State

@export var walk_speed: float = 80.0
@export var walk_duration: float = 1.0

var _elapsed: float = 0.0

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	player.jumps_used = 0
	_elapsed = 0.0
	player._visual.add_mark("anim", 2, {"name": "walk"})

func physics_update(delta: float):
	var player: Player = _actor
	var dir = player._input.get_move_direction()

	if dir == 0:
		_sm.transition_to("Idle")
		return

	_elapsed += delta

	if _elapsed >= walk_duration:
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
	if player._input.consume_action("crouch"):
		_sm.transition_to("Crouch")
		return
	if not player.is_on_floor():
		_sm.transition_to("Fall")
		return

	player.velocity.x = dir * walk_speed
	player.set_facing(1 if dir > 0 else -1)
