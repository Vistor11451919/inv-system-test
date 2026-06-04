class_name VisualController
extends Node

# 一次性标记桶（3=最高优先级, 1=最低）
var _priority_buckets: Dictionary = {3: [], 2: [], 1: []}
# 状态类标记（持续存在，直到状态退出时清除）
var _state_marks: Dictionary = {}
# 动画冲突队列
var _anim_queue: Array[Dictionary] = []
# 当前动画名称
var _current_anim: String = ""
# 可中断动画集合 — 这些动画可以被新动画立即打断
var _interruptible_anims: Array[String] = ["idle", "run", "fall"]

func add_mark(mark: String, priority: int = 2, data: Dictionary = {}):
	assert(priority in [1, 2, 3])
	_priority_buckets[priority].append({"mark": mark, "data": data})

# --- 状态类标记接口（第9.1节） ---
func set_state_mark(key: String, value: Variant = true):
	_state_marks[key] = value

func get_state_mark(key: String, default_value = null):
	return _state_marks.get(key, default_value)

func clear_state_mark(key: String):
	_state_marks.erase(key)

func clear_all_state_marks():
	_state_marks.clear()

# --- 动画冲突处理（第9.3节） ---
func set_interruptible_anims(anims: Array[String]):
	_interruptible_anims = anims

func add_interruptible_anim(anim_name: String):
	if anim_name not in _interruptible_anims:
		_interruptible_anims.append(anim_name)

func play_animation(anim_name: String):
	var anim_player = _find_animation_player()
	if not anim_player:
		return

	# 检查动画冲突
	if _current_anim and anim_player.is_playing():
		if _current_anim in _interruptible_anims:
			# 可中断：立即切换
			anim_player.stop()
		else:
			# 不可中断：排入队列
			_update_queue(anim_name)
			return

	_current_anim = anim_name
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	else:
		_current_anim = ""

func _update_queue(anim_name: String):
	# 去重：同名标记只保留最新的
	for i in range(_anim_queue.size() - 1, -1, -1):
		if _anim_queue[i].get("name") == anim_name:
			_anim_queue.remove_at(i)
	_anim_queue.append({"name": anim_name})

func _process_anim_queue():
	if _anim_queue.is_empty():
		return
	var next = _anim_queue.pop_front()
	var anim_player = _find_animation_player()
	if anim_player and anim_player.has_animation(next.get("name", "")):
		_current_anim = next["name"]
		anim_player.play(next["name"])
	else:
		_current_anim = ""

# --- 每帧标记消费（第9.2节：动画 > 特效 > 音效） ---
func _process(_delta):
	# 检查是否需要播放下一个排队动画（当前动画播放完毕）
	if _anim_queue:
		var anim_player = _find_animation_player()
		if anim_player and not anim_player.is_playing():
			_process_anim_queue()

	# 消费一次性标记 — 每个优先级每帧消费一个
	for priority in [3, 2, 1]:
		if not _priority_buckets[priority].is_empty():
			var mark_data = _priority_buckets[priority].pop_front()
			_consume_mark(mark_data.mark, mark_data.data)

func _consume_mark(mark: String, data: Dictionary):
	match mark:
		"anim":
			play_animation(data.get("name", ""))
		"effect":
			_play_effect(data)
		"sound":
			_play_sound(data)
		"facing":
			if _actor_has_method("set_facing"):
				_actor_call("set_facing", data.get("direction", 1))
		"flash":
			_do_flash(data)
		"sprite_color":
			_set_sprite_color(data)
		"hp_display":
			_update_hp_label(data)
		_:
			push_warning("Unknown visual mark: ", mark)

func _play_effect(data: Dictionary):
	var effect_name = data.get("name", "")
	var position = data.get("position", null)
	# 预留：通过 ObjectPool 生成特效
	pass

func _play_sound(data: Dictionary):
	var sound_id = data.get("sound_id", "")
	# 预留：通过 AudioManager 播放音效
	pass

func _do_flash(data: Dictionary):
	var sprite = _find_sprite()
	if not sprite:
		return
	var color = data.get("color", Color(2, 0.5, 0.5))
	var duration = data.get("duration", 0.1)
	sprite.modulate = color
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE

func _set_sprite_color(data: Dictionary):
	var sprite = _find_sprite()
	if not sprite:
		return
	sprite.modulate = data.get("color", Color.WHITE)

func _update_hp_label(data: Dictionary):
	var label = _find_hp_label()
	if not label:
		return
	label.text = data.get("text", "")

# --- 查找组件 ---
func _find_animation_player():
	for child in get_parent().get_children():
		if child is AnimationPlayer:
			return child
		if child is AnimationTree:
			return child
	return null

func _find_sprite():
	for child in get_parent().get_children():
		if child is Sprite2D:
			return child
	return null

func _find_hp_label():
	for child in get_parent().get_children():
		if child is Label:
			return child
	return null

func _actor_has_method(method_name: String) -> bool:
	return get_parent().has_method(method_name)

func _actor_call(method_name: String, val):
	get_parent().call(method_name, val)
