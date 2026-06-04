extends Node

## 测试桩 — 主项目的 CameraManager

var lock_boss_zone_call_count: int = 0
var unlock_boss_zone_call_count: int = 0

func lock_boss_zone(_rect: Rect2):
	lock_boss_zone_call_count += 1

func unlock_boss_zone():
	unlock_boss_zone_call_count += 1
