class_name EnemyHurtState
extends State

var _stun_timer: float = 0.0

func enter(_prev_state: String, _params: Dictionary = {}):
	var enemy = _actor
	enemy.velocity.x = 0
	enemy._visual.add_mark("anim", 2, {"name": "hurt"})
	enemy._visual.add_mark("flash", 3, {"color": Color(2, 0.5, 0.5), "duration": 0.15})
	_stun_timer = 0.3

func physics_update(delta: float):
	var enemy = _actor
	if enemy.gravity_amount > 0:
		enemy.velocity.y += enemy.gravity_amount * delta
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, 500 * delta)

	_stun_timer -= delta
	if _stun_timer <= 0:
		# 晕眩结束后，如果玩家还在检测范围内则追击
		if enemy.player_detected and enemy.player_entity:
			_sm.transition_to("Chase")
		else:
			_sm.transition_to("Patrol")
