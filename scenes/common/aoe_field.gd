extends Area2D

## 领域效果场 — 支持矩形墙和圆形结界

var _duration: float = 5.0
var _width: float = 60.0
var _height: float = 120.0
var _radius: float = 80.0
var _caster_id: int = 0


func _ready():
	var is_rect = _radius == 80.0  # 没调 set_radius 说明是矩形
	if is_rect:
		var shape = RectangleShape2D.new()
		shape.size = Vector2(_width, _height)
		$CollisionShape2D.shape = shape
		$WallVisual.offset_left = -_width / 2
		$WallVisual.offset_top = -_height / 2
		$WallVisual.offset_right = _width / 2
		$WallVisual.offset_bottom = _height / 2
	else:
		var shape = CircleShape2D.new()
		shape.radius = _radius
		$CollisionShape2D.shape = shape
		$WallVisual.offset_left = -_radius
		$WallVisual.offset_top = -_radius
		$WallVisual.offset_right = _radius
		$WallVisual.offset_bottom = _radius

	$Timer.wait_time = _duration
	$Timer.start()
	$Timer.timeout.connect(queue_free)


func set_duration(d: float):
	_duration = d


func set_radius(r: float):
	_radius = r


func set_width(w: float):
	_width = w


func set_height(h: float):
	_height = h


func set_caster_id(cid: int):
	_caster_id = cid
