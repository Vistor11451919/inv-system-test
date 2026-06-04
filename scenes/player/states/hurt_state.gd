class_name HurtState
extends State


func enter(_prev_state: String, _params: Dictionary = {}):
	_actor.invulnerable = true
	_actor._visual.add_mark("anim", 2, {"name": "hurt"})
	var knockback = _params.get("knockback", Vector2.ZERO)
	if knockback != Vector2.ZERO:
		_actor.apply_knockback(knockback)

func physics_update(_delta: float):
	if not _actor._anim_playing("hurt"):
		_sm.transition_to("Idle")

func exit():
	_actor.invulnerable = false