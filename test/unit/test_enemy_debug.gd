extends GutTest

## Soldier 调试信息 — 攻击盒/受击盒/碰撞盒加载验证

const ENEMY_SCENE = preload("res://scenes/enemies/templates/enemy_template.tscn")
const SOLDIER_CFG = preload("res://data/enemies/soldier.tres")

func test_soldier_hitbox_hurtbox_debug():
	var e = ENEMY_SCENE.instantiate()
	e.config = SOLDIER_CFG
	add_child_autofree(e)
	await get_tree().process_frame

	# ── 碰撞盒 (CollisionShape2D) ──
	var body_shape = e.get_node("CollisionShape2D").shape as RectangleShape2D
	push_warning("=== Soldier 碰撞系统调试 ===")
	push_warning("config: id=%s  name=%s" % [SOLDIER_CFG.enemy_id, SOLDIER_CFG.display_name])
	push_warning("config.collision_size=%s" % SOLDIER_CFG.collision_size)
	if body_shape:
		push_warning("碰撞盒 RectangleShape2D: size=%s  (来自 config: %.0f,%.0f)" % [
			body_shape.size, SOLDIER_CFG.collision_size.x, SOLDIER_CFG.collision_size.y])

	# ── 受击盒 (Hurtbox) ──
	var hurtbox = e._hurtbox
	var hurt_shape_node = hurtbox.get_node("CollisionShape2D")
	var hurt_shape = hurt_shape_node.shape as RectangleShape2D
	push_warning("Hurtbox: collision_layer=%d  mask=%d  entity_id=%d" % [
		hurtbox.collision_layer, hurtbox.collision_mask, hurtbox.entity_id])
	if hurt_shape:
		push_warning("受击盒 RectangleShape2D: size=%s  (来自 config: %.0f,%.0f)" % [
			hurt_shape.size, SOLDIER_CFG.hurtbox_size.x, SOLDIER_CFG.hurtbox_size.y])

	# ── 攻击盒 (Hitbox) ──
	var hitbox = e._hitbox
	var hit_shape_node = hitbox.get_node("CollisionShape2D")
	var hit_shape = hit_shape_node.shape as RectangleShape2D
	push_warning("Hitbox: collision_layer=%d  mask=%d  monitoring=%s  damage=%.0f" % [
		hitbox.collision_layer, hitbox.collision_mask, hitbox.monitoring, hitbox.damage])
	if hit_shape:
		push_warning("攻击盒 RectangleShape2D: size=%s  disabled=%s" % [
			hit_shape.size, hit_shape_node.disabled])

	# ── 检测范围 (DetectionArea) ──
	var detect = e._detection
	var detect_shape_node = detect.get_node("CollisionShape2D")
	var detect_shape = detect_shape_node.shape as CircleShape2D
	push_warning("DetectionArea: collision_mask=%d" % detect.collision_mask)
	if detect_shape:
		push_warning("检测范围 CircleShape2D: radius=%.0f  (来自 config: %.0f)" % [
			detect_shape.radius, SOLDIER_CFG.detection_radius])

	# ── 攻击状态时的 Hitbox ──
	push_warning("")
	push_warning("=== 切换到 Attack 状态 ===")
	e._sm.transition_to("Attack")
	await get_tree().process_frame
	push_warning("当前状态: %s" % e._sm.get_current_state_name())
	push_warning("Hitbox monitoring=%s  damage=%.0f  hitbox.shape.disabled=%s" % [
		e._hitbox.monitoring, e._hitbox.damage, hit_shape_node.disabled])

	# 等 Hitbox 关闭
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	push_warning("3帧后 Hitbox monitoring=%s  disabled=%s" % [
		e._hitbox.monitoring, hit_shape_node.disabled])

	# ── 断言关键值 ──
	assert_eq(body_shape.size, SOLDIER_CFG.collision_size, "碰撞盒 size 应与 config 一致")
	assert_eq(hurt_shape.size, SOLDIER_CFG.hurtbox_size, "受击盒 size 应与 config 一致")
	assert_eq(detect_shape.radius, SOLDIER_CFG.detection_radius, "检测半径应与 config 一致")
	assert_eq(hurtbox.collision_layer, 2, "受击盒应在 layer 2")
	assert_eq(hitbox.collision_mask, 2, "攻击盒应检测 layer 2（受击盒）")
	assert_eq(SOLDIER_CFG.ranged, false, "soldier 应为近战")

	# ── 攻击状态验证 ──
	assert_eq(e._hitbox.damage, SOLDIER_CFG.attack, "Hitbox 伤害=config.attack")
	assert_true(e._hitbox.monitoring, "攻击时 Hitbox 应开启")
