# Changelog

## [1.1.0] — 2026-06-04

### 新增
- **跨项目同步**：从 enemy-ai-test v1.1.0 同步核心系统更新，保持两项目 API 兼容
- EnemyConfig 新增 `ninja_art` / `ninja_arts` 字段
- BossPhaseConfig 新增 `phase_ninja_arts` 字段
- BossBase 新增 `set_ninja_arts()` 方法 + `_current_ninja_arts` 变量
- BossPhaseManager 新增阶段忍术列表切换逻辑
- EnemyBase 新增完整忍术接口：`use_ninja_art()`、`cancel_ninja_art()`、`ninja_art_finished` 信号、`_res_str()`/`_res_float()` 安全包装、`_resolve_art_timeline()` 自动构建
- EventBus 信号全部添加类型标注
- Projectile 占位纹理改为 `static var` 缓存，减少高频发射内存碎片

### 修复

#### 🔴 Critical
- `inventory_backend.gd` — `equip()` 换装时 `add_item(old_id, 1)` 返回值被忽略，背包满时旧装备**静默丢失**。修复：检查 leftover，非零则拒绝换装并返回 false
- `inventory_ui.gd` — `_process()` 每帧轮询 `Input.is_action_just_pressed`，UI 关闭时也持续消耗 CPU。修复：改用 `_unhandled_input()` + `set_process(false)`
- `inventory_ui.gd` — `toggle()` 直接设置 `get_tree().paused`，与其他暂停系统冲突（外部暂停被关闭 UI 意外取消）。修复：进入时保存 `_was_paused_before`，退出时恢复
- `damage_utils.gd` — `resolve_damage()` 每次调用都 `RandomNumberGenerator.new()`，高频战斗产生大量临时对象。修复：类级别 `static var _shared_rng`
- `enemy_attack_state.gd` — `monitoring` / `disabled` 属性在 physics flushing 中直接赋值，触发 Godot 4 引擎断言/崩溃。修复：全部改用 `set_deferred()`
- `enemy_patrol_state.gd` — 浮空敌人到达路点后只清零 `velocity.x`，Y 轴速度残留在无重力状态下导致无限漂移。修复：增加 `velocity.y = 0`

#### 🟡 High
- `inventory_manager.gd` — `use_item()` 和 `unequip()` 只发射本地 `inventory_changed`，缺少 `EventBus.inventory_changed`，导致外部系统（成就、任务）收不到通知。修复：补充 EventBus 发射
- `inventory_backend.gd` — `add_item()` 对 `amount <= 0` 静默返回 0，调用方可能误用。修复：增加 `push_warning`
- `enemy_base.gd` — `_visual.get_parent().has_node("NameLabel")` 使用脆弱的跨层级引用。修复：改为 `owner.has_node()`

#### 🟢 Medium
- `inventory_backend.gd` — 全面添加类型标注（`Dictionary[String, Dictionary]`、`Dictionary[int, String]` 等）
- `inventory_manager.gd` — `get_all_items_display() -> Array` 改为 `-> Array[Dictionary]`
- `inventory_ui.gd` — `_on_slot_selected()` 双重遍历 GridContainer 合并为一次
- `inventory_ui.gd` — 装备标签三元表达式增加括号提升可读性
- `inventory_slot.gd` — 删除冗余 `_selected` 变量，`is_selected()` 直接读取 `_select_highlight.visible`
- `gut_config.json` — 移除不存在的 `res://test/integration` 目录引用

### 文档
- `inventory_backend.gd` — 顶层 docstring 明确"每种物品一个堆叠"的设计决策
- `inventory_backend.gd` — `_unique_item_count()` 重命名（原 `_slot_used` 语义模糊）

---

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
