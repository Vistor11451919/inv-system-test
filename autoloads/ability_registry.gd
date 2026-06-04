extends Node

## 简化版 AbilityRegistry

var _abilities: Dictionary = {}

func has_ability(ability_id: String) -> bool:
	return _abilities.get(ability_id, false)

func unlock_ability(ability_id: String):
	_abilities[ability_id] = true

func unlock_all():
	for key in ["dash", "slide", "double_jump", "wall_jump"]:
		_abilities[key] = true
