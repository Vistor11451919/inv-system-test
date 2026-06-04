extends GutTest

## 子弹系统单元测试
## 覆盖: 平射 / 追踪 / 碰撞伤害

const PROJECTILE_SCENE = preload("res://scenes/common/projectile.tscn")

func _frames(n: int = 1):
	for _i in range(n):
		await get_tree().physics_frame

# ── 辅助 ──

func _make_projectile(pos: Vector2 = Vector2.ZERO) -> Projectile:
	var p = PROJECTILE_SCENE.instantiate()
	p.global_position = pos
	add_child_autofree(p)
	return p

func _make_target(pos: Vector2 = Vector2(200, 0)) -> Node2D:
	var t = Node2D.new()
	t.global_position = pos
	add_child_autofree(t)
	return t

# =============================================================================
# 1. 平射（默认行为）
# =============================================================================

func test_projectile_moves_in_launch_direction():
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.RIGHT, 300.0, 1, 10.0)
	await _frames(15)  # 15 frames = ~0.25s, speed 300 → ~75px
	assert_gt(proj.global_position.x, 50.0, "平射子弹应向右移动")
	assert_almost_eq(proj.global_position.y, 0.0, 2.0, "平射子弹 Y 应几乎不动")

func test_projectile_launched_left_flips_sprite():
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.LEFT, 300.0, 1, 10.0)
	await _frames(15)
	assert_lt(proj.global_position.x, -50.0, "向左发射应向左移动")

func test_projectile_speed_affects_movement():
	var fast = _make_projectile(Vector2.ZERO)
	fast.launch(Vector2.RIGHT, 400.0, 1, 10.0)
	await _frames(10)
	var fast_x = fast.global_position.x

	var slow = _make_projectile(Vector2.ZERO)
	slow.launch(Vector2.RIGHT, 100.0, 1, 10.0)
	await _frames(10)
	var slow_x = slow.global_position.x

	assert_gt(fast_x, slow_x * 2, "高速子弹应比低速子弹移动更远")

# =============================================================================
# 2. 追踪（homing）
# =============================================================================

func test_homing_projectile_turns_toward_target():
	var proj = _make_projectile(Vector2.ZERO)
	var target = _make_target(Vector2(200, 100))  # 目标在右下

	# 向右上发射 → 应转向右下跟踪目标
	proj.launch(Vector2(1, -1).normalized(), 300.0, 1, 10.0, target, 8.0)
	await _frames(30)

	# 追踪弹应已从向上转向为向右下
	assert_gt(proj.global_position.x, 60.0, "追踪弹应收敛到目标 X 方向")
	assert_gt(proj.global_position.y, 0.0, "追踪弹从 Y 负转向 Y 正")

func test_homing_projectile_follows_moving_target():
	var proj = _make_projectile(Vector2.ZERO)
	var target = _make_target(Vector2(120, 0))

	proj.launch(Vector2.RIGHT, 250.0, 1, 10.0, target, 6.0)
	await _frames(10)

	# 目标移动到下方
	target.global_position = Vector2(120, 80)
	await _frames(25)

	assert_gt(proj.global_position.y, 30.0, "追踪弹应跟随目标下移")

func test_homing_projectile_different_strength():
	# 弱追踪应向目标方向缓慢偏转
	var weak = _make_projectile(Vector2.ZERO)
	var t1 = _make_target(Vector2(150, 100))
	weak.launch(Vector2.RIGHT, 250.0, 1, 10.0, t1, 0.5)
	await _frames(15)
	var weak_y = weak.global_position.y  # 偏转慢，Y 接近 0

	# 强追踪应显著转向目标
	var strong = _make_projectile(Vector2.ZERO)
	var t2 = _make_target(Vector2(150, 100))
	strong.launch(Vector2.RIGHT, 250.0, 1, 10.0, t2, 10.0)
	await _frames(15)
	var strong_y = strong.global_position.y  # 偏转快，Y 显著增加

	assert_gt(strong_y, weak_y + 10, "强追踪应比弱追踪更早转向目标")

func test_no_homing_when_target_null():
	"""不传 target → 平射，不论 homing_strength"""
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.UP, 300.0, 1, 10.0, null, 10.0)
	await _frames(20)

	assert_lt(proj.global_position.y, -80.0, "无 target 时即使 homing_strength 很大也应继续向上")
	assert_almost_eq(proj.global_position.x, 0.0, 2.0, "X 不应移动")

# =============================================================================
# 3. 颜色区分
# =============================================================================

func test_homing_projectile_orange_color():
	var proj = _make_projectile(Vector2.ZERO)
	var target = _make_target(Vector2(100, 0))
	proj.launch(Vector2.RIGHT, 100.0, 1, 10.0, target, 2.0)
	await _frames(2)
	assert_eq(proj._sprite.self_modulate, Color(1, 0.5, 0.0, 1),
		"追踪弹应为橙色")

func test_straight_projectile_yellow_color():
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.RIGHT, 100.0, 1, 10.0)
	await _frames(2)
	assert_eq(proj._sprite.self_modulate, Color(1, 0.8, 0.2, 1),
		"平射弹应为黄色")

# =============================================================================
# 4. 碰撞与消失
# =============================================================================

func test_projectile_hit_any_despawns():
	"""撞到任意对象（包括 null/wall）→ 子弹消失"""
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.RIGHT, 100.0, 1, 10.0)
	await _frames(2)
	var id = proj.get_instance_id()
	proj._on_hit(null)  # null 碰撞 → 应 despawn
	await _frames(2)
	assert_false(is_instance_valid(proj), "碰撞后子弹应消失")

func test_projectile_hit_twice_ignored():
	"""第二次碰撞不重复处理"""
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.RIGHT, 100.0, 1, 10.0)
	proj._hit_already = true
	proj._on_hit(null)
	assert_true(is_instance_valid(proj), "已标记 hit 不应再次销毁")

func test_projectile_piercing_passes_through():
	"""piercing=true → 碰撞不消失（穿墙弹）"""
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.RIGHT, 100.0, 1, 10.0, null, 2.0, true)  # piercing!
	await _frames(2)
	proj._on_hit(null)
	assert_true(is_instance_valid(proj), "piercing 弹碰撞后不应消失")
	assert_true(proj._hit_already, "piercing 弹仍应标记 hit 防重复伤害")

func test_projectile_piercing_only_blocks_despawn():
	"""piercing 弹撞墙不消失但标记 _hit_already，后续再撞墙不重复标记"""
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.RIGHT, 100.0, 1, 10.0, null, 2.0, true)
	await _frames(2)
	proj._on_hit(null)   # 第一次碰撞 → _hit_already=true, 但保留
	var pos1 = proj.global_position
	proj._on_hit(null)   # 第二次碰撞 → _hit_already=true → 直接 return
	var pos2 = proj.global_position
	assert_eq(pos1, pos2, "第二次碰撞不应触发任何逻辑")

func test_projectile_despawn_cleans_up():
	"""_despawn 后不再处理物理"""
	var proj = _make_projectile(Vector2.ZERO)
	proj.launch(Vector2.RIGHT, 100.0, 1, 10.0)
	proj._despawn()
	await _frames(5)
	assert_false(is_instance_valid(proj), "_despawn 后子弹应被销毁")

# =============================================================================
# 5. 碰撞掩码（场景层配置）
# =============================================================================

func test_projectile_collision_mask_includes_walls():
	"""子弹碰撞掩码应包含层 1（墙体）和层 2（受击盒）"""
	var proj = _make_projectile(Vector2.ZERO)
	assert_eq(proj.collision_mask, 3, "collision_mask 应为 3（bit1 墙 + bit2 受击）")
