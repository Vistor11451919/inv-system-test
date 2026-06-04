class_name StateMachine
extends Node

@export var initial_state_name: String = ""

var current_state: State = null
var states: Dictionary = {}
var previous_state: String = ""

# 调试状态历史 (第15章)
var debug_state_history: Array[Dictionary] = []
var last_transition_reason: String = ""
var transition_rejected_reason: String = ""

const _DEBUG_HISTORY_MAX: int = 120

func _ready():
	_collect_states(self)
	if initial_state_name and not current_state and states.has(initial_state_name):
		init(initial_state_name)

# 递归收集所有子 State（支持层级状态机组）
func _collect_states(node: Node):
	for child in node.get_children():
		if child is State:
			child.setup(self, owner)
			states[child.name] = child
		_collect_states(child)

func init(first_state: String):
	if current_state:
		current_state.exit()
	current_state = states.get(first_state)
	if current_state:
		current_state.enter("")

# 转换仲裁钩子 — 子类可重写此方法实现特定优先级逻辑
# 返回 true 表示允许转换，false 表示拒绝
func _can_transition(state_name: String, _params: Dictionary) -> bool:
	return true

func transition_to(state_name: String, params: Dictionary = {}) -> bool:
	var from = current_state.name if current_state else "null"

	if not states.has(state_name):
		transition_rejected_reason = "状态不存在: " + state_name
		return false
	if from == state_name:
		return true

	if not _can_transition(state_name, params):
		transition_rejected_reason = "仲裁拒绝: %s → %s" % [from, state_name]
		_push_debug_entry(state_name)
		return false

	if current_state:
		current_state.exit()
	previous_state = from
	current_state = states[state_name]
	last_transition_reason = transition_rejected_reason
	transition_rejected_reason = ""
	current_state.enter(previous_state, params)
	_push_debug_entry(state_name)
	return true

func get_state(state_name: String) -> State:
	return states.get(state_name)

func _push_debug_entry(state_name: String):
	debug_state_history.append({
		"frame": Engine.get_process_frames(),
		"current_state": current_state.name if current_state else "null",
		"target_state": state_name,
		"last_reason": last_transition_reason,
		"rejected_reason": transition_rejected_reason,
	})
	if debug_state_history.size() > _DEBUG_HISTORY_MAX:
		debug_state_history.pop_front()

func _physics_process(delta: float):
	if current_state:
		current_state.physics_update(delta)
		var actor = owner
		if actor is CharacterBody2D:
			actor.move_and_slide()

func _input(event: InputEvent):
	if current_state:
		current_state.input_update(event)

# 调试接口
func dump_history() -> Array[Dictionary]:
	return debug_state_history.duplicate()

func get_current_state_name() -> String:
	return current_state.name if current_state else "null"

# 列出所有已注册的状态名（测试辅助）
func get_all_state_names() -> Array:
	return states.keys()
