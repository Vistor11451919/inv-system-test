extends GutTest

var inv: InventoryBackend

func before_each():
	inv = InventoryBackend.new()

func test_add_item_new():
	inv.cache_max_stack("potion_hp", 10)
	var leftover = inv.add_item("potion_hp", 3)
	assert_eq(leftover, 0)
	assert_eq(inv.get_item_count("potion_hp"), 3)

func test_add_item_overflow():
	inv.cache_max_stack("potion_hp", 10)
	inv.add_item("potion_hp", 8)
	var leftover = inv.add_item("potion_hp", 5)
	assert_eq(leftover, 3)
	assert_eq(inv.get_item_count("potion_hp"), 10)

func test_remove_item_partial():
	inv.cache_max_stack("potion_hp", 10)
	inv.add_item("potion_hp", 5)
	var ok = inv.remove_item("potion_hp", 2)
	assert_true(ok)
	assert_eq(inv.get_item_count("potion_hp"), 3)

func test_remove_item_nonexistent():
	var ok = inv.remove_item("nothing", 1)
	assert_false(ok)

func test_use_item():
	inv.cache_max_stack("potion_hp", 10)
	inv.add_item("potion_hp", 3)
	var ok = inv.use_item("potion_hp")
	assert_true(ok)
	assert_eq(inv.get_item_count("potion_hp"), 2)

func test_equip_consumes_item():
	inv.cache_max_stack("weapon_katana", 1)
	inv.add_item("weapon_katana", 1)
	var ok = inv.equip("weapon_katana", Enums.EquipSlot.WEAPON)
	assert_true(ok)
	assert_eq(inv.get_item_count("weapon_katana"), 0)
	assert_eq(inv.get_equipped_item(Enums.EquipSlot.WEAPON), "weapon_katana")

func test_unequip_returns_item():
	inv.cache_max_stack("weapon_katana", 1)
	inv.add_item("weapon_katana", 1)
	inv.equip("weapon_katana", Enums.EquipSlot.WEAPON)
	var old_id = inv.unequip(Enums.EquipSlot.WEAPON)
	assert_eq(old_id, "weapon_katana")
	assert_eq(inv.get_item_count("weapon_katana"), 1)

# ============== 边缘情况补充 ==============

func test_default_max_stack_is_99():
	# 不调用 cache_max_stack 时，默认堆叠上限应为 99
	var leftover = inv.add_item("ore", 100)
	assert_eq(leftover, 1)
	assert_eq(inv.get_item_count("ore"), 99)

func test_add_negative_amount():
	var leftover = inv.add_item("item", -5)
	assert_eq(leftover, 0)

func test_add_zero_amount():
	var leftover = inv.add_item("item", 0)
	assert_eq(leftover, 0)

func test_remove_more_than_available():
	inv.cache_max_stack("potion_hp", 10)
	inv.add_item("potion_hp", 3)
	var ok = inv.remove_item("potion_hp", 5)
	assert_false(ok)
	assert_eq(inv.get_item_count("potion_hp"), 3)

func test_remove_negative_amount():
	inv.cache_max_stack("potion_hp", 10)
	inv.add_item("potion_hp", 3)
	var ok = inv.remove_item("potion_hp", -1)
	assert_false(ok)

func test_remove_to_zero_erases_entry():
	inv.cache_max_stack("potion_hp", 10)
	inv.add_item("potion_hp", 1)
	inv.remove_item("potion_hp", 1)
	assert_eq(inv.get_item_count("potion_hp"), 0)

func test_use_item_empty():
	var ok = inv.use_item("nonexistent")
	assert_false(ok)

func test_use_item_after_partial_use():
	inv.cache_max_stack("potion_hp", 10)
	inv.add_item("potion_hp", 2)
	inv.use_item("potion_hp")
	assert_eq(inv.get_item_count("potion_hp"), 1)

func test_equip_nonexistent_item():
	var ok = inv.equip("nothing", Enums.EquipSlot.WEAPON)
	assert_false(ok)

func test_equip_empty_inventory():
	var ok = inv.equip("item", Enums.EquipSlot.WEAPON)
	assert_false(ok)

func test_unequip_empty_slot():
	var old_id = inv.unequip(Enums.EquipSlot.WEAPON)
	assert_eq(old_id, "")

func test_equip_replaces_occupied_slot():
	inv.cache_max_stack("weapon_katana", 1)
	inv.cache_max_stack("weapon_axe", 1)
	inv.add_item("weapon_katana", 1)
	inv.add_item("weapon_axe", 1)
	inv.equip("weapon_katana", Enums.EquipSlot.WEAPON)
	inv.equip("weapon_axe", Enums.EquipSlot.WEAPON)
	assert_eq(inv.get_equipped_item(Enums.EquipSlot.WEAPON), "weapon_axe")
	# 替换时旧装备应回到背包
	assert_eq(inv.get_item_count("weapon_katana"), 1)

func test_get_all_equipped():
	inv.cache_max_stack("a", 1); inv.cache_max_stack("b", 1); inv.cache_max_stack("c", 1)
	inv.add_item("a", 1); inv.add_item("b", 1); inv.add_item("c", 1)
	inv.equip("a", Enums.EquipSlot.WEAPON)
	inv.equip("b", Enums.EquipSlot.ARMOR)
	inv.equip("c", Enums.EquipSlot.ACCESSORY)
	var equipped = inv.get_all_equipped()
	assert_eq(equipped.size(), 3)
	assert_true("a" in equipped)
	assert_true("b" in equipped)
	assert_true("c" in equipped)

func test_get_equipped_mods_returns_slots():
	inv.cache_max_stack("katana", 1)
	inv.add_item("katana", 1)
	inv.equip("katana", Enums.EquipSlot.WEAPON)
	var mods = inv.get_equipped_mods()
	assert_eq(mods.size(), 1)
	assert_eq(mods[0].slot, Enums.EquipSlot.WEAPON)
	assert_eq(mods[0].item_id, "katana")

func test_use_then_equip():
	inv.cache_max_stack("potion_hp", 5)
	inv.cache_max_stack("weapon", 1)
	inv.add_item("potion_hp", 3)
	inv.add_item("weapon", 1)
	inv.use_item("potion_hp")
	var ok = inv.equip("weapon", Enums.EquipSlot.WEAPON)
	assert_true(ok)
