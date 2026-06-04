extends GutTest

## Boss 阶段管理单元测试
## 覆盖: 阶段初始化 / 血量阈值转换 / 阶段配置应用 / 弱点元素 / 防重复 / 边界条件

const BOSS_SCENE = preload("res://scenes/enemies/boss_template.tscn")
const SOLDIER_CFG = preload("res://data/enemies/soldier.tres")
const MOCK_ENTITY = preload("res://test/fixtures/mock_entity.gd")

# 注意: EnemyBase._ready() 从 config 覆盖 max_hp
# SOLDIER_CFG.max_hp = 60, 所有阈值计算基于 max_hp=60
const BOSS_MAX_HP = 60.0

func _frames(n: int = 1):
	for _i in range(n):
		await get_tree().physics_frame

func _make_phase(name: String, threshold: float, weakness: String = "",
	patterns: Array[String] = [], speed_mult: float = 1.0, atk_rate_mult: float = 1.0) -> BossPhaseConfig:
	var cfg = BossPhaseConfig.new()
	cfg.phase_name = name
	cfg.health_threshold = threshold
	cfg.weakness_element = weakness
	cfg.new_attack_patterns = patterns.duplicate()
	cfg.move_speed_multiplier = speed_mult
	cfg.attack_rate_multiplier = atk_rate_mult
	return cfg

func _make_boss(phases: Array[BossPhaseConfig], custom_cfg: EnemyConfig = SOLDIER_CFG):
	var boss = BOSS_SCENE.instantiate()
	boss.config = custom_cfg
	boss.phase_manager = boss.get_node("AI/PhaseManager")
	boss.phase_manager.phases = phases
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	boss.add_child(hp_label)
	add_child_autofree(boss)
	await _frames()
	return { boss = boss, pm = boss.phase_manager }

var _test_boss_cfg_no_invuln = null
func _get_no_invuln_cfg() -> EnemyConfig:
	if not _test_boss_cfg_no_invuln:
		_test_boss_cfg_no_invuln = SOLDIER_CFG.duplicate()
		_test_boss_cfg_no_invuln.invulnerability_time = 0.0
	return _test_boss_cfg_no_invuln

func _reset_autoload_counters():
	CameraManager.lock_boss_zone_call_count = 0
	CameraManager.unlock_boss_zone_call_count = 0
	MapManager.unlock_region_call_count = 0
	MapManager.last_unlocked_region = ""
	GameManager.record_boss_defeated_call_count = 0
	GameManager.last_recorded_boss = ""
	CutsceneManager.play_call_count = 0
	CutsceneManager.last_played_resource = null

# =============================================================================
# 1. 阶段初始化
# =============================================================================

func test_phase_manager_initializes_first_phase():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("Phase1", 1.0),
		_make_phase("Phase2", 0.5),
	]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.pm.current_phase, 0)

func test_phase_enters_zero_on_init():
	var phases: Array[BossPhaseConfig] = [_make_phase("First", 1.0)]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.pm.current_phase, 0)
	assert_eq(ctx.boss.get_blackboard("boss_current_phase"), 0)

func test_phase_init_with_single_phase():
	var phases: Array[BossPhaseConfig] = [_make_phase("Only", 1.0)]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.pm.current_phase, 0)

func test_phase_init_applies_attack_patterns():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0, "", ["slash", "thrust"]),
	]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.boss._current_attack_patterns, ["slash", "thrust"])

# =============================================================================
# 2. 血量阈值转换
# =============================================================================

func test_phase_transitions_on_health_threshold():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 20.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)

func test_phase_transition_on_exact_threshold():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 30.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)

func test_no_transition_above_threshold():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.3),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 30.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 0)

func test_multiple_phase_progression():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.6),
		_make_phase("P3", 0.3),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 30.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, 30.0, 10.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 2)

func test_skipped_threshold_queue():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.6),
		_make_phase("P3", 0.3),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 5.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, 30.0, 5.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 2)

# =============================================================================
# 3. 阶段配置应用
# =============================================================================

func test_phase_speed_multiplier_applied():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5, "", [], 2.0),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 20.0)
	await _frames()
	assert_eq(ctx.boss._speed_multiplier, 2.0)

func test_phase_attack_rate_multiplier_applied():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5, "", [], 1.0, 1.5),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 20.0)
	await _frames()
	assert_eq(ctx.boss._attack_rate_multiplier, 1.5)

func test_phase_new_attack_patterns_applied():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5, "", ["enrage"]),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 20.0)
	await _frames()
	assert_eq(ctx.boss._current_attack_patterns, ["enrage"])

# =============================================================================
# 4. 弱点元素
# =============================================================================

func test_weakness_element_stored_in_blackboard():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0, "fire"),
	]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.boss.get_blackboard("boss_weakness"), "fire")

func test_weakness_element_bonus_damage():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0, "fire"),
	]
	var ctx = await _make_boss(phases)
	var caster_id = ctx.boss.entity_id
	ctx.boss.take_damage(10, caster_id, {"element": "ice"})
	await _frames(25)
	var hp_ice = ctx.boss.hp
	var ice_damage = BOSS_MAX_HP - hp_ice
	ctx.boss.take_damage(10, caster_id, {"element": "fire"})
	await _frames()
	var hp_fire = ctx.boss.hp
	var fire_damage = hp_ice - hp_fire
	assert_gt(fire_damage, ice_damage)

func test_weakness_no_bonus_when_phase_has_no_weakness():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
	]
	var ctx = await _make_boss(phases)
	var caster_id = ctx.boss.entity_id
	ctx.boss.take_damage(10, caster_id, {"element": "fire"})
	await _frames()
	assert_eq(ctx.boss.hp, 50.0)

# =============================================================================
# 5. 防重复与边界
# =============================================================================

func test_same_phase_no_reentry():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 20.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, 20.0, 10.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)

func test_phase_out_of_bounds_safe():
	var phases: Array[BossPhaseConfig] = [_make_phase("P1", 1.0)]
	var ctx = await _make_boss(phases)
	ctx.pm.enter_phase(5)
	assert_eq(ctx.pm.current_phase, 0)

func test_phase_manager_emits_signal():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	watch_signals(ctx.pm)
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 20.0)
	await _frames()
	assert_signal_emitted(ctx.pm, "phase_changed")

func test_get_current_config():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	var cfg = ctx.pm.get_current_config()
	assert_not_null(cfg)
	if cfg:
		assert_eq(cfg.phase_name, "P1")
	EventBus.entity_health_changed.emit(ctx.boss.entity_id, BOSS_MAX_HP, 20.0)
	await _frames()
	cfg = ctx.pm.get_current_config()
	if cfg:
		assert_eq(cfg.phase_name, "P2")

func test_no_phases_does_not_crash():
	var boss = BOSS_SCENE.instantiate()
	boss.config = SOLDIER_CFG
	var pm: BossPhaseManager = boss.get_node("AI/PhaseManager")
	pm.phases.clear()
	boss.phase_manager = pm
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	boss.add_child(hp_label)
	add_child_autofree(boss)
	await _frames()
	assert_eq(pm.current_phase, -1)

func test_boss_without_phases_still_works():
	var boss = BOSS_SCENE.instantiate()
	boss.config = SOLDIER_CFG
	var pm: BossPhaseManager = boss.get_node("AI/PhaseManager")
	boss.phase_manager = pm
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	boss.add_child(hp_label)
	add_child_autofree(boss)
	await _frames()
	assert_eq(pm.phases.size(), 0)
	assert_eq(pm.current_phase, -1)

# =============================================================================
# 6. Boss 死亡流程测试
# =============================================================================

func test_boss_die_called_on_hp_zero():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.death_delay = 0.0
	var boss: BossBase = BOSS_SCENE.instantiate()
	boss.config = cfg
	boss.reward_on_defeat = ["reward_test_1", "reward_test_2"]
	var pm: BossPhaseManager = boss.get_node("AI/PhaseManager")
	boss.phase_manager = pm
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	boss.add_child(hp_label)
	add_child_autofree(boss)
	await _frames()
	assert_eq(boss.hp, 60.0)
	watch_signals(EventBus)
	var eid = boss.entity_id
	boss.take_damage(999, boss.entity_id, {})
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_null(WorldManager.get_entity(eid))
	assert_signal_emit_count(EventBus, "item_collected", 2)

func test_boss_die_no_reentry():
	var cfg = SOLDIER_CFG.duplicate()
	cfg.death_delay = 0.0
	var boss: BossBase = BOSS_SCENE.instantiate()
	boss.config = cfg
	boss.reward_on_defeat = ["single_reward"]
	var pm: BossPhaseManager = boss.get_node("AI/PhaseManager")
	boss.phase_manager = pm
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	boss.add_child(hp_label)
	add_child_autofree(boss)
	await _frames()
	watch_signals(EventBus)
	var eid = boss.entity_id
	boss.take_damage(999, boss.entity_id, {})
	boss.take_damage(10, boss.entity_id, {})
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_signal_emit_count(EventBus, "item_collected", 1)
	assert_null(WorldManager.get_entity(eid))

# =============================================================================
# 7. PhaseManager 实体过滤
# =============================================================================

func test_phase_manager_ignores_other_entity_damage():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.pm.current_phase, 0)
	var mock = MOCK_ENTITY.new()
	mock.entity_id = WorldManager.register_entity(mock)
	add_child_autofree(mock)
	mock.set_stat("hp", 100.0)
	mock.set_stat("max_hp", 100.0)
	EventBus.entity_health_changed.emit(mock.entity_id, 100.0, 20.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 0)

func test_phase_manager_ignores_wrong_entity_emit():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.pm.current_phase, 0)
	EventBus.entity_health_changed.emit(99999, BOSS_MAX_HP, 10.0)
	await _frames()
	assert_eq(ctx.pm.current_phase, 0)

# =============================================================================
# 8. 真实伤害触发测试
# =============================================================================

func test_phase_change_via_damage_flow():
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0),
		_make_phase("P2", 0.5),
	]
	var ctx = await _make_boss(phases)
	assert_eq(ctx.pm.current_phase, 0)
	ctx.boss.take_damage(31, ctx.boss.entity_id, {})
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)

# =============================================================================
# 9. 竞技场锁
# =============================================================================

func test_arena_lock_triggers_on_player_detection():
	_reset_autoload_counters()
	var phases: Array[BossPhaseConfig] = [_make_phase("P1", 1.0)]
	var ctx = await _make_boss(phases)
	var boss = ctx.boss as BossBase
	assert_false(boss._arena_locked)
	var player = Node2D.new()
	player.add_to_group("player")
	add_child_autofree(player)
	boss._detection.body_entered.emit(player)
	await _frames()
	assert_true(boss._arena_locked)

func test_arena_lock_idempotent():
	_reset_autoload_counters()
	var phases: Array[BossPhaseConfig] = [_make_phase("P1", 1.0)]
	var ctx = await _make_boss(phases)
	var boss = ctx.boss as BossBase
	var player = Node2D.new()
	player.add_to_group("player")
	add_child_autofree(player)
	boss._detection.body_entered.emit(player)
	await _frames()
	assert_true(boss._arena_locked)
	boss._detection.body_entered.emit(player)
	await _frames()
	assert_true(boss._arena_locked)

# =============================================================================
# 10. Boss 击败进度门
# =============================================================================

func test_boss_death_triggers_progression():
	_reset_autoload_counters()
	var cfg = _get_no_invuln_cfg()
	cfg.death_delay = 0.0
	var boss: BossBase = BOSS_SCENE.instantiate()
	boss.config = cfg
	boss.boss_name = "TestKing"
	boss.unlock_region_on_defeat = "zone_boss_2"
	var pm: BossPhaseManager = boss.get_node("AI/PhaseManager")
	boss.phase_manager = pm
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	boss.add_child(hp_label)
	add_child_autofree(boss)
	await _frames()
	boss.take_damage(999, boss.entity_id, {})
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(GameManager.record_boss_defeated_call_count, 1)
	assert_eq(GameManager.last_recorded_boss, "TestKing")
	assert_eq(CameraManager.unlock_boss_zone_call_count, 1)
	assert_eq(MapManager.unlock_region_call_count, 1)
	assert_eq(MapManager.last_unlocked_region, "zone_boss_2")

func test_boss_death_empty_region_skipped():
	_reset_autoload_counters()
	var cfg = _get_no_invuln_cfg()
	cfg.death_delay = 0.0
	var boss: BossBase = BOSS_SCENE.instantiate()
	boss.config = cfg
	boss.boss_name = "NoUnlock"
	var pm: BossPhaseManager = boss.get_node("AI/PhaseManager")
	boss.phase_manager = pm
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	boss.add_child(hp_label)
	add_child_autofree(boss)
	await _frames()
	boss.take_damage(999, boss.entity_id, {})
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(GameManager.record_boss_defeated_call_count, 1)
	assert_eq(MapManager.unlock_region_call_count, 0)

# =============================================================================
# 11. 多阶段完整战斗
# =============================================================================

func test_full_multi_phase_fight():
	_reset_autoload_counters()
	var cfg = _get_no_invuln_cfg()
	cfg.death_delay = 0.0
	var phases: Array[BossPhaseConfig] = [
		_make_phase("Calm", 1.0, "", ["basic"], 1.0, 1.0),
		_make_phase("Angry", 0.6, "fire", ["enrage"], 1.5, 1.2),
		_make_phase("Frenzy", 0.3, "fire", ["berserk"], 2.0, 1.5),
	]
	var ctx = await _make_boss(phases, cfg)
	assert_eq(ctx.pm.current_phase, 0)
	assert_eq(ctx.boss._current_attack_patterns, ["basic"])
	assert_eq(ctx.boss._speed_multiplier, 1.0)
	ctx.boss.take_damage(30, ctx.boss.entity_id, {})
	assert_eq(ctx.pm.current_phase, 1)
	assert_eq(ctx.boss._current_attack_patterns, ["enrage"])
	assert_eq(ctx.boss._speed_multiplier, 1.5)
	assert_eq(ctx.boss._attack_rate_multiplier, 1.2)
	await get_tree().process_frame; await get_tree().process_frame
	ctx.boss.take_damage(15, ctx.boss.entity_id, {})
	assert_eq(ctx.pm.current_phase, 2)
	assert_eq(ctx.boss._current_attack_patterns, ["berserk"])
	assert_eq(ctx.boss._speed_multiplier, 2.0)
	await get_tree().process_frame; await get_tree().process_frame
	ctx.boss.take_damage(999, ctx.boss.entity_id, {})
	await get_tree().process_frame; await get_tree().process_frame
	assert_eq(GameManager.record_boss_defeated_call_count, 1)

# =============================================================================
# 12. 弱点跨阶段变化
# =============================================================================

func test_weakness_element_changes_across_phases():
	_reset_autoload_counters()
	var cfg = _get_no_invuln_cfg()
	var phases: Array[BossPhaseConfig] = [
		_make_phase("P1", 1.0, ""),
		_make_phase("P2", 0.5, "fire"),
	]
	var ctx = await _make_boss(phases, cfg)
	var eid = ctx.boss.entity_id
	ctx.boss.take_damage(10, eid, {"element": "fire"})
	await _frames()
	assert_eq(ctx.boss.hp, 50.0)
	assert_eq(ctx.pm.current_phase, 0)
	ctx.boss.take_damage(21, eid, {"element": "fire"})
	await _frames()
	assert_eq(ctx.pm.current_phase, 1)
	var hp_before = ctx.boss.hp
	ctx.boss.take_damage(10, eid, {"element": "fire"})
	await _frames()
	var fire_damage = hp_before - ctx.boss.hp
	assert_eq(fire_damage, 15.0)
