class_name DamageUtils
extends RefCounted

static func resolve_damage(
	caster_id: int,
	target_id: int,
	base_damage: float,
	data_packet: Dictionary = {},
	formula_id: String = "default",
	rng: RandomNumberGenerator = null
) -> float:
	var caster = WorldManager.get_entity(caster_id)
	var target = WorldManager.get_entity(target_id)
	if not caster or not target:
		return 0.0

	var final: float = base_damage

	match formula_id:
		"default":
			var atk = caster.get_stat("attack", 0)
			var defense = target.get_stat("defense", 0)
			final = base_damage * atk / max(atk + defense, 1)
		"linear":
			var atk = caster.get_stat("attack", 0)
			var defense = target.get_stat("defense", 0)
			final = base_damage + atk - defense
		"percent_reduction":
			var atk = caster.get_stat("attack", 0)
			var defense = target.get_stat("defense", 0)
			var reduction = defense / (defense + 100.0)
			final = base_damage * atk * (1.0 - reduction)
		_:
			push_error("Unknown damage formula: ", formula_id)
			final = base_damage

	# 元素抗性计算
	var element: String = data_packet.get("element", "physical")
	if element != "physical":
		var target_resist: float = target.get_stat("resist_" + element, 0.0)
		final *= (1.0 - target_resist)

	# 暴击计算
	var crit_rate: float = caster.get_stat("crit_rate", 0.0)
	var rand: RandomNumberGenerator = rng if rng else RandomNumberGenerator.new()
	if crit_rate > 0.0 and rand.randf() < crit_rate:
		var crit_damage: float = caster.get_stat("crit_damage", 1.5)
		final *= crit_damage
		EventBus.crit_happened.emit(caster_id, target_id)

	return max(1.0, floor(final))
