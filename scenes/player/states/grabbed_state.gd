class_name GrabbedState
extends State

var grappler_id: int = 0
var break_time: float = 1.0
var on_break_behavior: String = "knockback"
var _break_timer: SceneTreeTimer = null

func enter(_prev_state: String, params: Dictionary = {}):
	var player: Player = _actor
	grappler_id = params.get("grappler_id", 0)
	break_time = params.get("break_time", 1.0)
	on_break_behavior = params.get("on_break_behavior", "knockback")

	player.velocity = Vector2.ZERO

	# 禁用输入
	player._input.set_input_enabled(false)

	# 锁定双方位置
	WorldManager.set_entity_lock(player.entity_id, true)
	if grappler_id > 0:
		WorldManager.set_entity_lock(grappler_id, true)

	# 通过 VisualController 播放动画
	player._visual.add_mark("anim", 3, {"name": "grabbed"})

	# 启动挣脱计时器
	_break_timer = player.get_tree().create_timer(break_time)
	_break_timer.timeout.connect(_on_break)

func exit():
	var player: Player = _actor
	if not is_instance_valid(player):
		return
	# 解锁双方
	WorldManager.set_entity_lock(player.entity_id, false)
	if grappler_id > 0:
		WorldManager.set_entity_lock(grappler_id, false)
	player._input.set_input_enabled(true)

	# 断开计时器连接
	if _break_timer and _break_timer.timeout.is_connected(_on_break):
		_break_timer.timeout.disconnect(_on_break)
		_break_timer = null

func physics_update(_delta: float):
	var player: Player = _actor
	player.velocity.x = move_toward(player.velocity.x, 0, 5)

func _on_break():
	var player: Player = _actor
	if not is_instance_valid(player):
		return
	if _sm.current_state != self:
		return

	# 根据挣脱行为转换状态
	match on_break_behavior:
		"knockback":
			_sm.transition_to("Hurt", {"force_knockback": true, "knockback": Vector2(200 * -player.facing_direction, -150)})
		_:
			_sm.transition_to("Idle")
