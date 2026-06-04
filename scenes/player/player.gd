class_name Player
extends CharacterBody2D


@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 780.0
@export var coyote_time: float = 0.12
@export var attack_cooldown: float = 0.25

var facing_direction: int = 1
var entity_id: int = -1
var jumps_used: int = 0
var invulnerable: bool = false
var shield_active: bool = false
var shield_duration: float = 0.0
var shield_damage_reduction: float = 0.0

var attack_cooldown_timer: float = 0.0

var _coyote_timer: float = 0.0
var _gravity: float

@onready var _sm: StateMachine = $StateMachine
@onready var _input: InputHandler = $Movement/InputHandler
@onready var _visual: VisualController = $Visuals/VisualController
@onready var _anim: AnimationPlayer = $Visuals/AnimationPlayer
@onready var _collision_shape: CollisionShape2D = $BodyShape
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _hitbox: HitboxComponent = $Hitbox

func _ready():
	_gravity = gravity if gravity > 0.0 else ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	_gravity = abs(_gravity)
	entity_id = WorldManager.register_player(self)
	_hurtbox.entity_id = entity_id
	_hitbox.caster_id = entity_id
	_hitbox.monitoring = false
	floor_block_on_wall = false
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(8.0)
	add_to_group("player")
	if not _sm.current_state:
		_sm.init("Idle")

func _physics_process(delta: float):
	velocity.y += _gravity * delta

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if shield_active:
		shield_duration -= delta
		if shield_duration <= 0.0:
			shield_active = false
			invulnerable = false
			shield_damage_reduction = 0.0

func can_coyote_jump() -> bool:
	return _coyote_timer > 0.0

func consume_coyote():
	_coyote_timer = 0.0

func get_stat(stat_name: String, _default: float = 0.0) -> float:
	if DataManager and DataManager.player_data and DataManager.player_data.attributes.has(stat_name):
		return DataManager.player_data.attributes[stat_name]
	match stat_name:
		"max_hp":
			return 100.0
		"hp":
			return 100.0
		"attack":
			return 10.0
		"defense":
			return 5.0
		"chakra":
			return 50.0
		"max_chakra":
			return 50.0
	return _default

func enable_hitbox(duration: float = 0.3):
	_hitbox.reset()
	_hitbox.monitoring = true
	_hitbox.get_node("HitboxShape").disabled = false
	await get_tree().create_timer(duration).timeout
	_hitbox.monitoring = false
	_hitbox.get_node("HitboxShape").disabled = true

func take_damage(final_damage: float, _caster_id: int, _data_packet: Dictionary):
	if invulnerable:
		return
	if DataManager.player_data and DataManager.player_data.attributes.has("hp"):
		if DataManager.player_data.attributes["hp"] <= 0.0:
			_sm.transition_to("Die")
			return
	_sm.transition_to("Hurt", {"knockback": Vector2(final_damage * 10 * -facing_direction, -100)})

func set_facing(direction: int):
	facing_direction = direction
	$Visuals/Sprite2D.scale.x = abs($Visuals/Sprite2D.scale.x) * direction
	$Hitbox/HitboxShape.position.x = abs($Hitbox/HitboxShape.position.x) * direction
	queue_redraw()

func _draw():
	var dir = facing_direction
	var hbs = _hitbox.get_node("HitboxShape")
	var h_size = (hbs.shape as RectangleShape2D).size
	var h_pos = hbs.position
	draw_rect(Rect2(h_pos - h_size / 2, h_size), Color(0, 1, 0, 0.7), false, 2.0)
	var hurbs = _hurtbox.get_node("HurtboxShape")
	var u_size = (hurbs.shape as RectangleShape2D).size
	draw_rect(Rect2(-u_size / 2, u_size), Color(0.2, 0.6, 1, 0.5), false, 1.5)
	draw_circle(Vector2(dir * 14, 0), 2, Color(1, 0.2, 0.2))

func apply_shield(duration: float, damage_reduction: float):
	shield_active = true
	shield_duration = duration
	shield_damage_reduction = damage_reduction
	invulnerable = true

func apply_knockback(force: Vector2):
	velocity += force

func _anim_playing(anim_name: String) -> bool:
	if not _anim:
		return false
	return _anim.is_playing() and _anim.current_animation == anim_name
