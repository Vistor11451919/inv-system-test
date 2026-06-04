class_name Projectile
extends Area2D

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 300.0
var _caster_id: int = -1
var _damage: float = 10.0
var _lifetime: float = 3.0
var _spawned_at: float = 0.0
var _hit_already: bool = false
var _homing_target: Node = null
var _homing_strength: float = 2.0
var _piercing: bool = false

static var _placeholder_texture: ImageTexture = null

@onready var _sprite: Sprite2D = $Sprite2D


func _ready():
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	if _sprite and not _sprite.texture:
		_sprite.texture = _get_placeholder()


static func _get_placeholder() -> ImageTexture:
	if not _placeholder_texture:
		var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 0.8, 0.2, 1))
		_placeholder_texture = ImageTexture.create_from_image(img)
	return _placeholder_texture


func launch(dir: Vector2, speed: float, caster_id: int, damage: float,
	homing_target: Node = null, homing_strength: float = 2.0, piercing: bool = false):
	_direction = dir
	_speed = speed
	_caster_id = caster_id
	_damage = damage
	_homing_target = homing_target
	_homing_strength = homing_strength
	_piercing = piercing
	_spawned_at = Time.get_ticks_msec() / 1000.0

	if _homing_target:
		_sprite.self_modulate = Color(1, 0.5, 0.0, 1)
	else:
		_sprite.self_modulate = Color(1, 0.8, 0.2, 1)

	if _sprite and dir.x < 0:
		_sprite.scale.x = abs(_sprite.scale.x) * -1

	await get_tree().create_timer(_lifetime).timeout
	if is_instance_valid(self):
		_despawn()


func _physics_process(delta: float):
	if _homing_target and is_instance_valid(_homing_target):
		var target_dir = (_homing_target.global_position - global_position).normalized()
		# 钳制 Y 分量，模拟 2D 平台水平追踪
		target_dir.y *= 0.5
		_direction = _direction.lerp(target_dir, _homing_strength * delta).normalized()
		if _direction == Vector2.ZERO:
			_direction = Vector2.RIGHT
	position += _direction * _speed * delta


func _on_hit(other: Node):
	var hurtbox = other as HurtboxComponent

	# 碰到发射者自己 → 忽略
	if hurtbox and hurtbox.entity_id == _caster_id:
		return
	if other and "entity_id" in other and other.entity_id == _caster_id:
		return

	# 非 Hurtbox 的 Area2D（检测区、竞技场锁等）→ 忽略
	if other is Area2D and not hurtbox:
		return

	if _hit_already:
		return

	# body_entered 先碰到实体身体（非 Hurtbox）→ 不等，等 area_entered 处理伤害
	if not hurtbox and other and "entity_id" in other:
		return

	_hit_already = true

	# 受伤结算
	if hurtbox and hurtbox.entity_id >= 0:
		var final_damage = DamageUtils.resolve_damage(
			_caster_id, hurtbox.entity_id, _damage, {}, "default"
		)
		if final_damage > 0:
			EventBus.damage_dealt.emit(_caster_id, hurtbox.entity_id, final_damage, {})
			var target = WorldManager.get_entity(hurtbox.entity_id)
			if target and target.has_method("take_damage"):
				target.take_damage(final_damage, _caster_id, {})

	# 撞墙/地 → 消失（除非穿墙）
	if not _piercing:
		_despawn()


func _despawn():
	set_process(false)
	set_physics_process(false)
	queue_free()
