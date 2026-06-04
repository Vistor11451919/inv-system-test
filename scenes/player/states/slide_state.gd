class_name SlideState
extends State

var _slide_dir: int = 1
var _elapsed: float = 0.0
var _full_height: float = 24.0
var _slide_height: float = 12.0

@export var slide_speed: float = 400.0
@export var slide_duration: float = 0.6

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	_slide_dir = player.facing_direction
	_elapsed = 0.0
	player.velocity = Vector2(_slide_dir * slide_speed, 0.0)
	player._visual.add_mark("anim", 2, {"name": "slide"})
	_shrink_collision(player, true)

func exit():
	var player: Player = _actor
	_shrink_collision(player, false)

func physics_update(delta: float):
	var player: Player = _actor
	_elapsed += delta

	# 滑铲中离地立即转入 Fall，避免空中滑行
	if not player.is_on_floor():
		_shrink_collision(player, false)
		_sm.transition_to("Fall")
		return

	if player._input.consume_action("jump"):
		_shrink_collision(player, false)
		player.jumps_used = 0
		player.velocity.y = player.jump_velocity
		_sm.transition_to("Jump")
		return

	if _elapsed >= slide_duration or abs(player.velocity.x) < 10.0:
		_end_slide(player)
		return

	player.velocity.x = _slide_dir * slide_speed

func _end_slide(player: Player):
	_shrink_collision(player, false)
	if player.is_on_floor():
		if player._input.is_crouch_pressed():
			_sm.transition_to("Crouch")  # 还按着蹲 → 稳定蹲下，不循环
		elif player._input.is_move_pressed():
			_sm.transition_to("Run")
		else:
			_sm.transition_to("Idle")
	else:
		_sm.transition_to("Fall")

func _shrink_collision(player: Player, shrink: bool):
	var shape = player._collision_shape.shape as RectangleShape2D
	if not shape:
		return
	var new_height = _slide_height if shrink else _full_height
	shape.size.y = new_height
	player._collision_shape.position.y = (_full_height - new_height) / 2.0

	# 同步缩小 hurtbox
	var hb_shape = player._hurtbox.get_node("HurtboxShape")
	var hb_rect = hb_shape.shape as RectangleShape2D
	if hb_rect:
		var hb_new = (new_height - 2) if shrink else (_full_height - 2)
		hb_rect.size.y = hb_new
		hb_shape.position.y = (_full_height - new_height) / 2.0
