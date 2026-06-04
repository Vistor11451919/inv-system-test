class_name EnemyAttackState
extends State

var _locked_dir: int = 1
var _timer: float = 0.0
var _duration: float = 0.5
var _hitbox_active: bool = false

func enter(_prev_state: String, _params: Dictionary = {}):
	var enemy = _actor
	enemy.velocity.x = 0
	_locked_dir = enemy.facing_direction
	_timer = 0.0

	var use_ranged = enemy.config and enemy.config.ranged
	if not use_ranged and "_current_attack_patterns" in enemy:
		use_ranged = "projectile" in enemy._current_attack_patterns
	if use_ranged:
		_duration = 0.3
		_ranged_attack(enemy)
	else:
		_duration = 0.5
		_melee_attack(enemy)

func physics_update(delta: float):
	var enemy = _actor
	if enemy.gravity_amount > 0:
		enemy.velocity.y += enemy.gravity_amount * delta
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, 500 * delta)

	_timer += delta
	if _timer >= _duration:
		enemy.start_attack_cooldown()
		_sm.transition_to("Chase")

	if _hitbox_active and _timer >= 0.2:
		_disable_hitbox(enemy)

func _melee_attack(enemy):
	enemy.set_facing(_locked_dir)
	enemy._hitbox.damage = enemy.config.attack if enemy.config else 10.0
	enemy._hitbox.reset()
	enemy._hitbox.monitoring = true
	var hs = enemy._hitbox.get_node_or_null("CollisionShape2D")
	if hs:
		hs.disabled = false
	_hitbox_active = true

func _ranged_attack(enemy):
	var scene = enemy.config.projectile_scene
	if not scene:
		_sm.transition_to("Chase")
		return
	if not enemy.player_entity:
		_sm.transition_to("Chase")
		return

	var proj = scene.instantiate() as Node2D
	if not proj:
		return
	var spawn_pos = enemy.global_position + Vector2(enemy.facing_direction * 20, -8)
	proj.global_position = spawn_pos
	var dir = (enemy.player_entity.global_position - enemy.global_position).normalized()
	# 2D 平台游戏：钳制 Y 分量，保持水平攻击
	dir.y = 0.0
	if dir == Vector2.ZERO:
		dir = Vector2(enemy.facing_direction, 0)
	get_tree().current_scene.add_child(proj)
	if proj.has_method("launch"):
		var homing_target = enemy.player_entity if enemy.config and enemy.config.homing else null
		proj.launch(dir, enemy.config.projectile_speed, enemy.entity_id, enemy.config.attack,
			homing_target, enemy.config.homing_strength if enemy.config else 2.0)

func _disable_hitbox(enemy):
	if not is_instance_valid(enemy):
		return
	enemy._hitbox.monitoring = false
	var hs = enemy._hitbox.get_node_or_null("CollisionShape2D")
	if hs:
		hs.disabled = true
	_hitbox_active = false
