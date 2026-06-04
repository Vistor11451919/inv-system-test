# Inv System Test

Godot 4.6 背包系统测试项目（从 enemy-ai-test 模板创建）。

## 快速命令

```bash
cd "E:/gme/tests/inv-system-test"
# 编译检查
godot --path "." --headless --quit
# 运行全部 ~151 个测试
godot --path "." --headless -s addons/gut/gut_cmdln.gd -gconfig=res://test/gut_config.json
# 打开编辑器
godot --path "." --editor
```

## 项目结构

```
inv-system-test/
├── autoloads/
│   ├── inventory_manager.gd # 背包管理器 autoload（持有 InventoryBackend）
│   └── ...
├── scripts/
│   ├── enums.gd               # Enums（EquipSlot 等枚举）
│   └── inventory_backend.gd   # 背包后端逻辑（InventoryBackend）
├── scenes/
│   ├── ui/
│   │   ├── inventory_ui.tscn/.gd  # 背包 UI 面板（按 I 开关）
│   │   └── item_adder.tscn        # 测试物品添加按钮（左上角）
│   └── ...
├── data/               # 敌人配置数据（来自模板）
├── test/
│   └── unit/
│       ├── test_inventory_backend.gd  # 背包测试（19 tests）
│       ├── test_enemy_*.gd           # 敌人 AI 测试（来自模板）
│       └── ...
└── addons/gut/         # GUT 测试插件
```

## 背包系统

后端逻辑：`scripts/inventory_backend.gd`（class_name InventoryBackend）

### 设计说明

- **每种物品一个堆叠**：同一 `item_id` 只创建一条条目，堆到 `max_stack_cache` 上限后多余物品返回 `leftover`
- **换装保护**：背包满时 `equip()` 会拒绝换装（返回 false），旧装备不会丢失

### API

| 方法 | 功能 |
|------|------|
| `add_item(id, amount)` | 添加物品，返回未放入数量 |
| `remove_item(id, amount)` | 移除物品，返回成功/失败 |
| `get_item_count(id)` | 查询数量 |
| `use_item(id)` | 使用物品（触发 EventBus.item_used） |
| `equip(id, slot)` | 装备到槽位（满仓时拒绝换装） |
| `unequip(slot)` | 卸下装备，返回 item_id |
| `get_equipped_item(slot)` | 查询槽位装备 |
| `get_all_equipped()` | 获取所有已装备 ID |
| `cache_max_stack(id, max)` | 设置堆叠上限 |

### 背包测试（19 tests）

| 测试 | 覆盖范围 |
|------|---------|
| `test_add_item_new` / `test_add_item_overflow` | 添加物品、堆叠超限 |
| `test_remove_item_partial` / `test_remove_item_nonexistent` | 移除物品、不存在物品 |
| `test_use_item` / `test_use_item_empty` / `test_use_item_after_partial_use` | 使用物品 |
| `test_equip_consumes_item` / `test_equip_nonexistent` / `test_equip_empty_inventory` | 装备系统 |
| `test_unequip_returns_item` / `test_unequip_empty_slot` | 卸下装备 |
| `test_equip_replaces_occupied_slot` | 装备替换旧物品回包 |
| `test_get_all_equipped` / `test_get_equipped_mods_returns_slots` | 查询已装备 |
| `test_default_max_stack_is_99` / 边缘参数 | 默认堆叠、负值/零值 |
| `test_use_then_equip` | 组合操作 |

## 背包 UI 测试

运行 `test_level.tscn` 进入测试关卡：

- **左上角按钮**：点击添加测试物品到背包
- **按 I**：开关背包面板，显示物品和装备
- **点击物品后点击武器/护甲/饰品按钮**：装备到对应槽位
- 背包面板自动响应 InventoryManager.inventory_changed 信号刷新

## 与 enemy-ai-test 的关系

本项目基于 enemy-ai-test 模板创建，共享敌人 AI、状态机、忍术等系统代码。v1.1.0 同步了 enemy-ai-test 的忍术接口和配置字段更新。
