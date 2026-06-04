class_name CrouchState
extends State

var _full_height: float = 24.0
var _crouch_height: float = 12.0
var _crouch_speed: float = 40.0

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	player.velocity.x = 0
	player._visual.add_mark("anim", 2, {"name": "crouch"})
	_shrink_collision(player, true)

func exit():
	var player: Player = _actor
	_shrink_collision(player, false)

func physics_update(_delta: float):
	var player: Player = _actor

	if player._input.consume_action("jump"):
		_sm.transition_to("Jump")
		return

	# 松开下蹲键 → 站起
	if not player._input.is_crouch_pressed():
		if player.is_on_floor():
			_sm.transition_to("Idle")
		else:
			_sm.transition_to("Fall")
		return

	# 下蹲时慢速移动
	var dir = player._input.get_move_direction()
	player.velocity.x = dir * _crouch_speed
	if dir != 0:
		player.set_facing(1 if dir > 0 else -1)

	# 检查是否悬空
	if not player.is_on_floor():
		_sm.transition_to("Fall")
		return

func _shrink_collision(player: Player, shrink: bool):
	var shape = player._collision_shape.shape as RectangleShape2D
	if not shape:
		return
	var new_height = _crouch_height if shrink else _full_height
	shape.size.y = new_height
	player._collision_shape.position.y = (_full_height - new_height) / 2.0

	# 同步缩小 hurtbox
	var hb_shape = player._hurtbox.get_node("HurtboxShape")
	var hb_rect = hb_shape.shape as RectangleShape2D
	if hb_rect:
		var hb_new = (new_height - 2) if shrink else (_full_height - 2)
		hb_rect.size.y = hb_new
		hb_shape.position.y = (_full_height - new_height) / 2.0
