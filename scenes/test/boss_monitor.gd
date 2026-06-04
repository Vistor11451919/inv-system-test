extends Node

## Boss 监视器 — 观察 Boss 状态转换 + 伤害结算 + 阶段切换
## 使用: boss_monitor.watch(boss_node)

var _target: Node = null
var _last_state: String = ""
var _last_hp: float = -1.0
var _last_phase: int = -1

func watch(boss: Node):
	_target = boss
	_last_state = _get_state()
	_last_hp = boss.hp
	_last_phase = boss.phase_manager.current_phase if boss.phase_manager else -1
	_print_header()

	if EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.disconnect(_on_damage_dealt)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	if EventBus.entity_health_changed.is_connected(_on_health_changed):
		EventBus.entity_health_changed.disconnect(_on_health_changed)
	EventBus.entity_health_changed.connect(_on_health_changed)
	if EventBus.boss_phase_changed.is_connected(_on_phase_changed):
		EventBus.boss_phase_changed.disconnect(_on_phase_changed)
	EventBus.boss_phase_changed.connect(_on_phase_changed)

func _get_state() -> String:
	if _target and _target._sm:
		return _target._sm.get_current_state_name()
	return "?"

func _print_header():
	var cfg = _target.config
	print("═══════════════════════════════════════════")
	print("  Boss: %s (entity_id=%d)" % [cfg.display_name if cfg else "?", _target.entity_id])
	print("  HP: %.0f/%.0f  ATK: %.0f  DEF: %.0f" % [_target.hp, _target.max_hp,
		cfg.attack if cfg else 0, cfg.defense if cfg else 0])
	print("  阶段: %d  无敌: %s" % [_last_phase, str(_target._invulnerable)])
	var phase_cfg = _target.phase_manager.get_current_config() if _target.phase_manager else null
	if phase_cfg:
		print("  阶段名: %s  弱点: %s" % [phase_cfg.phase_name, phase_cfg.weakness_element if phase_cfg.weakness_element else "无"])
	print("───────────────────────────────────────────")

func _process(_delta):
	if not _target or not is_instance_valid(_target):
		if _target:
			print("  ═══ Boss 已击败 ═══")
			_target = null
		return
	var cur = _get_state()
	if cur != _last_state:
		print("  [状态] %s -> %s" % [_last_state, cur])
		_last_state = cur
	var hp = _target.hp
	if hp != _last_hp:
		print("  [HP]   %.0f -> %.0f  (-%.0f)" % [_last_hp, hp, _last_hp - hp])
		_last_hp = hp

func _on_damage_dealt(caster_id: int, target_id: int, damage: float, data: Dictionary):
	if not _target or not is_instance_valid(_target):
		return
	if target_id != _target.entity_id:
		return
	var element = data.get("element", "physical")
	print("  [受击] -%.0f HP  element=%s  caster=%d" % [damage, element, caster_id])

func _on_health_changed(entity_id: int, old_hp: float, new_hp: float):
	if not _target or not is_instance_valid(_target):
		return
	if entity_id != _target.entity_id:
		return
	if new_hp <= 0:
		print("  ═══ 死亡 ═══")

func _on_phase_changed(boss_id: int, phase_index: int):
	if not _target or not is_instance_valid(_target):
		return
	if boss_id != _target.entity_id:
		return
	var phase_cfg = _target.phase_manager.get_current_config() if _target.phase_manager else null
	var pname = phase_cfg.phase_name if phase_cfg else "?"
	print("  [阶段] -> %s (index=%d)" % [pname, phase_index])
	_last_phase = phase_index
