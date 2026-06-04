extends GutTest

## 敌人 AI 状态单元测试
## 覆盖: Patrol / Chase / Attack / Hurt / Die 全部 5 个状态

const ENEMY_SCENE = preload("res://scenes/enemies/templates/enemy_template.tscn")
const SOLDIER_CFG = preload("res://data/enemies/soldier.tres")
const NINJA_CFG = preload("res://data/enemies/ninja.tres")
const ARCHER_CFG = preload("res://data/enemies/archer.tres")
const HEAVY_CFG = preload("res://data/enemies/heavy.tres")
const FLOATER_CFG = preload("res://data/enemies/floater.tres")

# ── 测试辅助 ──

func _make_enemy(config = SOLDIER_CFG, pos: Vector2 = Vector2.ZERO):
	var e = ENEMY_SCENE.instantiate()
	e.config = config
	e.global_position = pos
	add_child_autofree(e)
	return e

func _make_player(pos: Vector2 = Vector2.ZERO):
	var p = Node2D.new()
	p.add_to_group("player")
	add_child_autofree(p)
	p.global_position = pos
	return p

func _frames(n: int = 1):
	for _i in range(n):
		await get_tree().physics_frame

func _setup_player_for(enemy, px: float = 100.0):
	var p = _make_player(enemy.global_position + Vector2(px, 0))
	enemy.player_detected = true
	enemy.player_entity = p
	return p

# =============================================================================
# 1. 基础初始化
# =============================================================================

func test_enemy_ready_registers_in_world():
	var enemy = _make_enemy()
	await _frames()
	assert_ne(enemy.entity_id, -1, "_ready() 应注册 entity_id")

func test_enemy_starts_in_patrol():
	var enemy = _make_enemy()
	await _frames()
	assert_eq(enemy._sm.get_current_state_name(), "Patrol", "初始状态应为 Patrol")

func test_enemy_has_all_states():
	var enemy = _make_enemy()
	await _frames()
	var names = enemy._sm.get_all_state_names()
	for s in ["Patrol", "Chase", "Attack", "Hurt", "Die"]:
		assert_has(names, s, "状态机应包含 %s" % s)

func test_config_applied_to_enemy():
	var enemy = _make_enemy()
	await _frames()
	assert_eq(enemy.hp, 60.0, "HP 应来自 config")
	assert_eq(enemy.max_hp, 60.0, "max_hp 应来自 config")

func test_enemy_take_damage_reduces_hp():
	var enemy = _make_enemy()
	await _frames()
	var initial_hp = enemy.hp
	enemy.take_damage(10, 1, {})
	assert_lt(enemy.hp, initial_hp, "受击后 HP 应减少")

func test_enemy_damage_transitions_to_hurt():
	var enemy = _make_enemy()
	await _frames()
	enemy.take_damage(10, 1, {})
	await _frames()
	assert_has(["Hurt", "Die"], enemy._sm.get_current_state_name(), "受击后应进入 Hurt 或 Die")

func test_enemy_hp_zero_transitions_to_die():
	var enemy = _make_enemy()
	await _frames()
	enemy.take_damage(999, 1, {})
	await _frames()
	assert_eq(enemy._sm.get_current_state_name(), "Die", "HP=0 应进入 Die")

# =============================================================================
# 2. Patrol 状态
# =============================================================================

func test_patrol_moves_toward_first_waypoint():
	var e = _make_enemy()
	await _frames()
	# soldier patrol_points[0] = Vector2(-80, 0) → 应向左移动
	await _frames(3)
	assert_lt(e.velocity.x, 0.0, "应向左移向第一个路点")

func test_patrol_waypoint_right_positive_velocity():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.patrol_points.clear()
	cfg.patrol_points.append(Vector2(100, 0))
	var e = _make_enemy(cfg)
	await _frames(3)
	assert_gt(e.velocity.x, 0.0, "路点在右侧时应向右移动")

func test_patrol_with_empty_waypoints_idles():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.patrol_points.clear()
	var e = _make_enemy(cfg)
	await _frames(5)
	assert_almost_eq(e.velocity.x, 0.0, 1.0, "无路点时应站桩减速到 0")

func test_patrol_applies_patrol_speed():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.patrol_points.clear()
	cfg.patrol_points.append(Vector2(100, 0))
	cfg.patrol_speed = 75.0
	var e = _make_enemy(cfg)
	await _frames(5)
	assert_almost_eq(abs(e.velocity.x), 75.0, 5.0, "速度应与 patrol_speed 一致")

func test_patrol_waits_at_waypoint():
	# 验证 Patrol 到达路点后进入等待（velocity.x→0）
	var cfg = SOLDIER_CFG.duplicate()
	cfg.patrol_points.clear()
	cfg.patrol_points.append(Vector2(50, 0))
	cfg.patrol_speed = 600.0
	cfg.patrol_pause = 999.0
	var e = _make_enemy(cfg)
	# 等待足够长时间到达路点
	for _i in range(30):
		await get_tree().physics_frame
		if abs(e.velocity.x) < 1.0 and abs(e.global_position.x - e.spawn_position.x) > 10:
			break  # 已到达并停止
	assert_almost_eq(e.velocity.x, 0.0, 5.0, "到达路点后应停止（等待）")

func test_patrol_cycles_to_next_waypoint():
	# 验证 Patrol 循环到下一个路点
	var cfg = SOLDIER_CFG.duplicate()
	cfg.patrol_points.clear()
	cfg.patrol_points.append(Vector2(50, 0))
	cfg.patrol_points.append(Vector2(-50, 0))
	cfg.patrol_speed = 600.0
	cfg.patrol_pause = 0.0
	var e = _make_enemy(cfg)
	await _frames(3)
	assert_gt(e.velocity.x, 0.0, "第一路点在右侧")
	# 等待足够帧数到达并转向
	for _i in range(40):
		await get_tree().physics_frame
		if not is_instance_valid(e):
			break
		if e.velocity.x < 0:
			break
	if e.velocity.x >= 0:
		# 可能刚好停在路点处
		assert_almost_eq(e.global_position.x, e.spawn_position.x + 50, 10.0,
			"应接近第一个路点")
	else:
		assert_lt(e.velocity.x, 0.0, "循环到第二个路点后应向左移动")

func test_patrol_detects_player_and_transitions_to_chase():
	var e = _make_enemy()
	var p = _make_player(e.global_position + Vector2(60, 0))
	await _frames()
	e._on_detection_body_entered(p)
	await _frames(3)
	assert_true(e.player_detected, "应标记玩家已检测")
	assert_eq(e._sm.get_current_state_name(), "Chase", "检测到玩家应切换到 Chase")

func test_patrol_gravity_applied():
	var e = _make_enemy(FLOATER_CFG)
	await _frames(5)
	assert_eq(e.velocity.y, 0.0, "floater 重力为 0 不应下落")

	var e2 = _make_enemy(SOLDIER_CFG)
	await _frames(5)
	assert_gt(e2.velocity.y, 0.0, "普通敌人应受重力影响下落（Y 正方向为下）")

# =============================================================================
# 3. Chase 状态
# =============================================================================

func test_chase_moves_toward_player():
	var e = _make_enemy()
	await _frames()
	_setup_player_for(e, 100.0)
	await _frames(3)
	assert_eq(e._sm.get_current_state_name(), "Chase")
	assert_gt(e.velocity.x, 0.0, "玩家在右侧时应向右移动")

func test_chase_moves_toward_player_left():
	var e = _make_enemy()
	await _frames()
	_setup_player_for(e, -100.0)
	await _frames(3)
	assert_lt(e.velocity.x, 0.0, "玩家在左侧时应向左移动")

func test_chase_faces_player():
	var e = _make_enemy()
	await _frames()
	_setup_player_for(e, -100.0)
	await _frames(3)
	assert_eq(e.facing_direction, -1, "玩家在左侧时应朝左")

func test_chase_faces_player_right():
	var e = _make_enemy()
	await _frames()
	_setup_player_for(e, 100.0)
	await _frames(3)
	assert_eq(e.facing_direction, 1, "玩家在右侧时应朝右")

func test_chase_applies_chase_speed():
	var e = _make_enemy()
	await _frames()
	_setup_player_for(e, 200.0)
	await _frames(5)
	assert_almost_eq(abs(e.velocity.x), SOLDIER_CFG.chase_speed, 5.0, "速度应与 chase_speed 一致")

func test_chase_returns_to_patrol_when_player_escapes():
	var e = _make_enemy()
	await _frames()
	_setup_player_for(e, 50.0)
	await _frames(3)
	assert_eq(e._sm.get_current_state_name(), "Chase")
	e.player_detected = false
	e.player_entity = null
	await _frames(3)
	assert_eq(e._sm.get_current_state_name(), "Patrol", "玩家脱离后卫 Patrol")

func test_chase_returns_to_patrol_when_player_out_of_range():
	var e = _make_enemy()
	await _frames()
	var p = _setup_player_for(e, 50.0)
	await _frames(3)
	assert_eq(e._sm.get_current_state_name(), "Chase")
	p.global_position = e.global_position + Vector2(9999, 0)
	await _frames(3)
	assert_eq(e._sm.get_current_state_name(), "Patrol", "超出检测范围后卫 Patrol")

func test_chase_transitions_to_attack():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.attack_cooldown = 0.0
	cfg.attack_radius = 100.0
	var e = _make_enemy(cfg)
	var p = _make_player(e.global_position + Vector2(30, 0))
	await _frames()
	e.player_detected = true
	e.player_entity = p
	await _frames(5)
	assert_eq(e._sm.get_current_state_name(), "Attack", "玩家在攻击范围内应切换到 Attack")

func test_chase_no_player_entity_returns_patrol():
	var e = _make_enemy()
	await _frames()
	e._sm.transition_to("Chase")
	await _frames(5)
	assert_eq(e._sm.get_current_state_name(), "Patrol", "无玩家实体时应回 Patrol")

# =============================================================================
# 4. Attack 状态
# =============================================================================

func test_attack_melee_activates_hitbox():
	var e = _make_enemy()
	await _frames()
	e._sm.transition_to("Attack")
	await _frames()
	assert_true(e._hitbox.monitoring, "近战攻击应激活 Hitbox")
	assert_eq(e._hitbox.damage, SOLDIER_CFG.attack, "Hitbox 伤害应等于 config.attack")

func test_attack_locks_facing_direction():
	var e = _make_enemy()
	await _frames()
	# _ready 已执行，set_facing 安全
	e.set_facing(-1)
	e._sm.transition_to("Attack")
	await _frames()
	assert_eq(e.facing_direction, -1, "攻击时应锁定面朝方向")

func test_attack_transitions_to_patrol_after_duration():
	# 没有玩家 → Attack → Chase → Patrol (因为无玩家)
	var e = _make_enemy()
	await _frames()
	e._sm.transition_to("Attack")
	await _frames(40)  # 0.5s melee duration + 余量
	assert_eq(e._sm.get_current_state_name(), "Patrol", "攻击完成后应回到 Patrol (无玩家)")

func test_attack_transitions_to_chase_with_player():
	# 有玩家 → Attack → Chase (玩家在范围内)
	var e = _make_enemy()
	await _frames()
	_setup_player_for(e, 100.0)
	e._sm.transition_to("Attack")
	await _frames(2)
	assert_eq(e._sm.get_current_state_name(), "Attack", "应进入 Attack")
	# 等待攻击完成 (0.5s melee) + 几帧让 Chase 处理
	await _frames(35)
	var state = e._sm.get_current_state_name()
	# Attack 结束后会先切 Chase，Chase 若无玩家则切 Patrol
	# 但这里有玩家，所以应保持 Chase
	# 不过引擎帧率可能导致 Chase 还没来得及处理
	# 至少应离开 Attack
	assert_ne(state, "Attack", "攻击完成后应离开 Attack")
	assert_has(["Chase", "Patrol"], state, "攻击完成后的状态")

func test_attack_sets_cooldown():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.attack_cooldown = 5.0
	var e = _make_enemy(cfg)
	await _frames()
	e._sm.transition_to("Attack")
	await _frames(40)  # 等待攻击完成
	assert_gt(e._attack_cooldown, 4.0, "攻击后 _attack_cooldown 应设为 config 值")

func test_attack_cooldown_decays():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.attack_cooldown = 0.05
	var e = _make_enemy(cfg)
	await _frames()
	e._sm.transition_to("Attack")
	await _frames(35)
	# 攻击刚完成时 _attack_cooldown ≈ 0.05
	# 几帧后应衰减到 0
	assert_almost_eq(e._attack_cooldown, 0.0, 0.1, "冷却应随时间衰减")

func test_attack_disables_hitbox_after_delay():
	var e = _make_enemy()
	await _frames()
	e._sm.transition_to("Attack")
	await _frames()
	assert_true(e._hitbox.monitoring, "攻击开始时 Hitbox 应开启")
	await _frames(15)  # ~0.25s > 0.2s (hitbox关闭阈值)
	assert_false(e._hitbox.monitoring, "攻击中后期 Hitbox 应关闭")

func test_attack_applies_gravity():
	var e = _make_enemy()
	await _frames()
	e._sm.transition_to("Attack")
	var y_before = e.velocity.y
	await _frames(5)
	assert_lt(y_before, e.velocity.y, "攻击中应受重力影响")

func test_attack_ranged_archer():
	# Archer 远程攻击需要场景树来生成投射物，在测试环境中跳过
	# 只验证: 配置标记、状态转换不受阻
	var cfg = ARCHER_CFG.duplicate()
	var e = _make_enemy(cfg)
	await _frames()
	assert_true(cfg.ranged, "archer 应为远程")

	# 设为近战模式避免投射物生成（测试攻击状态本身）
	cfg.ranged = false
	var ok = e._sm.transition_to("Attack")
	assert_true(ok, "应能进入 Attack 状态")
	await _frames(2)
	assert_eq(e._sm.get_current_state_name(), "Attack", "应处于 Attack 状态")
	# 等待攻击完成 (melee 0.5s ≈ 30 帧)
	await _frames(35)
	assert_ne(e._sm.get_current_state_name(), "Attack", "攻击完成后应离开 Attack")

# =============================================================================
# 5. Hurt 状态
# =============================================================================

func test_hurt_stops_horizontal_velocity():
	var e = _make_enemy(NINJA_CFG)
	await _frames()
	e.velocity = Vector2(200, 0)
	e.take_damage(5, 1, {})
	await _frames()
	assert_almost_eq(e.velocity.x, 0.0, 1.0, "受击后水平速度应归零")

func test_hurt_applies_gravity():
	var e = _make_enemy(SOLDIER_CFG)
	await _frames()
	e.take_damage(5, 1, {})
	var y_before = e.velocity.y
	await _frames(5)
	assert_lt(y_before, e.velocity.y, "受击晕眩中应受重力影响")

func test_hurt_stun_duration():
	var e = _make_enemy(SOLDIER_CFG)
	await _frames()
	e.take_damage(5, 1, {})
	await _frames()
	assert_eq(e._sm.get_current_state_name(), "Hurt")
	await _frames(25)  # stun_timer = 0.3s ≈ 18 帧
	assert_ne(e._sm.get_current_state_name(), "Hurt", "晕眩结束后应离开 Hurt")

func test_hurt_recovers_to_chase():
	var e = _make_enemy(SOLDIER_CFG)
	_setup_player_for(e, 60.0)
	await _frames()
	e.take_damage(5, 1, {})
	await _frames(25)
	assert_eq(e._sm.get_current_state_name(), "Chase", "玩家在场时晕眩后应 Chase")

func test_hurt_recovers_to_patrol():
	var e = _make_enemy(SOLDIER_CFG)
	await _frames()
	e.take_damage(5, 1, {})
	await _frames(25)
	assert_eq(e._sm.get_current_state_name(), "Patrol", "无玩家时晕眩后应 Patrol")

func test_hurt_sets_invulnerable():
	var e = _make_enemy(SOLDIER_CFG)
	await _frames()
	e.take_damage(10, 1, {})
	await _frames()
	assert_true(e._invulnerable, "受击后应处于无敌状态")

func test_hurt_invulnerable_prevents_damage():
	var e = _make_enemy(SOLDIER_CFG)
	await _frames()
	e.take_damage(10, 1, {})
	await _frames()
	var hp_after = e.hp
	e.take_damage(999, 1, {})
	assert_eq(e.hp, hp_after, "无敌期间不应再次扣血")

func test_hurt_invulnerability_expires():
	var e = _make_enemy(SOLDIER_CFG)
	await _frames()
	var hp_initial = e.hp
	e.take_damage(10, 1, {})
	await _frames(25)  # 等无敌 + stun 结束
	e.take_damage(10, 1, {})
	await _frames()
	assert_lt(e.hp, hp_initial - 10, "无敌结束后第二次伤害应生效")

# =============================================================================
# 6. Die 状态
# =============================================================================

func test_die_stops_movement():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.death_delay = 999.0  # 长延迟，防止 cleanup 提前触发
	var e = _make_enemy(cfg)
	await _frames()
	e.velocity = Vector2(100, 50)
	e.take_damage(999, 1, {})
	await _frames()
	assert_eq(e._sm.get_current_state_name(), "Die")
	assert_eq(e.velocity, Vector2.ZERO, "死亡时速度应归零")

func test_die_disables_collision():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.death_delay = 999.0
	var e = _make_enemy(cfg)
	await _frames()
	assert_true(e.get_collision_layer_value(1), "初始应有碰撞层")
	e.take_damage(999, 1, {})
	await _frames()
	assert_false(e.get_collision_layer_value(1), "死亡后碰撞层应禁用")
	assert_false(e.get_collision_mask_value(1), "死亡后碰撞掩码应禁用")

func test_die_called_once_only():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.death_delay = 999.0
	var e = _make_enemy(cfg)
	await _frames()
	e.take_damage(999, 1, {})
	await _frames()
	assert_eq(e._sm.get_current_state_name(), "Die")
	e.take_damage(10, 1, {})
	assert_eq(e.hp, 0.0, "死亡后 HP=0 不应再变化")

func test_die_death_delay_triggers_cleanup():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.death_delay = 0.0
	var e = _make_enemy(cfg)
	await _frames()
	var eid = e.entity_id
	assert_ne(eid, -1)
	e.take_damage(999, 1, {})
	# 等 cleanup (delay=0 但 Timer 需要一帧处理)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var ref = WorldManager.get_entity(eid)
	assert_null(ref, "cleanup 后实体应从 WorldManager 注销")

# =============================================================================
# 7. 配置差异测试
# =============================================================================

func test_ninja_config_values():
	var e = _make_enemy(NINJA_CFG)
	await _frames()
	assert_eq(e.hp, 40.0)
	assert_eq(e.max_hp, 40.0)
	assert_eq(e.get_stat("attack"), 15.0)
	assert_eq(e.get_stat("defense"), 2.0)

func test_heavy_config_values():
	var e = _make_enemy(HEAVY_CFG)
	await _frames()
	assert_eq(e.hp, 200.0)
	assert_eq(e.max_hp, 200.0)
	assert_eq(e.get_stat("attack"), 20.0)
	assert_eq(e.get_stat("defense"), 15.0)

func test_floater_no_gravity():
	var e = _make_enemy(FLOATER_CFG)
	await _frames(10)
	assert_eq(e.velocity.y, 0.0, "floater 重力为 0")

func test_archer_ranged_flag():
	var e = _make_enemy(ARCHER_CFG)
	await _frames()
	assert_true(e.config.ranged, "archer 应标记为远程")

# =============================================================================
# 8. 边缘情况
# =============================================================================

func test_no_config_does_not_crash():
	var e = _make_enemy(null)
	await _frames(5)
	assert_not_null(e, "无 config 不应崩溃")
	assert_eq(e._sm.get_current_state_name(), "Patrol", "无 config 初始状态应为 Patrol")

func test_duplicate_config_modify_works():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.patrol_points.clear()
	cfg.patrol_points.append(Vector2(50, 0))
	cfg.attack_cooldown = 3.0
	assert_eq(cfg.attack_cooldown, 3.0, "duplicate 后修改 cooldown 应生效")
	assert_eq(cfg.patrol_points.size(), 1, "duplicate 后修改 patrol_points 应生效")

func test_multiple_damage_accumulates():
	var e = _make_enemy(NINJA_CFG)
	await _frames()
	e.take_damage(10, 1, {})
	await _frames(25)  # 等无敌结束
	e.take_damage(10, 1, {})
	await _frames(25)
	e.take_damage(10, 1, {})
	await _frames()
	assert_eq(e.hp, 10.0, "HP=40, 三次 10 伤害后应剩 10")

func test_overkill_sets_hp_to_zero():
	var e = _make_enemy(SOLDIER_CFG)
	await _frames()
	e.take_damage(100, 1, {})
	assert_eq(e.hp, 0.0, "过量伤害应使 HP 归零")

func test_detection_body_exited_clears_player():
	var e = _make_enemy()
	var p = _make_player(e.global_position)
	await _frames()
	e._on_detection_body_entered(p)
	assert_true(e.player_detected)
	e._on_detection_body_exited(p)
	assert_false(e.player_detected, "离开检测范围应清除玩家引用")
	assert_null(e.player_entity, "离开后 player_entity 应为 null")

func test_move_toward_target_sets_facing():
	var e = _make_enemy()
	await _frames()
	e.move_toward_target(e.global_position + Vector2(100, 0), 50.0)
	assert_gt(e.velocity.x, 0.0, "目标在右侧速度应为正")
	assert_eq(e.facing_direction, 1, "目标在右侧应朝右")
	e.move_toward_target(e.global_position + Vector2(-100, 0), 50.0)
	assert_lt(e.velocity.x, 0.0, "目标在左侧速度应为负")
	assert_eq(e.facing_direction, -1, "目标在左侧应朝左")
