class_name BossPhaseManager
extends Node

signal phase_changed(old_phase: int, new_phase: int)

@export var phases: Array[BossPhaseConfig] = []

var current_phase: int = -1
var boss: Node = null

func initialize(boss_node: Node):
	boss = boss_node
	EventBus.entity_health_changed.connect(_on_health_changed.bind(boss_node.entity_id))
	enter_phase(0)

func enter_phase(phase_index: int):
	if phase_index >= phases.size():
		return
	if phase_index == current_phase:
		return
	var old_phase = current_phase
	current_phase = phase_index
	var config = phases[phase_index]

	# 写入黑板
	if boss and boss.has_method("set_blackboard"):
		boss.set_blackboard("boss_current_phase", phase_index)
		boss.set_blackboard("boss_phase_config", config)
		boss.set_blackboard("boss_weakness", config.weakness_element)

	EventBus.boss_phase_changed.emit(boss.entity_id, phase_index)
	phase_changed.emit(old_phase, phase_index)

	# 播放阶段过渡过场
	if config.transition_cutscene:
		CutsceneManager.play(config.transition_cutscene)

	# 更新攻击模式
	if boss and boss.has_method("set_attack_patterns"):
		boss.set_attack_patterns(config.new_attack_patterns)

	# 更新移速
	if boss and boss.has_method("set_speed_multiplier"):
		boss.set_speed_multiplier(config.move_speed_multiplier)

	# 更新攻击速率
	if boss and boss.has_method("set_attack_rate_multiplier"):
		boss.set_attack_rate_multiplier(config.attack_rate_multiplier)

func _on_health_changed(entity_id: int, _old_hp: float, new_hp: float, _boss_id: int):
	if entity_id != boss.entity_id:
		return
	if not boss or not is_instance_valid(boss):
		return
	var max_hp = boss.get_stat("max_hp", 1.0)
	var ratio = new_hp / max_hp if max_hp > 0 else 0.0

	for i in range(phases.size()):
		if i > current_phase and ratio <= phases[i].health_threshold:
			enter_phase(i)
			break

func get_current_config() -> BossPhaseConfig:
	if current_phase >= 0 and current_phase < phases.size():
		return phases[current_phase]
	return null
