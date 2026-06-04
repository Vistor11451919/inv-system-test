class_name EnemyDieState
extends State

var _die_started: bool = false

func enter(_prev_state: String, _params: Dictionary = {}):
	if _die_started:
		return
	_die_started = true
	var enemy = _actor
	enemy.velocity = Vector2.ZERO
	enemy.set_collision_layer_value(1, false)
	enemy.set_collision_mask_value(1, false)
	var delay = enemy.config.death_delay if enemy.config else 0.5
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(enemy):
		enemy._die_cleanup()

func physics_update(_delta: float):
	pass
