extends Node

## 简化版 GameManager

signal game_paused()
signal game_resumed()

var is_paused: bool = false

var record_boss_defeated_call_count: int = 0
var last_recorded_boss: String = ""

func _ready():
	# 注册原子效果，让忍术 timeline 能执行 spawn_projectile 等
	AtomicEffectRegistry.register_defaults()

func record_boss_defeated(boss_name: String):
	record_boss_defeated_call_count += 1
	last_recorded_boss = boss_name
