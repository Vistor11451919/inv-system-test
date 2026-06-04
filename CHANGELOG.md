# Changelog

## [1.0.0] — 2026-06-02

### 新增
- 105 个 GUT 单元测试，覆盖敌人 AI 全部 5 状态、伤害公式、Boss 阶段系统
- 测试文件：`test_enemy_config.gd`、`test_enemy_states.gd`、`test_damage_utils.gd`、`test_boss_phases.gd`
- Soldier 碰撞盒/攻击盒/受击盒调试测试：`test_enemy_debug.gd`
- 头顶名字标签（NameLabel），自动从 EnemyConfig 读取显示名
- 测试用 Autoload 桩（CameraManager、CutsceneManager、MapManager、CutsceneResource）
- `mock_entity.gd` 扩展，支持自定义任意 stat

### 修复

#### 🔴 Critical
- `state_machine.gd` — `_physics_process` 使用 `get_parent()` 返回 AI Node 而非 CharacterBody2D，**导致 `move_and_slide()` 永不执行，敌人完全无法移动**。修复：改用 `owner`

#### 🟡 High
- `enemy_attack_state.gd` — `_ranged_attack()` 先调 `proj.launch()` 后 `add_child()`，导致 projectile 的 `get_tree()` 为 null。修复：交换调用顺序
- `boss_phase_config.gd` — 引用不存在的 `CutsceneResource`，导致编译失败。新增桩文件解决
- `boss_base.gd` — 引用缺失的 `CameraManager`、`CutsceneManager`、`MapManager`。新增 Autoload 桩

#### 🟢 Medium
- 节点结构拍平：`Components/Hurtbox`、`Components/Hitbox`、`Components/DetectionArea`、`Visuals/Sprite2D`、`Visuals/VisualController`、`Visuals/HPLabel` 全部改为 EnemyBase 直子
- Boss 模板缺少 `HPLabel` 节点（@onready 找不到），测试中动态添加
- `atomic_effect_registry.gd` — 删除调试打印后 `else:` 分支变为空块，移除 `else` 行

### 清理
- 移除全部 `[NinjaDebug]` 调试打印（9 个文件）
- 移除 `[Dummy]`、`[GameManager]`、`[TestLevel]`、`[Player]` 调试打印
- `damage_utils.gd` 清理残留死代码
