class_name AtomicEffectRegistry
extends RefCounted

static var _effects: Dictionary = {}

static func register_effect(effect_id: String, callable: Callable):
	_effects[effect_id] = callable

static func execute(effect_id: String, context: Dictionary, params: Dictionary) -> bool:
	if not _effects.has(effect_id):
		push_error("AtomicEffectRegistry: 未知效果ID: ", effect_id)
		return false
	return _effects[effect_id].call(context, params)

static func has_effect(effect_id: String) -> bool:
	return _effects.has(effect_id)

static func get_all_effects() -> Array:
	return _effects.keys()

static func register_defaults():
	register_effect("spawn_projectile", _spawn_projectile)
	register_effect("damage_area", _damage_area)
	register_effect("apply_buff", _apply_buff)
	register_effect("apply_knockback", _apply_knockback)
	register_effect("spawn_effect", _spawn_effect)
	register_effect("heal", _heal)
	register_effect("status_effect", _status_effect)
	register_effect("teleport", _teleport)
	register_effect("summon", _summon)
	register_effect("shield", _shield)
	register_effect("pull", _pull)
	register_effect("push", _push)
	register_effect("aoe_field", _aoe_field)
	register_effect("camera_shake", _camera_shake)
	register_effect("spawn_ring", _spawn_ring)

static func _spawn_projectile(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var scene_path = params.get("scene", "res://scenes/common/projectile.tscn")
	var projectile_scene = load(scene_path)
	if not projectile_scene:
		return false
	var projectile = projectile_scene.instantiate()
	# 使用 context 中保存的方向（skill executor 在发起时捕获），避免 call_deferred 后读过时值
	var direction = context.get("origin_direction", Vector2.RIGHT)
	var spawn_pos = context.get("self_position", caster.global_position)
	var world = caster.get_tree().current_scene
	if world:
		world.add_child(projectile)
		projectile.global_position = spawn_pos + direction * 20
		if projectile.has_method("launch"):
			var speed = params.get("speed", 400)
			var damage = params.get("damage", 10)
			var caster_id = context.get("caster_id", 0)
			projectile.launch(direction, speed, caster_id, damage)
	context["last_spawned_node"] = projectile
	return true

static func _damage_area(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var pos = context.get("self_position", caster.global_position)
	var radius = params.get("radius", 50.0)
	var damage = params.get("damage", 10.0)
	var element = params.get("element", "physical")
	var caster_id = context.get("caster_id", 0)
	var space = caster.get_world_2d().direct_space_state
	if not space:
		return false
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.set_shape(shape)
	query.transform = Transform2D(0, pos)
	query.exclude = [caster.get_rid()]
	query.collision_mask = params.get("collision_mask", 2)
	var hits = space.intersect_shape(query)
	for hit in hits:
		var collider = hit.collider
		if collider and collider.has_method("get_parent"):
			var parent = collider.get_parent()
			if parent and parent.has_method("take_damage"):
				EventBus.damage_dealt.emit(caster_id, parent.get("entity_id", 0), damage, {"element": element})
				parent.take_damage(damage, caster_id, {"element": element})
	return true

static func _apply_buff(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var buff_id = params.get("buff_id", "")
	if buff_id.is_empty():
		return false
	EventBus.story_flag_changed.emit("buff_" + buff_id, true)
	return true

static func _apply_knockback(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var force = params.get("force", Vector2(200, -200))
	if caster.has_method("apply_knockback"):
		caster.apply_knockback(force)
	return true

static func _spawn_effect(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var scene_path = params.get("scene", "")
	if scene_path.is_empty():
		return false
	var effect_scene = load(scene_path)
	if not effect_scene:
		return false
	var effect = effect_scene.instantiate()
	var pos = context.get("self_position", caster.global_position)
	var world = caster.get_tree().current_scene
	if world:
		world.add_child(effect)
		effect.global_position = pos
	return true

static func _heal(context: Dictionary, params: Dictionary) -> bool:
	var caster_id = context.get("caster_id", 0)
	var amount = params.get("amount", 10)
	if caster_id > 0:
		DataManager.modify_attribute(caster_id, "hp", amount)
	return true

# ---- 扩展效果 ----

static func _status_effect(context: Dictionary, params: Dictionary) -> bool:
	var status_id = params.get("status_id", "")
	var duration = params.get("duration", 3.0)
	var magnitude = params.get("magnitude", 1.0)
	if status_id.is_empty():
		return false
	EventBus.story_flag_changed.emit("status_" + status_id, {"duration": duration, "magnitude": magnitude})
	return true

static func _teleport(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var distance = params.get("distance", 100.0)
	var direction = context.get("origin_direction", Vector2.RIGHT)
	var target_pos = caster.global_position + direction * distance
	var space = caster.get_world_2d().direct_space_state
	if space:
		var query = PhysicsRayQueryParameters2D.new()
		query.from = caster.global_position
		query.to = target_pos
		query.exclude = [caster.get_rid()]
		var result = space.intersect_ray(query)
		if result:
			target_pos = result.position - direction * 10
	caster.global_position = target_pos
	return true

static func _summon(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var scene_path = params.get("scene", "")
	var count = params.get("count", 1)
	var offset_raw = params.get("offset", Vector2(40, 0))
	var offset = offset_raw if offset_raw is Vector2 else Vector2(offset_raw[0], offset_raw[1]) if offset_raw is Array and offset_raw.size() >= 2 else Vector2(40, 0)
	if scene_path.is_empty():
		return false
	var scene = load(scene_path)
	if not scene:
		return false
	var world = caster.get_tree().current_scene
	if not world:
		return false
	for i in range(count):
		var instance = scene.instantiate()
		var spawn_pos = caster.global_position + offset * (i - (count - 1) / 2.0)
		world.add_child(instance)
		instance.global_position = spawn_pos
	return true

static func _shield(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var duration = params.get("duration", 2.0)
	var damage_reduction = params.get("damage_reduction", 0.5)
	if caster.has_method("apply_shield"):
		caster.apply_shield(duration, damage_reduction)
		EventBus.story_flag_changed.emit("shield_applied", {"duration": duration, "damage_reduction": damage_reduction})
	return true

static func _pull(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var radius = params.get("radius", 100.0)
	var force = params.get("force", 500.0)
	var caster_pos = caster.global_position
	var space = caster.get_world_2d().direct_space_state
	if not space:
		return false
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.set_shape(shape)
	query.transform = Transform2D(0, caster_pos)
	query.exclude = [caster.get_rid()]
	query.collision_mask = params.get("collision_mask", 1)
	var hits = space.intersect_shape(query)
	for hit in hits:
		var collider = hit.collider
		if collider and collider.has_method("get_parent"):
			var parent = collider.get_parent()
			if parent and parent.has_method("apply_knockback"):
				var dir = (caster_pos - parent.global_position).normalized()
				parent.apply_knockback(dir * force)
	return true

static func _push(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var radius = params.get("radius", 100.0)
	var force = params.get("force", 500.0)
	var caster_pos = caster.global_position
	var space = caster.get_world_2d().direct_space_state
	if not space:
		return false
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	query.set_shape(shape)
	query.transform = Transform2D(0, caster_pos)
	query.exclude = [caster.get_rid()]
	query.collision_mask = params.get("collision_mask", 1)
	var hits = space.intersect_shape(query)
	for hit in hits:
		var collider = hit.collider
		if collider and collider.has_method("get_parent"):
			var parent = collider.get_parent()
			if parent and parent.has_method("apply_knockback"):
				var dir = (parent.global_position - caster_pos).normalized()
				parent.apply_knockback(dir * force)
	return true

static func _aoe_field(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var scene_path = params.get("scene", "")
	var duration = params.get("duration", 5.0)
	if scene_path.is_empty():
		return false
	var field_scene = load(scene_path)
	if not field_scene:
		return false
	var world = caster.get_tree().current_scene
	if not world:
		return false
	var field = field_scene.instantiate()
	world.add_child(field)
	field.global_position = context.get("self_position", caster.global_position)
	if field.has_method("set_duration"):
		field.set_duration(duration)
	if params.has("radius") and field.has_method("set_radius"):
		field.set_radius(params["radius"])
	if params.has("width") and field.has_method("set_width"):
		field.set_width(params["width"])
	if params.has("height") and field.has_method("set_height"):
		field.set_height(params["height"])
	if field.has_method("set_caster_id"):
		field.set_caster_id(context.get("caster_id", 0))
	return true

static func _camera_shake(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var intensity = params.get("intensity", 5.0)
	var duration = params.get("duration", 0.3)
	var camera = caster.get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(intensity, duration)
	return true

static func _spawn_ring(context: Dictionary, params: Dictionary) -> bool:
	var caster = context.get("caster_node")
	if not caster:
		return false
	var count = params.get("count", 8)
	var ring_radius = params.get("radius", 60.0)
	var scene_path = params.get("projectile_scene", "res://scenes/common/projectile.tscn")
	var speed = params.get("speed", 300.0)
	var damage = params.get("damage", 8.0)
	var caster_id = context.get("caster_id", 0)
	var projectile_scene = load(scene_path)
	if not projectile_scene:
		return false
	var world = caster.get_tree().current_scene
	if not world:
		return false
	var center = context.get("self_position", caster.global_position)
	for i in range(count):
		var angle = (2.0 * PI / count) * i
		var dir = Vector2(cos(angle), sin(angle))
		var projectile = projectile_scene.instantiate()
		world.add_child(projectile)
		projectile.global_position = center + dir * ring_radius
		if projectile.has_method("launch"):
			projectile.launch(dir, speed, caster_id, damage)
	return true
