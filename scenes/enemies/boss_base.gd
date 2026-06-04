class_name BossBase
extends EnemyBase

@export var boss_name: String = ""
@export var phase_manager: BossPhaseManager = null
@export var arena_lock_area: Area2D = null
@export var reward_on_defeat: Array[String] = []
@export var unlock_region_on_defeat: String = ""
@export var defeat_dialogue: CutsceneResource = null

var _has_died: bool = false
var _current_attack_patterns: Array[String] = []
var _speed_multiplier: float = 1.0
var _attack_rate_multiplier: float = 1.0
var _arena_locked: bool = false
var _blackboard: Dictionary = {}

func _ready():
	super._ready()
	if is_instance_valid(phase_manager):
		phase_manager.initialize(self)
	if boss_name.is_empty() and config:
		boss_name = config.display_name
	if _hp_label:
		_hp_label.text = "%s: %.0f/%.0f" % [boss_name, hp, max_hp]

func _update_hp_display():
	if _hp_label:
		_hp_label.text = "%s: %.0f/%.0f" % [boss_name, hp, max_hp]

func take_damage(final_damage: float, caster_id: int, data_packet: Dictionary):
	if _has_died or _invulnerable:
		return
	var pc = phase_manager.get_current_config() if is_instance_valid(phase_manager) else null
	if pc and not pc.weakness_element.is_empty():
		var element = data_packet.get("element", "")
		if element == pc.weakness_element:
			super.take_damage(final_damage * 1.5, caster_id, data_packet)
			return
	super.take_damage(final_damage, caster_id, data_packet)

func set_blackboard(key: String, value: Variant):
	_blackboard[key] = value

func get_blackboard(key: String, default_val: Variant = null):
	return _blackboard.get(key, default_val)

func set_attack_patterns(patterns: Array[String]):
	_current_attack_patterns = patterns

func set_speed_multiplier(val: float):
	_speed_multiplier = val

func set_attack_rate_multiplier(val: float):
	_attack_rate_multiplier = val

# —— 竞技场锁定 ——
func trigger_arena_lock():
	if _arena_locked:
		return
	_arena_locked = true
	if arena_lock_area:
		for child in arena_lock_area.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.disabled = false
	if defeat_dialogue:
		CutsceneManager.play(defeat_dialogue)

func _on_detection_body_entered(body: Node):
	super._on_detection_body_entered(body)
	if body.is_in_group("player") and not _has_died:
		trigger_arena_lock()

func _die():
	if _has_died:
		return
	_has_died = true
	_arena_locked = false
	GameManager.record_boss_defeated(boss_name if not boss_name.is_empty() else config.enemy_id)
	CameraManager.unlock_boss_zone()
	if not unlock_region_on_defeat.is_empty():
		MapManager.unlock_region(unlock_region_on_defeat)

func _die_cleanup():
	_die()  # 确保 Boss 击败逻辑执行（记录击败、解锁区域等）
	WorldManager.unregister_entity(entity_id)
	for item_id in reward_on_defeat:
		EventBus.item_collected.emit(item_id, 1)
	queue_free()
