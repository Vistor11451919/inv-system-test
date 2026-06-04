class_name DashState
extends State

var _dash_dir: int = 1
var _elapsed: float = 0.0

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.3

func enter(_prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	_dash_dir = player.facing_direction
	_elapsed = 0.0
	player.velocity = Vector2(_dash_dir * dash_speed, 0.0)
	player.invulnerable = true
	player._visual.add_mark("anim", 2, {"name": "dash"})
	player._hitbox.monitoring = false

func exit():
	var player: Player = _actor
	player.invulnerable = false
	player._hitbox.monitoring = true

func physics_update(delta: float):
	var player: Player = _actor
	_elapsed += delta
	player.velocity.x = _dash_dir * dash_speed
	player.velocity.y = 0.0

	if _elapsed >= dash_duration:
		_end_dash()

func _end_dash():
	var player: Player = _actor
	if player.is_on_floor():
		if abs(player.velocity.x) > 10.0:
			_sm.transition_to("Run")
		else:
			_sm.transition_to("Idle")
	else:
		_sm.transition_to("Fall")
