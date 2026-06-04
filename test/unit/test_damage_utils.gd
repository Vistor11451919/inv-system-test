extends GutTest

## 伤害公式单元测试
## 覆盖: default / linear / percent_reduction 三种公式 + 暴击 + 元素抗性 + 边界条件

const MOCK_ENTITY = preload("res://test/fixtures/mock_entity.gd")

# ── 测试辅助 ──

func _make_caster(atk: float = 10.0, crit_rate: float = 0.0, crit_dmg: float = 1.5) -> int:
	var e = MOCK_ENTITY.new()
	e.set_stat("attack", atk)
	e.set_stat("crit_rate", crit_rate)
	e.set_stat("crit_damage", crit_dmg)
	add_child_autofree(e)
	return WorldManager.register_entity(e)

func _make_target(defense: float = 5.0, hp: float = 100.0, element_resist: String = "", resist_val: float = 0.0) -> int:
	var e = MOCK_ENTITY.new()
	e.set_stat("defense", defense)
	e.set_stat("hp", hp)
	e.set_stat("max_hp", hp)
	if element_resist:
		e.set_stat("resist_" + element_resist, resist_val)
	add_child_autofree(e)
	return WorldManager.register_entity(e)

func _resolve(caster_id: int, target_id: int, base_dmg: float = 10.0, formula: String = "default", data: Dictionary = {}) -> float:
	return DamageUtils.resolve_damage(caster_id, target_id, base_dmg, data, formula)

# =============================================================================
# 1. default 公式
# =============================================================================

func test_default_formula_reduces_by_defense():
	var caster = _make_caster(10.0)
	var target = _make_target(5.0)
	# base=10, atk=10, def=5 → 10 * 10/(10+5) = 10 * 0.666... = 6.66 → floor → 6.0
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 6.0, "base=10 atk=10 def=5 → default → 6")

func test_default_formula_zero_defense():
	var caster = _make_caster(10.0)
	var target = _make_target(0.0)
	# base=10, atk=10, def=0 → 10 * 10/10 = 10
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 10.0, "def=0 → 全额伤害")

func test_default_formula_high_defense():
	var caster = _make_caster(10.0)
	var target = _make_target(90.0)
	# base=10, atk=10, def=90 → 10 * 10/100 = 1
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 1.0, "def 很高 → 最小伤害 1")

func test_default_formula_zero_attack():
	var caster = _make_caster(0.0)
	var target = _make_target(5.0)
	# base=10, atk=0, def=5 → 10 * 0/5 = 0... 但是 max(1, floor(0)) = 1
	# 等等，atk=0 而公式是 max(atk+def, 1) = max(5, 1) = 5; 10 * 0/5 = 0 → max(1, 0) = 1
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 1.0, "atk=0 → 最小伤害 1")

func test_default_zero_base_damage():
	var caster = _make_caster(10.0)
	var target = _make_target(5.0)
	# base=0, atk=10, def=5 → 0 * 10/15 = 0 → max(1, 0) = 1
	var dmg = _resolve(caster, target, 0.0, "default")
	assert_eq(dmg, 1.0, "base=0 → 最小伤害 1")

# =============================================================================
# 2. linear 公式
# =============================================================================

func test_linear_formula():
	var caster = _make_caster(10.0)
	var target = _make_target(5.0)
	# base + atk - def = 10 + 10 - 5 = 15
	var dmg = _resolve(caster, target, 10.0, "linear")
	assert_eq(dmg, 15.0, "linear: 10+10-5 = 15")

func test_linear_damage_min_one():
	var caster = _make_caster(5.0)
	var target = _make_target(20.0)
	# 10 + 5 - 20 = -5 → max(1, floor(-5)) = 1
	var dmg = _resolve(caster, target, 10.0, "linear")
	assert_eq(dmg, 1.0, "linear: 负数 → 最小伤害 1")

func test_linear_no_attack():
	var caster = _make_caster(0.0)
	var target = _make_target(0.0)
	# 10 + 0 - 0 = 10
	var dmg = _resolve(caster, target, 10.0, "linear")
	assert_eq(dmg, 10.0, "linear: base 本身")

# =============================================================================
# 3. percent_reduction 公式
# =============================================================================

func test_percent_reduction_formula():
	var caster = _make_caster(10.0)
	var target = _make_target(100.0)
	# reduction = def/(def+100) = 100/200 = 0.5
	# base * atk * (1 - 0.5) = 10 * 10 * 0.5 = 50
	var dmg = _resolve(caster, target, 10.0, "percent_reduction")
	assert_eq(dmg, 50.0, "percent_reduction: 10*10*0.5=50")

func test_percent_reduction_low_defense():
	var caster = _make_caster(10.0)
	var target = _make_target(0.0)
	# reduction = 0/100 = 0
	# 10 * 10 * 1 = 100
	var dmg = _resolve(caster, target, 10.0, "percent_reduction")
	assert_eq(dmg, 100.0, "percent_reduction: def=0 → 全额")

func test_percent_reduction_min_one():
	var caster = _make_caster(0.0)
	var target = _make_target(100.0)
	# 10 * 0 * 0.5 = 0 → max(1, 0) = 1
	var dmg = _resolve(caster, target, 10.0, "percent_reduction")
	assert_eq(dmg, 1.0, "atk=0 → 最小伤害 1")

# =============================================================================
# 4. 暴击
# =============================================================================

func test_critical_hit_emits_signal():
	var caster = _make_caster(10.0, 1.0)  # 100% 暴击率
	var target = _make_target(5.0)

	watch_signals(EventBus)
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_gt(dmg, 6.0, "暴击应提高伤害")  # 否则默认是6
	assert_signal_emitted(EventBus, "crit_happened", "暴击应发射 crit_happened 信号")

func test_critical_hit_multiplication():
	var caster = _make_caster(10.0, 1.0, 2.0)  # 100% 暴击率, 2x 暴伤
	var target = _make_target(5.0)
	# default: 10 * 10/15 = 6.66 → floor 6 → * 2 = 12
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 13.0, "暴击 2x: floor(6.666*2)=13")

func test_no_critical_with_zero_rate():
	var caster = _make_caster(10.0, 0.0)  # 0% 暴击率
	var target = _make_target(5.0)

	watch_signals(EventBus)
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 6.0, "暴击率 0 → 不应暴击")
	assert_signal_not_emitted(EventBus, "crit_happened", "暴击率 0 不应发射 crit_happened")

# =============================================================================
# 5. 元素抗性
# =============================================================================

func test_element_resistance():
	var caster = _make_caster(10.0)
	var target = _make_target(5.0, 100.0, "fire", 0.5)  # 50% 火炕
	# default: 6, 元素抗性: 6 * (1-0.5) = 3
	var dmg = _resolve(caster, target, 10.0, "default", {"element": "fire"})
	assert_eq(dmg, 3.0, "火炕 50% → 伤害减半到 3")

func test_physical_element_no_resistance():
	var caster = _make_caster(10.0)
	var target = _make_target(5.0, 100.0, "fire", 0.5)  # 50% 火炕
	# physical 元素，不触发抗性
	var dmg = _resolve(caster, target, 10.0, "default", {"element": "physical"})
	assert_eq(dmg, 6.0, "物理伤害不应受元素抗性影响")

func test_different_element_resistance():
	var caster = _make_caster(10.0)
	var target = _make_target(5.0, 100.0, "ice", 0.3)  # 30% 冰炕
	var dmg = _resolve(caster, target, 10.0, "default", {"element": "fire"})
	assert_eq(dmg, 6.0, "火伤不应受冰炕影响")

# =============================================================================
# 6. 边界条件
# =============================================================================

func test_missing_caster_returns_zero():
	var target = _make_target(5.0)
	var dmg = _resolve(99999, target, 10.0)  # 不存在 caster
	assert_eq(dmg, 0.0, "caster 不存在应返回 0")

func test_missing_target_returns_zero():
	var caster = _make_caster(10.0)
	var dmg = _resolve(caster, 99999, 10.0)  # 不存在 target
	assert_eq(dmg, 0.0, "target 不存在应返回 0")

func test_both_missing_returns_zero():
	var dmg = _resolve(99999, 88888, 10.0)
	assert_eq(dmg, 0.0, "两者都不存在应返回 0")

func test_high_crit_damage():
	var caster = _make_caster(10.0, 1.0, 3.0)  # 100% 暴击率, 3x 暴伤
	var target = _make_target(5.0)
	# default: 6 * 3 = 18
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 20.0, "暴伤 3x → 20")  # floor(6.666 * 3) = floor(20) = 20

func test_default_same_atk_def():
	var caster = _make_caster(10.0)
	var target = _make_target(10.0)
	# base=10, atk=10, def=10 → 10 * 10/20 = 5
	var dmg = _resolve(caster, target, 10.0, "default")
	assert_eq(dmg, 5.0, "atk=def → 50% 伤害")
