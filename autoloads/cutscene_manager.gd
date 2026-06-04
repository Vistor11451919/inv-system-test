extends Node

## 测试桩 — 主项目的 CutsceneManager

var play_call_count: int = 0
var last_played_resource = null

func play(resource) -> bool:
	play_call_count += 1
	last_played_resource = resource
	return false
