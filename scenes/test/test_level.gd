extends Node2D

## 敌人 AI 测试关卡

const BOSS_MON = preload("res://scenes/test/boss_monitor.gd")

func _ready():
	AbilityRegistry.unlock_all()
	DataManager.set_attr("chakra", DataManager.get_attr("max_chakra", 50.0))

	var shuriken = load("res://data/ninja_arts/shuriken.tres")
	if shuriken:
		DataManager.equip_ninja_art(shuriken, 0)
	var heal = load("res://data/ninja_arts/heal.tres")
	if heal:
		DataManager.equip_ninja_art(heal, 1)

	await get_tree().process_frame
	_start_boss_monitor()

func _start_boss_monitor():
	var target = null
	for child in get_children():
		if child is BossBase:
			target = child
			break
	if target:
		# 确保 phase_manager 引用
		var pm: BossPhaseManager = target.phase_manager
		if not pm:
			pm = target.get_node("AI/PhaseManager") as BossPhaseManager
			target.phase_manager = pm
		# 先加载阶段配置，再初始化（initialize 会调用 enter_phase(0)）
		pm.phases = [
			load("res://data/enemies/boss_phase_calm.tres"),
			load("res://data/enemies/boss_phase_angry.tres"),
			load("res://data/enemies/boss_phase_frenzy.tres"),
		]
		pm.initialize(target)
		var mon = BOSS_MON.new()
		add_child(mon)
		mon.watch(target)
		print("  [Boss监视器] 观察: %s" % target.boss_name)
	else:
		print("  [Boss监视器] 未找到 Boss")
