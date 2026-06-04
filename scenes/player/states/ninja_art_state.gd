class_name NinjaArtState
extends State

var _art: NinjaArt = null
var _locked_dir: int = 1
var _return_state: String = "Idle"
var _executor: SkillExecutor = null
var _timeout: float = 0.0
var _entered_at: float = 0.0
var _casting: bool = false
var _cast_timer: float = 0.0

func enter(prev_state: String, params: Dictionary = {}):
	var player: Player = _actor
	_art = params.get("art", null)
	if not _art:
		_sm.transition_to("Idle")
		return
	_timeout = 3.0
	_entered_at = Time.get_ticks_msec() / 1000.0

	_locked_dir = player.facing_direction
	_return_state = prev_state if prev_state in ["Idle", "Run", "Fall"] else "Fall"

	# 验证查克拉是否足够
	var chakra = player.get_stat("chakra", 50)
	var art_cost = _art.chakra_cost
	if chakra < art_cost:
		_sm.transition_to(_return_state)
		return

	# 播放前摇动画
	player._visual.add_mark("anim", 2, {"name": "ninja_art_cast"})

	if _art.cast_time > 0.0:
		# 进入前摇阶段 — 等待 cast_time 后再执行忍术
		_casting = true
		_cast_timer = _art.cast_time
	else:
		# 无前摇，立即执行
		_execute_skill(player)


func _execute_skill(player: Player):
	# 先扣查克拉（避免 execute_skill 同步完成时 _cleanup 把 _art 置 null）
	DataManager.modify_attribute(player.entity_id, "chakra", -_art.chakra_cost)
	var remaining = player.get_stat("chakra", 50)

	_executor = player.get_node_or_null("SkillExecutor")
	if _executor:
		if not _executor.skill_finished.is_connected(_on_skill_finished):
			_executor.skill_finished.connect(_on_skill_finished)
		var result = _executor.execute_skill(_art, player.entity_id, player)
		if not result:
			# 失败则退回查克拉
			DataManager.modify_attribute(player.entity_id, "chakra", _art.chakra_cost)
			var refunded = player.get_stat("chakra", 50)
			_cleanup()
			_sm.transition_to(_return_state)
			return
	else:
		_cleanup()
		_sm.transition_to(_return_state)


func physics_update(delta: float):
	var player: Player = _actor
	player.velocity.x = move_toward(player.velocity.x, 0, player.move_speed * 4 * delta)

	# 前摇阶段：等待 cast_time 过去后才执行
	if _casting:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_casting = false
			_execute_skill(player)
		return

	# 执行阶段：超时保护
	_timeout -= delta
	if _timeout <= 0.0:
		_cleanup()
		_sm.transition_to(_return_state)


func _on_skill_finished(art_id: String):
	if _art and _art.art_id == art_id:
		var elapsed = Time.get_ticks_msec() / 1000.0 - _entered_at
		_cleanup()
		_sm.transition_to(_return_state)


func _cleanup():
	if _executor and is_instance_valid(_executor) and _executor.skill_finished.is_connected(_on_skill_finished):
		_executor.skill_finished.disconnect(_on_skill_finished)
	_executor = null
	_art = null


func exit():
	_cleanup()
