class_name State
extends Node

var _sm: StateMachine = null
var _actor: Node = null

func setup(sm: StateMachine, actor: Node):
	_sm = sm
	_actor = actor

func enter(_prev_state: String, _params: Dictionary = {}):
	pass

func exit():
	pass

func physics_update(_delta: float):
	pass

func input_update(_event: InputEvent):
	pass
