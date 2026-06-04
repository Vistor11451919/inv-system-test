extends Node

## 背包监视器 — 观察物品添加/移除/使用/装备变化并打印日志

var _last_items_state: Dictionary = {}

func _ready():
	if InventoryManager.inventory_changed.is_connected(_on_inventory_changed):
		InventoryManager.inventory_changed.disconnect(_on_inventory_changed)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	print("═══════════════════════════════════════════")
	print("  背包监视器启动")
	print("  物品槽: %d  已注册物品: %d" % [InventoryManager.backend.capacity, InventoryManager.get_all_item_ids().size()])
	print("───────────────────────────────────────────")
	_snapshot()
	_print_inventory()

func _snapshot():
	_last_items_state = {}
	for item_id in InventoryManager.backend.items:
		_last_items_state[item_id] = InventoryManager.backend.items[item_id].amount

func _on_inventory_changed():
	var new_state: Dictionary = {}
	for item_id in InventoryManager.backend.items:
		new_state[item_id] = InventoryManager.backend.items[item_id].amount

	# 检查新增
	for id in new_state:
		var old_amt = _last_items_state.get(id, 0)
		var new_amt = new_state[id]
		if new_amt > old_amt:
			var name = InventoryManager.get_item_name(id)
			print("  [添加] %s x%d" % [name, new_amt - old_amt])
		elif new_amt < old_amt:
			var name = InventoryManager.get_item_name(id)
			print("  [移除] %s x%d" % [name, old_amt - new_amt])

	# 检查消失的物品
	for id in _last_items_state:
		if not new_state.has(id):
			var name = InventoryManager.get_item_name(id)
			print("  [耗尽] %s" % name)

	# 检查装备变化
	var eq_changed = false
	var eq_info = ""
	for slot in [Enums.EquipSlot.WEAPON, Enums.EquipSlot.ARMOR, Enums.EquipSlot.ACCESSORY]:
		var item_id = InventoryManager.get_equipped_item(slot)
		if not item_id.is_empty():
			eq_info += "  slot%d: %s" % [slot, InventoryManager.get_item_name(item_id)]
	if not eq_info.is_empty():
		print("  [装备] %s" % eq_info.strip_edges())

	_snapshot()
	print_inventory_if_changed()

func print_inventory_if_changed():
	var lines = []
	for item_id in InventoryManager.backend.items:
		var amt = InventoryManager.backend.items[item_id].amount
		if amt > 0:
			var name = InventoryManager.get_item_name(item_id)
			lines.append("%s x%d" % [name, amt])
	if lines.is_empty():
		print("  背包: （空）")
	else:
		print("  背包: %s" % ", ".join(lines))

func _print_inventory():
	var lines = []
	for item_id in InventoryManager.backend.items:
		var amt = InventoryManager.backend.items[item_id].amount
		if amt > 0:
			var name = InventoryManager.get_item_name(item_id)
			lines.append("%s x%d" % [name, amt])
	if lines.is_empty():
		print("  背包: （空）")
	else:
		print("  初始背包: %s" % ", ".join(lines))
