class_name InventoryBackend
extends RefCounted

## 背包后端 — 纯逻辑层（RefCounted，无 Node 依赖）
## 设计：每种物品占一个槽位，同种物品堆叠到 max_stack_cache 上限。
## 注意：同一 item_id 只允许一个堆叠条目；堆满后多余物品返回 leftover。

const DEFAULT_CAPACITY: int = 30

var items: Dictionary[String, Dictionary] = {}
var equipment: Dictionary[int, String] = {}
var max_stack_cache: Dictionary[String, int] = {}
var capacity: int = DEFAULT_CAPACITY


## 添加物品，返回未能放入的剩余数量（0 = 全部放入）
func add_item(item_id: String, amount: int) -> int:
	if amount <= 0:
		push_warning("InventoryBackend.add_item: amount <= 0 (", amount, ") for ", item_id)
		return 0
	var max_st: int = max_stack_cache.get(item_id, 99)
	var remaining: int = amount

	# 先填已有堆叠
	for id in items:
		if remaining <= 0:
			break
		if id == item_id:
			var current: int = items[id].amount
			if current < max_st:
				var add: int = mini(remaining, max_st - current)
				items[id].amount += add
				remaining -= add

	# 同一 item_id 只允许一个堆叠 — 堆满后不创建新条目
	while remaining > 0 and _unique_item_count() < capacity:
		if items.has(item_id):
			break
		var add: int = mini(remaining, max_st)
		items[item_id] = {"amount": add, "data": {}}
		remaining -= add

	return remaining


## 返回不同物品种类数（每种占一槽）
func _unique_item_count() -> int:
	return items.size()


## 移除物品，成功返回 true
func remove_item(item_id: String, amount: int) -> bool:
	if amount <= 0:
		push_warning("InventoryBackend.remove_item: amount <= 0 (", amount, ") for ", item_id)
		return false
	if not items.has(item_id) or items[item_id].amount < amount:
		return false
	items[item_id].amount -= amount
	if items[item_id].amount <= 0:
		items.erase(item_id)
	return true


func get_item_count(item_id: String) -> int:
	if not items.has(item_id):
		return 0
	return items[item_id].amount


func use_item(item_id: String) -> bool:
	if not items.has(item_id) or items[item_id].amount < 1:
		return false
	var ok := remove_item(item_id, 1)
	if ok:
		EventBus.item_used.emit(item_id)
	return ok


## 装备物品到槽位。若槽位已被占用，旧装备退回背包。
## 退回失败（背包满）时拒绝换装，返回 false。
func equip(item_id: String, slot: int) -> bool:
	if not items.has(item_id) or items[item_id].amount < 1:
		return false
	# 如果该槽已有装备，先尝试退回
	if equipment.has(slot):
		var old_id: String = equipment[slot]
		var leftover: int = add_item(old_id, 1)
		if leftover > 0:
			# 背包满，无法退回旧装备 → 拒绝换装
			return false
	equipment[slot] = item_id
	remove_item(item_id, 1)
	return true


func unequip(slot: int) -> String:
	var item_id: String = equipment.get(slot, "")
	if not item_id.is_empty():
		equipment.erase(slot)
		add_item(item_id, 1)
	return item_id


func get_equipped_item(slot: int) -> String:
	return equipment.get(slot, "")


func get_all_equipped() -> Array[String]:
	var result: Array[String] = []
	for item_id in equipment.values():
		result.append(item_id)
	return result


func cache_max_stack(item_id: String, max_st: int) -> void:
	max_stack_cache[item_id] = max_st


## 收集所有已装备槽位信息，返回 [{slot, item_id}]
## 实际的 AttributeMod 由调用方通过 item_defs 查表解析
func get_equipped_mods() -> Array[Dictionary]:
	var mods: Array[Dictionary] = []
	for slot in equipment:
		var item_id: String = equipment[slot]
		mods.append({"slot": slot, "item_id": item_id})
	return mods
