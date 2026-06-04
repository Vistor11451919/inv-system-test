class_name TimelineExecutor
extends RefCounted

var _timeline: NinjaArtTimeline = null
var _context: Dictionary = {}
var _current_step: int = -1
var _is_running: bool = false
var _cancelled: bool = false
var _tree: SceneTree = null

var on_finished: Callable = Callable()
var on_step: Callable = Callable()

func start(timeline: NinjaArtTimeline, context: Dictionary):
	if _is_running:
		return
	_is_running = true
	_cancelled = false
	_timeline = timeline
	_context = context
	_current_step = -1
	_tree = Engine.get_main_loop() as SceneTree
	_next_step()

func cancel():
	_cancelled = true
	_is_running = false

func is_running() -> bool:
	return _is_running

func _get_step(idx: int) -> SkillStep:
	var raw = _timeline.steps[idx]
	if raw is SkillStep:
		return raw
	if raw is Dictionary:
		var s = SkillStep.new()
		s.effect_id = raw.get("effect_id", "")
		s.delay = raw.get("delay", 0.0)
		s.params = raw.get("params", {})
		s.description = raw.get("description", "")
		s.vfx_scene = raw.get("vfx_scene", "")
		s.sound_id = raw.get("sound_id", "")
		return s
	return SkillStep.new()

func _next_step():
	if _cancelled:
		return
	_current_step += 1
	if _current_step >= _timeline.steps.size():
		_finish()
		return
	var step = _get_step(_current_step)
	if step.delay > 0:
		if _tree:
			_tree.create_timer(step.delay).timeout.connect(_execute_current)
			return
	# 同步执行下一个步骤（delay=0 时），避免 timer 开销
	_execute_current()

func _execute_current():
	if _cancelled or _current_step >= _timeline.steps.size():
		return
	var step = _get_step(_current_step)
	AtomicEffectRegistry.execute(step.effect_id, _context, step.params)
	if on_step.is_valid():
		on_step.call(_current_step, step.effect_id)
	_next_step()

func _finish():
	_is_running = false
	if not _cancelled and on_finished.is_valid() and _timeline:
		on_finished.call(_timeline.timeline_id)
