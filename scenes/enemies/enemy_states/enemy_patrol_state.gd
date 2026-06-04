class_name EnemyPatrolState
extends State

var _patrol_index: int = 0
var _waiting: bool = false
var _wait_timer: float = 0.0

func enter(_prev_state: String, _params: Dictionary = {}):
	var enemy = _actor
	_patrol_index = 0
	_waiting = false
	_wait_timer = 0.0
	enemy.velocity.x = 0

func physics_update(delta: float):
	var enemy = _actor

	if enemy.gravity_amount > 0:
		enemy.velocity.y += enemy.gravity_amount * delta

	# 检测玩家 → 追击
	if enemy.player_detected and enemy.player_entity:
		var dist = enemy.global_position.distance_to(enemy.player_entity.global_position)
		var detect = enemy.config.detection_radius if enemy.config else 200.0
		if dist <= detect:
			_sm.transition_to("Chase")
			return

	# 巡逻逻辑
	if _waiting:
		_wait_timer -= delta
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, 500 * delta)
		if _wait_timer <= 0:
			_waiting = false
			_next_patrol_point(enemy)
		return

	var points = enemy.config.patrol_points if enemy.config else []
	if points.is_empty():
		# 没有巡逻点：站桩
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, 500 * delta)
		if enemy.player_detected and enemy.player_entity:
			var dir = sign(enemy.player_entity.global_position.x - enemy.global_position.x)
			enemy.set_facing(dir)
			if enemy.can_attack():
				var dist = enemy.global_position.distance_to(enemy.player_entity.global_position)
				var atk = enemy.config.attack_radius if enemy.config else 40.0
				if dist <= atk:
					_sm.transition_to("Attack")
	else:
		_move_to_current_point(enemy, delta)

func _next_patrol_point(enemy):
	var points = enemy.config.patrol_points if enemy.config else []
	if points.is_empty():
		return
	_patrol_index = (_patrol_index + 1) % points.size()

func _move_to_current_point(enemy, delta):
	var points = enemy.config.patrol_points if enemy.config else []
	if points.is_empty() or _patrol_index >= points.size():
		return

	# patrol_points 是相对于 spawn_position 的偏移
	var target = enemy.spawn_position + points[_patrol_index]
	var dir = sign(target.x - enemy.global_position.x)
	enemy.set_facing(dir)

	var speed = enemy.config.patrol_speed if enemy.config else 60.0
	enemy.velocity.x = dir * speed

	if abs(target.x - enemy.global_position.x) < 4.0:
		enemy.velocity.x = 0
		_waiting = true
		_wait_timer = enemy.config.patrol_pause if enemy.config else 1.0
