class_name DieState
extends State


func enter(_prev_state: String, _params: Dictionary = {}):
	if GameManager:
		GameManager.record_death()
	_actor._visual.add_mark("anim", 2, {"name": "die"})
	_actor.velocity = Vector2.ZERO
	_actor.set_physics_process(false)
	_actor.set_process_input(false)

func exit():
	_actor.set_physics_process(true)
	_actor.set_process_input(true)