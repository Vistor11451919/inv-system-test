class_name TestDummy
extends Node2D

## 忍术测试假人 — 受投射物/范围攻击后扣血，HP 归零销毁
## 视觉：绿→黄→红随血量变色，头顶 HP 条，受伤闪白反馈

@export var max_hp: float = 50.0
@export var defense: float = 5.0
@export var body_size: Vector2 = Vector2(32, 48)

var current_hp: float
var entity_id: int = -1


func _ready():
	current_hp = max_hp
	entity_id = WorldManager.register_entity(self)
	$Hurtbox.entity_id = entity_id
	EventBus.damage_dealt.connect(_on_damage_dealt)
	queue_redraw()


func get_stat(name: String, _default: float = 0.0) -> float:
	match name:
		"defense":
			return defense
		"hp":
			return current_hp
		"max_hp":
			return max_hp
		"attack":
			return 0.0
	return _default


# damage_area 等范围效果通过此入口触发
func take_damage(_damage: float, _caster_id: int, _data: Dictionary):
	pass  # 实际伤害走 EventBus.damage_dealt → _on_damage_dealt


func _on_damage_dealt(caster_id: int, target_id: int, damage: float, data: Dictionary):
	if target_id != entity_id:
		return
	current_hp = max(0, current_hp - damage)

	modulate = Color(2, 2, 2)
	queue_redraw()
	await get_tree().create_timer(0.06).timeout
	if not is_instance_valid(self):
		return
	modulate = Color.WHITE

	if current_hp <= 0:
		WorldManager.unregister_entity(entity_id)
		queue_free()


func _draw():
	var ratio = current_hp / max_hp
	var hue = ratio * 0.33
	var body_color = Color.from_hsv(hue, 0.85, 0.7)
	draw_rect(Rect2(-body_size.x / 2, -body_size.y / 2, body_size.x, body_size.y), body_color)
	draw_rect(Rect2(-body_size.x / 2, -body_size.y / 2, body_size.x, body_size.y), Color(1, 1, 1, 0.15), false, 1.0)

	var bar_w = 28.0
	var bar_h = 4.0
	var bar_x = -bar_w / 2
	var bar_y = -body_size.y / 2 - 8
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.15, 0.15, 0.15))

	var hp_color = Color.from_hsv(hue, 0.9, 0.9)
	if ratio > 0:
		draw_rect(Rect2(bar_x, bar_y, bar_w * ratio, bar_h), hp_color)

	draw_line(Vector2(-5, -5), Vector2(5, 5), Color(1, 1, 1, 0.35), 1.5)
	draw_line(Vector2(5, -5), Vector2(-5, 5), Color(1, 1, 1, 0.35), 1.5)

	var label = "TARGET"
	var font = ThemeDB.fallback_font
	var font_size = 8
	var label_w = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var label_pos = Vector2(-label_w / 2, -body_size.y / 2 - 14)
	draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.5))
