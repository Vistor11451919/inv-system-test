class_name BossPhaseConfig
extends Resource

@export var phase_name: String = ""
@export var health_threshold: float = 0.5
@export var transition_cutscene: CutsceneResource = null
@export var new_attack_patterns: Array[String] = []
@export var weakness_element: String = ""
@export var invulnerable: bool = false
@export var move_speed_multiplier: float = 1.0
@export var attack_rate_multiplier: float = 1.0

