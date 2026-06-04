extends Node

## 简化版 DataManager — 属性管理 + 忍术装备

var player_data = {
	"attributes": {
		"hp": 100.0,
		"max_hp": 100.0,
		"attack": 10.0,
		"defense": 5.0,
		"chakra": 50.0,
		"max_chakra": 50.0,
	}
}

var _equipped_ninja_arts: Array = []

func modify_attribute(_entity_id: int, attr_name: String, delta: float):
	if player_data.attributes.has(attr_name):
		var current = player_data.attributes[attr_name]
		var max_val = player_data.attributes.get("max_" + attr_name, INF)
		player_data.attributes[attr_name] = clamp(current + delta, 0, max_val)

func get_equipped_ninja_art(slot: int):
	if slot < _equipped_ninja_arts.size():
		return _equipped_ninja_arts[slot]
	return null

func equip_ninja_art(art, slot: int):
	while _equipped_ninja_arts.size() <= slot:
		_equipped_ninja_arts.append(null)
	_equipped_ninja_arts[slot] = art

func set_attr(name: String, value: float):
	player_data.attributes[name] = value

func get_attr(name: String, default_val: float = 0.0) -> float:
	return player_data.attributes.get(name, default_val)
