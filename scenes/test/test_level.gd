extends Node2D

## 背包测试关卡 — 背包 UI + 物品添加 + 背包监视器

const INVENTORY_UI = preload("res://scenes/ui/inventory_ui.tscn")
const ITEM_ADDER = preload("res://scenes/ui/item_adder.tscn")
const INV_MONITOR = preload("res://scenes/test/inventory_monitor.gd")

var _inventory_ui: CanvasLayer = null

func _ready():
	AbilityRegistry.unlock_all()
	_setup_inventory_ui()
	_setup_inventory_monitor()

func _setup_inventory_ui():
	# 背包面板（按 I 开关）
	_inventory_ui = INVENTORY_UI.instantiate()
	add_child(_inventory_ui)

	# 测试物品添加按钮（左上角）
	var adder = ITEM_ADDER.instantiate()
	add_child(adder)
	adder.get_node("Bg/BtnPotion").pressed.connect(func(): InventoryManager.add_item("potion_hp", 3))
	adder.get_node("Bg/BtnChakra").pressed.connect(func(): InventoryManager.add_item("potion_chakra", 3))
	adder.get_node("Bg/BtnKatana").pressed.connect(func(): InventoryManager.add_item("weapon_katana", 1))
	adder.get_node("Bg/BtnAxe").pressed.connect(func(): InventoryManager.add_item("weapon_axe", 1))
	adder.get_node("Bg/BtnArmor").pressed.connect(func(): InventoryManager.add_item("armor_leather", 1))
	adder.get_node("Bg/BtnRing").pressed.connect(func(): InventoryManager.add_item("accessory_ring", 1))
	adder.get_node("Bg/BtnOre").pressed.connect(func(): InventoryManager.add_item("ore", 5))
	adder.get_node("Bg/BtnClear").pressed.connect(func():
		InventoryManager.backend.items.clear()
		InventoryManager.backend.equipment.clear()
		InventoryManager.inventory_changed.emit()
		EventBus.inventory_changed.emit()
	)

func _setup_inventory_monitor():
	var mon = INV_MONITOR.new()
	add_child(mon)
