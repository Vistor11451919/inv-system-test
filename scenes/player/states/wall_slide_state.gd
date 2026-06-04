class_name WallSlideState
extends State

var _wall_dir: int = 0

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	_wall_dir = _get_wall_dir(player)
	player._visual.add_mark("anim", 2, {"name": "wall_slide"})
	player.jumps_used = 1

func physics_update(delta: float):
	var player: Player = _actor
	_wall_dir = _get_wall_dir(player)

	if not _wall_dir:
		_sm.transition_to("Fall")
		return
	if player.is_on_floor():
		_sm.transition_to("Idle")
		return
	if player._input.consume_action("jump"):
		_sm.transition_to("WallJump", {"wall_dir": -_wall_dir})
		return
	if player._input.consume_action("dash") and AbilityRegistry.has_ability("dash"):
		_sm.transition_to("Dash")
		return

	player.velocity.y = min(player.velocity.y, player._gravity * 0.2)
	player.velocity.x = 0.0
	player.set_facing(_wall_dir)

func _get_wall_dir(player: Player) -> int:
	if not player.is_on_wall():
		return 0
	var normal = player.get_wall_normal()
	return sign(normal.x)
