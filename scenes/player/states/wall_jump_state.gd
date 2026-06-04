class_name WallJumpState
extends State

@export var wall_jump_horizontal: float = 300.0
@export var wall_jump_vertical: float = -350.0

func enter(_prev_state: String, params: Dictionary = {}):
	var player: Player = _actor
	var wall_dir = params.get("wall_dir", 1)
	player.jumps_used = 1
	player.velocity = Vector2(-wall_dir * wall_jump_horizontal, wall_jump_vertical)
	player.set_facing(-wall_dir)
	player._visual.add_mark("anim", 2, {"name": "jump"})

func physics_update(_delta: float):
	var player: Player = _actor
	var dir = player._input.get_move_direction()
	if dir != 0:
		# 空中渐加速而非瞬间覆盖蹬墙初速，避免方向反转
		player.velocity.x = move_toward(player.velocity.x, dir * player.move_speed, player.move_speed * 4 * _delta)
		player.set_facing(1 if dir > 0 else -1)
	if player._input.consume_action("attack"):
		_sm.transition_to("Attack")
		return
	if player._input.consume_action("dash") and AbilityRegistry.has_ability("dash"):
		_sm.transition_to("Dash")
		return
	if player.velocity.y >= 0:
		_sm.transition_to("Fall")
		return
