class_name HitboxComponent
extends Area2D


@export var damage: float = 10.0
@export var caster_id: int = -1
@export var formula_id: String = "default"
@export var data_packet: Dictionary = {}

var _hit_entities: Dictionary = {}

func _ready():
	area_entered.connect(_on_area_entered)

func reset():
	_hit_entities.clear()

func _on_area_entered(area: Area2D):
	var hurtbox = area as HurtboxComponent
	if not hurtbox or hurtbox.entity_id < 0:
		return
	if hurtbox.entity_id == caster_id:
		return
	if _hit_entities.has(hurtbox.entity_id):
		return
	_hit_entities[hurtbox.entity_id] = true

	var final_damage = DamageUtils.resolve_damage(
		caster_id, hurtbox.entity_id, damage, data_packet, formula_id
	)
	if final_damage <= 0:
		return

	EventBus.damage_dealt.emit(caster_id, hurtbox.entity_id, final_damage, data_packet)
	# 对目标实体实际应用伤害（取 WorldManager 查实体，调 take_damage）
	var target = WorldManager.get_entity(hurtbox.entity_id)
	if target and target.has_method("take_damage"):
		target.take_damage(final_damage, caster_id, data_packet)
