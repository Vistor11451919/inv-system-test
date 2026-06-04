extends Node

## EventBus — 全局信号总线
## 背包测试项目扩展：inventory_changed, item_used

signal damage_dealt(caster_id: int, target_id: int, damage: float, data: Dictionary)
signal crit_happened(caster_id: int, target_id: int)
signal story_flag_changed(flag: String, value: Variant)
signal entity_health_changed(entity_id: int, old_hp: float, new_hp: float)
signal boss_phase_changed(boss_id: int, phase_name: String)
signal item_collected(item_id: String, quantity: int)
signal inventory_changed()
signal item_used(item_id: String)
