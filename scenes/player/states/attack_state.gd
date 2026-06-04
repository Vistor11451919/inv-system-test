class_name AttackState
extends State

var _locked_dir: int = 1
var _return_state: String = ""

func enter(prev_state: String, _params: Dictionary = {}):
	var player: Player = _actor
	player.velocity.x = 0
	_locked_dir = player.facing_direction
	_return_state = prev_state if prev_state in ["Idle", "Run", "Fall"] else "Fall"
	player._visual.add_mark("anim", 2, {"name": "attack"})
	player._hitbox.reset()
	player._hitbox.monitoring = true
	player._hitbox.get_node("HitboxShape").disabled = false
	player.attack_cooldown_timer = player.attack_cooldown

func exit():
	var player: Player = _actor
	player._hitbox.monitoring = false
	player._hitbox.get_node("HitboxShape").disabled = true

func physics_update(delta: float):
	var player: Player = _actor
	player.velocity.x = move_toward(player.velocity.x, 0, player.move_speed * 4 * delta)
	if not player._anim_playing("attack"):
		_sm.transition_to(_return_state)
