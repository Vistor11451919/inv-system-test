extends Node

## 忍术监视器 v2 — 追踪忍术执行全流程，定位失败原因

var _player: Node = null
var _last_state: String = ""
var _art_info: Dictionary = {}
var _timer: float = 0.0

func watch(player: Node):
	_player = player
	_last_state = _get_player_state()
	print("═══════════════════════════════════════════")
	print("  忍术监视器 v2")
	_print_status()
	print("───────────────────────────────────────────")
	set_process(true)

	# 监听技能完成信号
	var exe = player.get_node_or_null("SkillExecutor")
	if exe:
		if not exe.skill_finished.is_connected(_on_skill_finished):
			exe.skill_finished.connect(_on_skill_finished)
		print("  [OK] SkillExecutor 已连接")
	else:
		print("  [✗] SkillExecutor 未找到!")

func _get_player_state() -> String:
	if not _player or not is_instance_valid(_player):
		return "?"
	var sm = _player.get_node_or_null("StateMachine")
	return sm.get_current_state_name() if sm else "?"

func _print_status():
	var chakra = DataManager.get_attr("chakra")
	var max_ch = DataManager.get_attr("max_chakra")
	var slot0 = DataManager.get_equipped_ninja_art(0)
	var slot1 = DataManager.get_equipped_ninja_art(1)

	print("  查克拉: %.0f/%.0f" % [chakra, max_ch])
	print("  装备: slot0=%s  slot1=%s" % [
		slot0.art_id if slot0 else "空",
		slot1.art_id if slot1 else "空"])

	# 检查 AtomicEffectRegistry
	if AtomicEffectRegistry.has_effect("spawn_projectile"):
		print("  [OK] AtomicEffect: spawn_projectile 已注册")
	else:
		print("  [✗] AtomicEffect: spawn_projectile 未注册!")

func _process(_delta):
	if not _player or not is_instance_valid(_player):
		return
	var cur = _get_player_state()

	if cur == "NinjaArt" and _last_state != "NinjaArt":
		_art_info = {}
		_on_enter()

	elif _last_state == "NinjaArt" and cur != "NinjaArt":
		_on_exit(cur)

	_last_state = cur

func _on_enter():
	var chakra = DataManager.get_attr("chakra")
	var slot0 = DataManager.get_equipped_ninja_art(0)
	var slot1 = DataManager.get_equipped_ninja_art(1)
	var art = slot0 if slot0 else slot1

	if not art:
		print("  ◆ 进入 NinjaArt 但 slot0/1 都为空!")
		return

	_art_info = {"id": art.art_id, "name": art.art_name, "cost": art.chakra_cost,
		"chakra_before": chakra}

	print("  ┌──────────────────────────────────────────")
	print("  │ 忍术: %s (id=%s)" % [art.art_name, art.art_id])
	print("  │ 查克拉: %.0f → 需要 %d → %s" % [chakra, art.chakra_cost,
		"足够" if chakra >= art.chakra_cost else "不足 ✗"])
	print("  │ 冷却: %.1fs  前摇: %.2fs" % [art.cooldown, art.cast_time])
	print("  │ Timeline: %s" % art.data_packet.get("timeline", "无"))

	# 检查 SkillExecutor 冷却状态
	var exe = _player.get_node_or_null("SkillExecutor")
	if exe:
		var on_cd = exe._is_on_cooldown(art.art_id) if exe.has_method("_is_on_cooldown") else false
		print("  │ 冷却状态: %s" % ("冷却中 ✗" if on_cd else "就绪 ✔"))
		# 检查 timeline 能否加载
		var tl_path = art.data_packet.get("timeline", "")
		if not tl_path.is_empty():
			var tl = load(tl_path)
			print("  │ Timeline 加载: %s" % ("成功 ✔" if tl else "失败 ✗"))
	else:
		print("  │ SkillExecutor: 未找到 ✗")
	print("  └──────────────────────────────────────────")

func _on_exit(target: String):
	var chakra = DataManager.get_attr("chakra")
	var before = _art_info.get("chakra_before", chakra)
	var cost = _art_info.get("cost", 0)
	var deducted = before - chakra

	print("  ← 退出 (→ %s)" % target)
	print("    查克拉: %.0f → %.0f (差: %+.0f, 消耗: %d)" % [before, chakra, chakra - before, cost])

	if deducted == 0 and cost > 0 and target == "Idle":
		print("    → 推测: 执行失败, 查克拉已退回")
	elif deducted == cost:
		print("    → 推测: 执行成功, 等待 skill_finished")
	elif deducted > 0 and deducted < cost:
		print("    → 推测: 部分扣除后异常退出")
	elif deducted > cost:
		print("    → 推测: 多扣了? 检查 refund 逻辑")

func _on_skill_finished(art_id: String):
	print("  ✔ 技能完成: %s  查克拉: %.0f" % [art_id, DataManager.get_attr("chakra")])
	_art_info = {}
