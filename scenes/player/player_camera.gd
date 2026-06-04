extends Camera2D

## 简化版跟随摄像机（无震屏、无区域限制）

@export var follow_speed: float = 6.0

var _target: Node2D = null

func _ready():
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	_target = get_parent() as Node2D
	if _target:
		global_position = _target.global_position
