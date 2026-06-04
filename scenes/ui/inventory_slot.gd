class_name InventorySlot
extends Button

## 背包物品格 — 显示物品颜色条、名称、数量，支持选中

signal slot_selected(item_id: String)

var item_id: String = ""
var item_name: String = ""
var item_amount: int = 0
var item_color: Color = Color.WHITE

var _color_bar: ColorRect
var _name_lbl: Label
var _qty_lbl: Label
var _select_highlight: ColorRect

const SLOT_W: float = 120.0
const SLOT_H: float = 36.0

func _ready():
	_color_bar = $ColorBar
	_name_lbl = $NameLabel
	_qty_lbl = $QtyLabel
	_select_highlight = $SelectHighlight

func setup(id: String, name: String, amount: int, color: Color):
	item_id = id
	item_name = name
	item_amount = amount
	item_color = color
	custom_minimum_size = Vector2(SLOT_W, SLOT_H)
	_color_bar.color = color
	_name_lbl.text = name
	_qty_lbl.text = "x%d" % amount
	_select_highlight.visible = false

func update_amount(amount: int):
	item_amount = amount
	_qty_lbl.text = "x%d" % amount

func select():
	_select_highlight.visible = true

func deselect():
	_select_highlight.visible = false

func is_selected() -> bool:
	return _select_highlight.visible

func _pressed():
	slot_selected.emit(item_id)
