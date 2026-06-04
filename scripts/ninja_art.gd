class_name NinjaArt
extends Resource

enum Element { PHYSICAL, FIRE, WATER, WIND, LIGHTNING, EARTH, VOID }
enum Category { PROJECTILE, MELEE, HEAL, BUFF, DEBUFF, SUMMON, TRAP, TELEPORT, FIELD }

@export var art_id: String = ""
@export var art_name: String = ""
@export var icon: Texture2D
@export var element: Element = Element.PHYSICAL
@export var category: Category = Category.PROJECTILE
@export var tier: int = 1
@export var cooldown: float = 1.0
@export var chakra_cost: int = 10
@export var cast_animation: String = "ninja_art_cast"
@export var cast_time: float = 0.0
@export var hit_effect_scene: String = ""
@export var conditions: Dictionary = {}
@export var data_packet: Dictionary = {}
