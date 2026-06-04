extends Node

## 通用测试 Mock 实体 — 可自由配置任意 stat

var entity_id: int = -1

var _stats: Dictionary = {
	attack = 0.0,
	defense = 0.0,
	crit_rate = 0.0,
	crit_damage = 1.5,
	hp = 100.0,
	max_hp = 100.0,
}

func set_stat(name: String, value: float):
	_stats[name] = value

func get_stat(stat_name: String, default_val: float = 0.0) -> float:
	return _stats.get(stat_name, default_val)
