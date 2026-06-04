extends Node

## InventoryManager — 背包测试 autoload
## 持有 InventoryBackend 实例 + 物品定义，供 UI 和测试场景使用

signal inventory_changed

var backend: InventoryBackend
var item_defs: Dictionary = {}  # item_id → {name, desc, color}

func _ready():
	backend = InventoryBackend.new()
	_register_test_items()

func _register_test_items():
	var items = {
		"potion_hp":    {"name": "HP 药水",  "desc": "恢复 50 HP", "color": Color(1, 0.3, 0.3)},
		"potion_chakra":{"name": "查克拉药水","desc": "恢复 30 查克拉", "color": Color(0.3, 0.5, 1)},
		"weapon_katana":{"name": "刀",        "desc": "一把锋利的刀",  "color": Color(0.8, 0.8, 0.8)},
		"weapon_axe":   {"name": "斧头",      "desc": "沉重的战斧",   "color": Color(0.6, 0.4, 0.2)},
		"armor_leather":{"name": "皮甲",      "desc": "轻便的皮甲",   "color": Color(0.5, 0.3, 0.1)},
		"accessory_ring":{"name": "戒指",     "desc": "古老的金戒指", "color": Color(1, 0.8, 0.2)},
		"ore":          {"name": "矿石",      "desc": "闪亮的矿石",   "color": Color(0.4, 0.6, 0.8)},
	}
	for id in items:
		var d = items[id]
		item_defs[id] = d
		backend.cache_max_stack(id, 10 if "potion" in id or id == "ore" else 1)

# ── 后端代理方法 ──

func add_item(item_id: String, amount: int = 1) -> int:
	var leftover = backend.add_item(item_id, amount)
	inventory_changed.emit()
	EventBus.inventory_changed.emit()
	return leftover

func remove_item(item_id: String, amount: int = 1) -> bool:
	var ok = backend.remove_item(item_id, amount)
	if ok:
		inventory_changed.emit()
		EventBus.inventory_changed.emit()
	return ok

func use_item(item_id: String) -> bool:
	var ok = backend.use_item(item_id)
	if ok:
		inventory_changed.emit()
		EventBus.inventory_changed.emit()
	return ok

func equip(item_id: String, slot: int) -> bool:
	var ok = backend.equip(item_id, slot)
	if ok:
		inventory_changed.emit()
		EventBus.inventory_changed.emit()
	return ok

func unequip(slot: int) -> String:
	var item_id = backend.unequip(slot)
	if !item_id.is_empty():
		inventory_changed.emit()
		EventBus.inventory_changed.emit()
	return item_id

func get_item_count(item_id: String) -> int:
	return backend.get_item_count(item_id)

func get_equipped_item(slot: int) -> String:
	return backend.get_equipped_item(slot)

# ── UI 查询 ──

## 返回 [{id, name, desc, color, amount}] 供 UI 展示
func get_all_items_display() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in backend.items:
		var def = item_defs.get(item_id, {"name": item_id, "desc": "", "color": Color.WHITE})
		result.append({
			"id": item_id,
			"name": def.name,
			"desc": def.desc,
			"color": def.color,
			"amount": backend.items[item_id].amount,
		})
	return result

## 获取所有已定义物品的 ID 列表（用于测试添加）
func get_all_item_ids() -> Array:
	return item_defs.keys()

## 获取物品显示名
func get_item_name(item_id: String) -> String:
	var def = item_defs.get(item_id)
	return def.name if def else item_id
