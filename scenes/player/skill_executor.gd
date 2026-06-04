class_name SkillExecutor
extends Node

signal skill_finished(art_id: String)

var _current_executor: TimelineExecutor = null
var _cooldowns: Dictionary = {}

func execute_skill(art: NinjaArt, caster_id: int = 0, caster_node: Node = null) -> bool:
	if not art:
		return false
	if _is_on_cooldown(art.art_id):
		var remaining = _cooldowns[art.art_id] - Time.get_ticks_msec() / 1000.0
		return false

	var timeline = _resolve_timeline(art)
	if not timeline:
		push_error("SkillExecutor: 无法为 %s 创建 timeline" % art.art_id)
		return false

	var result = execute_timeline(timeline, art.art_id, caster_id, caster_node)
	if result:
		_start_cooldown(art.art_id, art.cooldown)
	return result

func _resolve_timeline(art: NinjaArt) -> NinjaArtTimeline:
	var timeline_path = art.data_packet.get("timeline", "")
	if not timeline_path.is_empty():
		var tl = load(timeline_path) as NinjaArtTimeline
		if tl:
			return tl

	# 自动构建默认 timeline（单步：spawn_projectile）
	var step = SkillStep.new()
	step.effect_id = "spawn_projectile"
	step.delay = 0.0
	step.params = {
		"scene": art.data_packet.get("projectile_scene", "res://scenes/common/projectile.tscn"),
		"speed": art.data_packet.get("projectile_speed", 400.0),
		"damage": art.data_packet.get("damage", 10.0),
	}

	var timeline = NinjaArtTimeline.new()
	timeline.timeline_id = art.art_id + "_default"
	timeline.steps.clear()
	timeline.steps.append(step)
	return timeline

func execute_timeline(timeline: NinjaArtTimeline, art_id: String, caster_id: int = 0, caster_node: Node = null) -> bool:
	if not timeline:
		return false

	_current_executor = TimelineExecutor.new()
	var context = {
		"caster_id": caster_id,
		"self_position": caster_node.global_position if caster_node else Vector2.ZERO,
		"origin_direction": Vector2.RIGHT,
	}
	if caster_node:
		context["caster_node"] = caster_node
		if caster_node.get("facing_direction"):
			context["origin_direction"] = Vector2(caster_node.facing_direction, 0)

	_current_executor.on_finished = func(_timeline_id: String):
		_current_executor = null
		skill_finished.emit(art_id)

	_current_executor.on_step = func(step_index: int, _effect_id: String):
		if caster_node and is_instance_valid(caster_node):
			context["self_position"] = caster_node.global_position
			if caster_node.get("facing_direction"):
				context["origin_direction"] = Vector2(caster_node.facing_direction, 0)

	_current_executor.start(timeline, context)
	return true

func cancel_current():
	if _current_executor and _current_executor.is_running():
		_current_executor.cancel()
		_current_executor = null

func _is_on_cooldown(art_id: String) -> bool:
	if not _cooldowns.has(art_id):
		return false
	var remaining = _cooldowns[art_id] - Time.get_ticks_msec() / 1000.0
	if remaining <= 0:
		_cooldowns.erase(art_id)
		return false
	return true

func _start_cooldown(art_id: String, cooldown: float):
	_cooldowns[art_id] = Time.get_ticks_msec() / 1000.0 + cooldown
