class_name EnemyChaseState
extends State

func enter(_prev_state: String, _params: Dictionary = {}):
	_actor.velocity.x = 0

func physics_update(delta: float):
	var enemy = _actor

	# 重力
	if enemy.gravity_amount > 0:
		enemy.velocity.y += enemy.gravity_amount * delta

	# 没有玩家目标 → 回巡逻
	if not enemy.player_detected or not enemy.player_entity:
		_sm.transition_to("Patrol")
		return

	var target = enemy.player_entity
	var dist = enemy.global_position.distance_to(target.global_position)
	var detect = enemy.config.detection_radius if enemy.config else 200.0
	var atk = enemy.config.attack_radius if enemy.config else 40.0

	# 超出检测范围 → 回巡逻
	if dist > detect:
		_sm.transition_to("Patrol")
		return

	# 朝向玩家
	var dir = sign(target.global_position.x - enemy.global_position.x)
	enemy.set_facing(dir)

	# 攻击范围内 → 攻击
	if dist <= atk and enemy.can_attack():
		_sm.transition_to("Attack")
		return

	# 追击移动
	var speed = enemy.config.chase_speed if enemy.config else 100.0
	enemy.velocity.x = dir * speed

	# 远程型：保持距离（不贴脸）
	if enemy.config and enemy.config.ranged and dist < atk * 0.5:
		enemy.velocity.x = -dir * speed
