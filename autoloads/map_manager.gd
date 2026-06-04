extends Node

## 测试桩 — 主项目的 MapManager

var unlock_region_call_count: int = 0
var last_unlocked_region: String = ""

func unlock_region(region_id: String):
	unlock_region_call_count += 1
	last_unlocked_region = region_id
