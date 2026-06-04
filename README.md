# Enemy AI Test

Godot 4.6 敌人 AI 系统单元测试项目。

## 项目结构

```
enemy-ai-test/
├── autoloads/          # 全局单例（EventBus、WorldManager、CameraManager 等）
├── data/enemies/       # 5 种敌人配置资源
├── scenes/
│   ├── common/         # 通用组件（StateMachine、State、VisualController）
│   ├── enemies/        # 敌人实体 + 6 状态 + Boss 系统
│   ├── player/         # 玩家实体（测试用手操角色）
│   └── test/           # 测试关卡
├── scripts/            # 非节点类（EnemyBase、DamageUtils、Hitbox/Hurtbox 等）
├── test/
│   ├── unit/           # 单元测试（4 文件，105 测试）
│   └── gut_config.json # GUT 测试框架配置
└── addons/gut/         # GUT 测试插件
```

## 测试

```bash
# 运行全部测试
godot --path . --headless -s addons/gut/gut_cmdln.gd -gconfig=res://test/gut_config.json
```

### 测试覆盖

| 文件 | 测试数 | 覆盖范围 |
|------|--------|---------|
| `test_enemy_config.gd` | 8 | 5 种敌人配置加载 + 模板实例化 |
| `test_enemy_states.gd` | 55 | Patrol/Chase/Attack/Hurt/Die 五状态 + 转换 + 边界 |
| `test_damage_utils.gd` | 22 | 3 种伤害公式 + 暴击 + 元素抗性 |
| `test_boss_phases.gd` | 19 | Boss 阶段初始化 + 血量阈值转换 + 配置应用 |
| `test_enemy_debug.gd` | 1 | Soldier 碰撞盒/攻击盒/受击盒检测 |

## 敌人类型

| 敌人 | HP | 攻击 | 速度 | 特点 |
|------|----|------|------|------|
| Soldier | 60 | 8 | 80 | 标准近战，路点巡逻 |
| Ninja | 40 | 15 | 140 | 高速高攻低防 |
| Heavy | 200 | 25 | 慢 | 高血量坦克 |
| Archer | 40 | 12 | - | 远程投射物 |
| Floater | 30 | 10 | - | 浮空（重力=0） |

## 状态机

敌人 5 状态 FSM：

```
Patrol ──→ Chase ──→ Attack
  ↑          │          │
  │          ↓          ↓
  └──←── Patrol ←── Chase ←──
                ↑
                │
             Hurt → (stun → Chase/Patrol)
               │
               ↓
              Die
```

## 运行测试关卡

用 Godot 编辑器打开项目，运行 `scenes/test/test_level.tscn`：

- WASD 移动
- J 攻击
- K 手里剑（忍术）
- L 回血
- Shift 行走
