class_name EnemyBase
extends CharacterBody2D

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
	# 头顶名字标签（已存在时不重复添加，如 Boss 模板自带 NameLabel）
	if not _visual.get_parent().has_node("NameLabel"):
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = config.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(0, -48)
		name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		name_label.add_theme_constant_override("outline_size", 2)
		name_label.add_theme_color_override("font_color", config.placeholder_color.lightened(0.5))
		_visual.get_parent().add_child(name_label)


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
	WorldManager.unregister_entity(entity_id)
	queue_free()
