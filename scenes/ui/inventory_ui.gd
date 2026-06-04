extends CanvasLayer

## 背包UI — 按 I 开关，点击物品选中，点击装备槽装备

const SLOT_SCENE = preload("res://scenes/ui/inventory_slot.tscn")

@onready var _backdrop: ColorRect = $Backdrop
@onready var _grid: GridContainer = $Backdrop/Panel/ItemScroll/ItemGrid
@onready var _weapon_lbl: Label = $Backdrop/Panel/EquipPanel/WeaponSlot/WeaponLabel
@onready var _armor_lbl: Label = $Backdrop/Panel/EquipPanel/ArmorSlot/ArmorLabel
@onready var _acc_lbl: Label = $Backdrop/Panel/EquipPanel/AccessorySlot/AccLabel

var _is_open: bool = false
var _selected_item_id: String = ""

func _ready():
	process_mode = PROCESS_MODE_WHEN_PAUSED
	set_process(false)  # 不需要 _process — 输入由 _unhandled_input 处理
	_backdrop.visible = false
	InventoryManager.inventory_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle()

var _was_paused_before: bool = false

func toggle() -> void:
	_is_open = not _is_open
	if _is_open:
		_selected_item_id = ""
		_refresh()
		_backdrop.visible = true
		_was_paused_before = get_tree().paused
		get_tree().paused = true
	else:
		_backdrop.visible = false
		if not _was_paused_before:
			get_tree().paused = false

# ── 装备槽点击（从 tscn 的 EquipBtn 触发） ──

func _on_weapon_clicked():
	_try_equip_selected(Enums.EquipSlot.WEAPON)

func _on_armor_clicked():
	_try_equip_selected(Enums.EquipSlot.ARMOR)

func _on_accessory_clicked():
	_try_equip_selected(Enums.EquipSlot.ACCESSORY)

# ── 刷新 ──

func _refresh():
	_refresh_items()
	_refresh_equipment()

func _refresh_items():
	for child in _grid.get_children():
		child.queue_free()

	_grid.columns = 4
	var items = InventoryManager.get_all_items_display()
	if items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "（背包为空）"
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.custom_minimum_size = Vector2(240, 36)
		_grid.add_child(empty_lbl)
		return

	for item in items:
		var slot = SLOT_SCENE.instantiate()
		_grid.add_child(slot)
		slot.setup(item.id, item.name, item.amount, item.color)
		if item.id == _selected_item_id:
			slot.select()
		slot.slot_selected.connect(_on_slot_selected)

func _on_slot_selected(item_id: String) -> void:
	for child in _grid.get_children():
		if child is InventorySlot:
			if child.item_id == item_id:
				child.select()
			else:
				child.deselect()
	_selected_item_id = item_id

func _refresh_equipment():
	var wid = InventoryManager.get_equipped_item(Enums.EquipSlot.WEAPON)
	var aid = InventoryManager.get_equipped_item(Enums.EquipSlot.ARMOR)
	var acc = InventoryManager.get_equipped_item(Enums.EquipSlot.ACCESSORY)
	_weapon_lbl.text = "武器: " + (InventoryManager.get_item_name(wid) if not wid.is_empty() else "空")
	_armor_lbl.text = "护甲: " + (InventoryManager.get_item_name(aid) if not aid.is_empty() else "空")
	_acc_lbl.text = "饰品: " + (InventoryManager.get_item_name(acc) if not acc.is_empty() else "空")

func _try_equip_selected(slot: int):
	if _selected_item_id.is_empty():
		return
	var ok = InventoryManager.equip(_selected_item_id, slot)
	if ok:
		_selected_item_id = ""
