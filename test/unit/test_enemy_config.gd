extends GutTest

## EnemyConfig 资源测试 — 配置加载和默认值

func test_soldier_config_loads():
	var cfg = load("res://data/enemies/soldier.tres") as EnemyConfig
	assert_not_null(cfg, "soldier.tres 应可加载")
	if cfg:
		assert_eq(cfg.enemy_id, "soldier")
		assert_eq(cfg.max_hp, 60.0)
		assert_eq(cfg.attack, 8.0)
		assert_eq(cfg.defense, 5.0)


func test_ninja_config_loads():
	var cfg = load("res://data/enemies/ninja.tres") as EnemyConfig
	assert_not_null(cfg)
	if cfg:
		assert_eq(cfg.enemy_id, "ninja")
		assert_eq(cfg.chase_speed, 140.0)


func test_heavy_config_loads():
	var cfg = load("res://data/enemies/heavy.tres") as EnemyConfig
	assert_not_null(cfg)
	if cfg:
		assert_eq(cfg.enemy_id, "heavy")
		assert_eq(cfg.max_hp, 200.0)
		assert_false(cfg.ranged)


func test_archer_config_loads():
	var cfg = load("res://data/enemies/archer.tres") as EnemyConfig
	assert_not_null(cfg)
	if cfg:
		assert_eq(cfg.enemy_id, "archer")
		assert_true(cfg.ranged)


func test_floater_config_loads():
	var cfg = load("res://data/enemies/floater.tres") as EnemyConfig
	assert_not_null(cfg)
	if cfg:
		assert_eq(cfg.enemy_id, "floater")
		assert_eq(cfg.gravity, 0.0)
		assert_true(cfg.homing, "floater 子弹应追踪玩家")


func test_enemy_template_instantiates():
	var scene = load("res://scenes/enemies/templates/enemy_template.tscn")
	assert_not_null(scene)
	var enemy = scene.instantiate()
	add_child_autofree(enemy)
	await get_tree().process_frame
	assert_not_null(enemy)
	assert_is(enemy, load("res://scripts/enemy_base.gd"), "应继承 EnemyBase")

func test_boss_config_loads():
	var cfg = load("res://data/enemies/test_boss.tres") as EnemyConfig
	assert_not_null(cfg, "test_boss.tres 应可加载")
	if cfg:
		assert_eq(cfg.enemy_id, "test_boss")
		assert_eq(cfg.max_hp, 200.0, "Boss HP 应为 200")
		assert_eq(cfg.attack, 15.0, "Boss ATK 应为 15")
		assert_false(cfg.ranged, "Boss 基础为近战，远程通过阶段攻击模式控制")

func test_boss_phase_configs_load():
	var calm = load("res://data/enemies/boss_phase_calm.tres") as BossPhaseConfig
	assert_not_null(calm)
	if calm:
		assert_eq(calm.phase_name, "Calm")
		assert_eq(calm.health_threshold, 1.0)

	var angry = load("res://data/enemies/boss_phase_angry.tres") as BossPhaseConfig
	assert_not_null(angry)
	if angry:
		assert_eq(angry.phase_name, "Angry")
		assert_eq(angry.health_threshold, 0.7)
		assert_eq(angry.weakness_element, "fire")

	var frenzy = load("res://data/enemies/boss_phase_frenzy.tres") as BossPhaseConfig
	assert_not_null(frenzy)
	if frenzy:
		assert_eq(frenzy.phase_name, "Frenzy")
		assert_eq(frenzy.health_threshold, 0.3)
		assert_eq(frenzy.move_speed_multiplier, 1.6)
