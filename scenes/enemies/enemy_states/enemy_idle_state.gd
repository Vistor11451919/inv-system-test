class_name EnemyIdleState
extends State

func physics_update(delta: float):
	var enemy = _actor
	if enemy.gravity_amount > 0:
		enemy.velocity.y += enemy.gravity_amount * delta
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, 500 * delta)

	if not enemy.player_entity:
		return

	enemy.set_facing(sign(enemy.player_entity.global_position.x - enemy.global_position.x))

	if not enemy.can_attack():
		return

	var dist = enemy.global_position.distance_to(enemy.player_entity.global_position)
	var atk_range = enemy.config.attack_radius if enemy.config else 40.0
	if dist <= atk_range:
		_sm.transition_to("Attack")
