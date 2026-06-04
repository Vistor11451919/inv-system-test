class_name EnemyBase
extends CharacterBody2D

## 敌人基类 — 包含忍术接口（与 enemy-ai-test v1.1.0 兼容）
signal ninja_art_finished(art_id: String)

@export var config: EnemyConfig = null

var entity_id: int = -1
var hp: float = 50.0
var max_hp: float = 50.0
var facing_direction: int = -1
var gravity_amount: float = 980.0

var player_detected: bool = false
var player_entity: Node = null
var spawn_position: Vector2 = Vector2.ZERO

var _attack_cooldown: float = 0.0
var _invulnerable: bool = false
var _current_timeline_executor: TimelineExecutor = null
var _ninja_art_cooldowns: Dictionary = {}
var _retreat_timer: float = 0.0
var _last_art_id: String = ""

@onready var _nav: NavigationAgent2D = $NavigationAgent if has_node("NavigationAgent") else null
@onready var _sm = $AI/StateMachine
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _visual: VisualController = $VisualController
@onready var _hurtbox = $Hurtbox
@onready var _hitbox = $Hitbox
@onready var _detection: Area2D = $DetectionArea
@onready var _hp_label: Label = $HPLabel


func _ready():
	if config:
		_apply_config()
	spawn_position = global_position
	entity_id = WorldManager.register_entity(self)
	_hurtbox.entity_id = entity_id
	_hitbox.caster_id = entity_id
	_hitbox.monitoring = false

	_detection.body_entered.connect(_on_detection_body_entered)
	_detection.body_exited.connect(_on_detection_body_exited)

	_sm.init("Patrol")
	_update_hp_display()


func _physics_process(_delta: float):
	_attack_cooldown = max(0, _attack_cooldown - _delta)
	if _retreat_timer > 0:
		_retreat_timer = max(0, _retreat_timer - _delta)


func _apply_config():
	hp = config.max_hp
	max_hp = config.max_hp
	gravity_amount = config.gravity

	if config.sprite_texture:
		_sprite.texture = config.sprite_texture
	_sprite.centered = true
	_sprite.scale = config.sprite_scale
	_sprite.position = config.sprite_offset

	var body_shape = $CollisionShape2D.shape as RectangleShape2D
	if body_shape and config.collision_size != Vector2.ZERO:
		body_shape.size = config.collision_size

	var hurt_shape = _hurtbox.get_node("CollisionShape2D").shape as RectangleShape2D
	if hurt_shape and config.hurtbox_size != Vector2.ZERO:
		hurt_shape.size = config.hurtbox_size

	var detect_shape = _detection.get_node("CollisionShape2D").shape as CircleShape2D
	if detect_shape and config.detection_radius > 0:
		detect_shape.radius = config.detection_radius

	# 头顶名字标签（通过 owner 查找，避免 get_parent() 链）
	if not owner.has_node("NameLabel"):
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = config.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(0, -48)
		name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		name_label.add_theme_constant_override("outline_size", 2)
		name_label.add_theme_color_override("font_color", config.placeholder_color.lightened(0.5))
		owner.add_child(name_label)


func get_stat(stat_name: String, default_val: float = 0.0) -> float:
	match stat_name:
		"hp": return hp
		"max_hp": return max_hp
		"attack": return config.attack if config else default_val
		"defense": return config.defense if config else default_val
	return default_val


func take_damage(final_damage: float, _caster_id: int, _data_packet: Dictionary):
	if hp <= 0 or _invulnerable:
		return
	hp = max(0.0, hp - final_damage)
	EventBus.entity_health_changed.emit(entity_id, hp + final_damage, hp)
	_update_hp_display()
	if hp <= 0:
		_sm.transition_to("Die")
	else:
		_set_invulnerable(true)
		_sm.transition_to("Hurt")


func can_attack() -> bool:
	return _attack_cooldown <= 0.0


func start_attack_cooldown():
	if config:
		_attack_cooldown = config.attack_cooldown


func set_facing(dir: int):
	if dir == 0:
		return
	facing_direction = sign(dir)
	_visual.add_mark("facing", 1, {"direction": facing_direction})


func _set_invulnerable(val: bool):
	_invulnerable = val
	if val:
		_visual.add_mark("flash", 2, {"color": Color(2, 0.5, 0.5), "duration": 0.05})
		await get_tree().create_timer(config.invulnerability_time if config else 0.3).timeout
		if not is_instance_valid(self):
			return
		_invulnerable = false
		_visual.add_mark("sprite_color", 2, {"color": Color.WHITE})


func _update_hp_display():
	if _hp_label:
		_hp_label.text = "%.0f/%.0f" % [hp, max_hp]


func _on_detection_body_entered(body: Node):
	if body.is_in_group("player"):
		player_detected = true
		player_entity = body


func _on_detection_body_exited(body: Node):
	if body.is_in_group("player"):
		player_detected = false
		player_entity = null


# 向目标位置移动（供 Patrol/Chase 调用）
func move_toward_target(target_pos: Vector2, speed: float) -> float:
	var dir = sign(target_pos.x - global_position.x)
	set_facing(dir)
	velocity.x = dir * speed
	return dir


func _die_cleanup():
	cancel_ninja_art()
	WorldManager.unregister_entity(entity_id)
	queue_free()


# ------------- 忍术接口 (与 enemy-ai-test v1.1.0 兼容) -------------

## 使用忍术 — 通过 TimelineExecutor 执行 NinjaArt 的时间线
func use_ninja_art(art: Resource) -> bool:
	if not art or not art.has_method("get"):
		return false

	# 冷却检查
	var art_id = _res_str(art, "art_id")
	if not art_id.is_empty():
		var cd_until = _ninja_art_cooldowns.get(art_id, 0.0)
		if Time.get_ticks_msec() / 1000.0 < cd_until:
			return false

	var timeline: NinjaArtTimeline = _resolve_art_timeline(art)
	if not timeline:
		return false

	cancel_ninja_art()

	var context = {
		"caster_id": entity_id,
		"caster_node": self,
		"self_position": global_position,
		"origin_direction": Vector2(facing_direction, 0),
	}

	_current_timeline_executor = TimelineExecutor.new()
	_current_timeline_executor.on_finished = func(tlid: String):
		ninja_art_finished.emit(tlid)
		_current_timeline_executor = null

	_current_timeline_executor.start(timeline, context)

	# 设置冷却
	if not art_id.is_empty():
		var cd = _res_float(art, "cooldown", 1.0)
		_ninja_art_cooldowns[art_id] = Time.get_ticks_msec() / 1000.0 + cd

	return true


## 取消正在执行的忍术
func cancel_ninja_art():
	if _current_timeline_executor:
		_current_timeline_executor.cancel()
		_current_timeline_executor = null


## 安全读取 Resource 属性（Resource.get() 在 Godot 4 中不支持默认值参数）
func _res_str(r: Resource, key: String, dflt: String = "") -> String:
	var v = r.get(key)
	return str(v) if v != null else dflt

func _res_float(r: Resource, key: String, dflt: float = 0.0) -> float:
	var v = r.get(key)
	return float(v) if v != null else dflt


## 解析 NinjaArt 的 data_packet 中的 timeline 路径，或自动构建投射物时间线
func _resolve_art_timeline(art: Resource) -> NinjaArtTimeline:
	var dp = art.get("data_packet")
	if not dp is Dictionary:
		dp = {}
	var tl_path = dp.get("timeline", "")
	if tl_path:
		var tl = load(tl_path)
		if tl is NinjaArtTimeline:
			return tl

	# 回退：自动构建单步投射物时间线
	var scene_path = _res_str(art, "projectile_scene")
	if scene_path.is_empty():
		return null
	var step = SkillStep.new()
	step.effect_id = "spawn_projectile"
	step.params = {
		"scene": scene_path,
		"speed": _res_float(art, "projectile_speed", 300.0),
		"damage": _res_float(art, "damage", 10.0),
	}
	var tl = NinjaArtTimeline.new()
	tl.timeline_id = _res_str(art, "art_id", "auto")
	tl.steps = [step]
	return tl
