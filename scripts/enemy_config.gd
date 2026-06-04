class_name EnemyConfig
extends Resource

## 唯一标识
@export var enemy_id: String = ""
## 显示名称
@export var display_name: String = ""

## 基础属性
@export var max_hp: float = 50.0
@export var attack: float = 10.0
@export var defense: float = 5.0
@export var gravity: float = 980.0

## true=远程(发射抛射物), false=近战(命中框)
@export var ranged: bool = false

## 索敌范围（像素）— 玩家进入此范围后转向玩家
@export var detection_radius: float = 200.0
## 攻击范围（像素）— 玩家在此范围内时发动攻击
@export var attack_radius: float = 40.0
## 攻击冷却（秒）
@export var attack_cooldown: float = 1.5

## 远程攻击参数
@export var projectile_scene: PackedScene = null
@export var projectile_speed: float = 300.0

## 子弹是否追踪玩家（homing）
@export var homing: bool = false
## 追踪强度（转向速率，越大转弯越猛）
@export var homing_strength: float = 2.0

## 伤害公式
@export var damage_formula_id: String = "default"

## 忍术攻击 — 配置后敌人使用此忍术代替硬编码近战/远程
@export var ninja_art: Resource = null
@export var ninja_arts: Array[Resource] = []

## 巡逻路点（空列表 = 站桩）
@export var patrol_points: Array[Vector2] = []
## 到达路点后停留时间（秒）
@export var patrol_pause: float = 1.0
## 巡逻移动速度
@export var patrol_speed: float = 60.0
## 追击移动速度
@export var chase_speed: float = 100.0

## 受击无敌时间（秒）
@export var invulnerability_time: float = 0.3
## 死亡延迟（秒）
@export var death_delay: float = 0.5

## 占位颜色（_make_placeholder 用）
@export var placeholder_color: Color = Color(0.5, 0.5, 0.5)

## 视觉
@export var sprite_texture: Texture2D = null
@export var sprite_scale: Vector2 = Vector2(1, 1)
@export var sprite_offset: Vector2 = Vector2.ZERO
## 碰撞盒大小
@export var collision_size: Vector2 = Vector2(24, 40)
## 受击盒大小
@export var hurtbox_size: Vector2 = Vector2(28, 44)
