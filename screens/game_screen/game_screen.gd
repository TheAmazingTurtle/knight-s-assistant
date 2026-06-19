class_name GameScreen
extends Control

const KnightViewScript := preload("res://entities/knight/knight.gd")
const EnemyViewScript := preload("res://entities/enemy/enemy.gd")
const PorterViewScript := preload("res://entities/porter/porter.gd")
const DroppedLootViewScript := preload("res://entities/loot/dropped_loot.gd")

const GOLD_UPGRADE_ORDER := ["knight_damage", "knight_health", "bag_capacity"]
const SPECIAL_UPGRADE_ORDER := [
	"attack_speed",
	"health_regen",
	"health_multiplier",
	"porter_heal_cooldown",
	"porter_tonic_multiplier",
	"porter_tonic_cooldown"
]

var battle_area: Control
var loot_layer: Control
var tabs: TabContainer
var inventory_content: VBoxContainer
var upgrades_content: VBoxContainer
var special_content: VBoxContainer

var stage_label: Label
var gold_label: Label
var enemy_label: Label
var knight_label: Label
var status_label: Label
var enemy_health_bar: ProgressBar
var knight_health_bar: ProgressBar
var heal_button: Button
var tonic_button: Button
var ability_row: HBoxContainer

var knight_view: Control
var enemy_view: Control
var porter_view: Control
var victory_layer: Control

var enemy_stats: Dictionary = {}
var enemy_hp := 1.0
var enemy_max_hp := 1.0
var knight_hp := 1.0
var knight_max_hp := 1.0
var knight_attack_timer := 0.0
var enemy_attack_timer := 0.0
var heal_cooldown_left := 0.0
var tonic_cooldown_left := 0.0
var tonic_active_left := 0.0
var porter_hurry_left := 0.0
var stage_transition_timer := 0.0
var combat_paused := false
var victory_visible := false
var porter_center := Vector2.ZERO
var active_loot: Array = []
var remaining_enemy_loot: Array = []
var drop_thresholds: Array = []
var next_drop_threshold_index := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	_connect_game_state()
	_start_stage()
	if GameState.victory_cleared:
		_show_victory()
	set_process(true)


func _process(delta: float) -> void:
	if battle_area == null:
		return
	_layout_battle_objects()
	_tick_cooldowns(delta)
	_tick_loot(delta)
	if victory_visible:
		_refresh_battle_labels()
		return
	if stage_transition_timer > 0.0:
		stage_transition_timer = max(0.0, stage_transition_timer - delta)
		if stage_transition_timer <= 0.0:
			_start_stage()
		_refresh_battle_labels()
		return
	if not combat_paused:
		_tick_combat(delta)
	_refresh_battle_labels()


func _connect_game_state() -> void:
	if not GameState.changed.is_connected(_on_game_state_changed):
		GameState.changed.connect(_on_game_state_changed)


func _build_layout() -> void:
	var background := ColorRect.new()
	background.color = Color("#263d3a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	battle_area = Control.new()
	battle_area.custom_minimum_size = Vector2(360, 322)
	battle_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_area.clip_contents = true
	root.add_child(battle_area)
	_build_battle_area()

	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(360, 318)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 13)
	root.add_child(tabs)
	_build_tab_pages()
	_refresh_tabs()


func _build_battle_area() -> void:
	var sky := ColorRect.new()
	sky.color = Color("#79aaa0")
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_area.add_child(sky)

	var far_hills := ColorRect.new()
	far_hills.color = Color("#6f8350")
	far_hills.anchor_top = 0.48
	far_hills.anchor_right = 1.0
	far_hills.anchor_bottom = 0.66
	battle_area.add_child(far_hills)

	var grass := ColorRect.new()
	grass.color = Color("#4f6f43")
	grass.anchor_top = 0.62
	grass.anchor_right = 1.0
	grass.anchor_bottom = 1.0
	battle_area.add_child(grass)

	var path := ColorRect.new()
	path.color = Color("#8a6a49")
	path.anchor_top = 0.75
	path.anchor_right = 1.0
	path.anchor_bottom = 1.0
	path.offset_left = -16
	path.offset_right = 16
	battle_area.add_child(path)

	loot_layer = Control.new()
	loot_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	loot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_area.add_child(loot_layer)

	porter_view = PorterViewScript.new()
	porter_view.size = Vector2(58, 68)
	battle_area.add_child(porter_view)

	knight_view = KnightViewScript.new()
	knight_view.size = Vector2(72, 84)
	battle_area.add_child(knight_view)

	enemy_view = EnemyViewScript.new()
	enemy_view.size = Vector2(88, 92)
	battle_area.add_child(enemy_view)

	stage_label = _make_label("", 16, Color("#173231"))
	stage_label.position = Vector2(10, 6)
	stage_label.size = Vector2(150, 24)
	battle_area.add_child(stage_label)

	gold_label = _make_label("", 16, Color("#173231"))
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.position = Vector2(210, 6)
	gold_label.size = Vector2(138, 24)
	battle_area.add_child(gold_label)

	enemy_label = _make_label("", 13, Color("#173231"))
	enemy_label.position = Vector2(116, 32)
	enemy_label.size = Vector2(232, 18)
	battle_area.add_child(enemy_label)

	enemy_health_bar = _make_bar(Color("#b94b40"))
	enemy_health_bar.position = Vector2(116, 51)
	enemy_health_bar.size = Vector2(232, 14)
	battle_area.add_child(enemy_health_bar)

	knight_label = _make_label("", 13, Color("#173231"))
	knight_label.position = Vector2(10, 32)
	knight_label.size = Vector2(96, 18)
	battle_area.add_child(knight_label)

	knight_health_bar = _make_bar(Color("#5f9f62"))
	knight_health_bar.position = Vector2(10, 51)
	knight_health_bar.size = Vector2(96, 14)
	battle_area.add_child(knight_health_bar)

	status_label = _make_label("", 13, Color("#fff1c8"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.position = Vector2(10, 250)
	status_label.size = Vector2(340, 22)
	battle_area.add_child(status_label)

	ability_row = HBoxContainer.new()
	ability_row.position = Vector2(10, 276)
	ability_row.size = Vector2(340, 42)
	ability_row.add_theme_constant_override("separation", 8)
	battle_area.add_child(ability_row)

	heal_button = _make_button("Heal")
	heal_button.custom_minimum_size = Vector2(160, 42)
	heal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heal_button.pressed.connect(_on_heal_pressed)
	ability_row.add_child(heal_button)

	tonic_button = _make_button("Power-up")
	tonic_button.custom_minimum_size = Vector2(160, 42)
	tonic_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tonic_button.pressed.connect(_on_tonic_pressed)
	ability_row.add_child(tonic_button)


func _build_tab_pages() -> void:
	var inventory_scroll := _make_scroll_page("Inventory")
	inventory_content = inventory_scroll.get_child(0)
	tabs.add_child(inventory_scroll)

	var upgrades_scroll := _make_scroll_page("Upgrades")
	upgrades_content = upgrades_scroll.get_child(0)
	tabs.add_child(upgrades_scroll)

	var special_scroll := _make_scroll_page("Special")
	special_content = special_scroll.get_child(0)
	tabs.add_child(special_scroll)


func _make_scroll_page(page_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = page_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	content.custom_minimum_size = Vector2(342, 0)
	scroll.add_child(content)
	return scroll


func _start_stage() -> void:
	enemy_stats = GameState.get_enemy_stats()
	enemy_max_hp = float(enemy_stats.get("max_health", 1))
	enemy_hp = enemy_max_hp
	knight_max_hp = GameState.get_knight_max_health()
	knight_hp = knight_max_hp
	knight_attack_timer = 0.35
	enemy_attack_timer = float(enemy_stats.get("attack_interval", 2.5))
	combat_paused = false
	stage_transition_timer = 0.0
	remaining_enemy_loot.clear()
	var is_boss := bool(enemy_stats.get("is_boss", false))
	for i in range(GameState.get_drops_per_enemy(is_boss)):
		remaining_enemy_loot.append(GameState.roll_loot_drop(is_boss))
	drop_thresholds = GameState.get_loot_drop_thresholds().duplicate()
	next_drop_threshold_index = 0
	if enemy_view != null:
		enemy_view.configure(int(enemy_stats.get("stage", GameState.stage)), is_boss)
		enemy_view.set_health_ratio(1.0)
	if knight_view != null:
		knight_view.set_health_ratio(1.0)
	status_label.text = "Boss stage" if is_boss else "Stage %d" % GameState.stage
	_refresh_tabs()
	_refresh_battle_labels()


func _tick_cooldowns(delta: float) -> void:
	heal_cooldown_left = max(0.0, heal_cooldown_left - delta)
	tonic_cooldown_left = max(0.0, tonic_cooldown_left - delta)
	tonic_active_left = max(0.0, tonic_active_left - delta)
	porter_hurry_left = max(0.0, porter_hurry_left - delta)


func _tick_combat(delta: float) -> void:
	if enemy_hp <= 0.0 or knight_hp <= 0.0:
		return
	var regen := GameState.get_knight_regen_per_second()
	if regen > 0.0:
		knight_hp = min(knight_max_hp, knight_hp + regen * delta)
	knight_attack_timer -= delta
	if knight_attack_timer <= 0.0:
		_knight_attack()
		knight_attack_timer = GameState.get_knight_attack_interval()
	enemy_attack_timer -= delta
	if enemy_attack_timer <= 0.0 and enemy_hp > 0.0:
		_enemy_attack()
		enemy_attack_timer = float(enemy_stats.get("attack_interval", 2.5))


func _knight_attack() -> void:
	var damage := GameState.get_knight_damage()
	if tonic_active_left > 0.0:
		damage *= GameState.get_tonic_multiplier()
	enemy_hp = max(0.0, enemy_hp - damage)
	if knight_view != null:
		knight_view.pulse_attack()
	if enemy_view != null:
		enemy_view.pulse_hit()
		enemy_view.set_health_ratio(enemy_hp / enemy_max_hp)
	_check_drop_thresholds()
	if enemy_hp <= 0.0:
		_handle_enemy_defeated()


func _enemy_attack() -> void:
	knight_hp = max(0.0, knight_hp - float(enemy_stats.get("damage", 1)))
	if knight_view != null:
		knight_view.set_health_ratio(knight_hp / knight_max_hp)
	if knight_hp <= 0.0:
		_handle_knight_defeated()


func _check_drop_thresholds() -> void:
	var ratio := enemy_hp / enemy_max_hp
	while next_drop_threshold_index < drop_thresholds.size() and ratio <= float(drop_thresholds[next_drop_threshold_index]):
		_drop_next_enemy_loot()
		next_drop_threshold_index += 1


func _drop_next_enemy_loot() -> void:
	if remaining_enemy_loot.is_empty():
		return
	var drop: Dictionary = remaining_enemy_loot.pop_front()
	_spawn_loot_from_drop(drop)


func _handle_enemy_defeated() -> void:
	combat_paused = true
	if enemy_view != null:
		enemy_view.set_health_ratio(0.0)
	while not remaining_enemy_loot.is_empty():
		var drop: Dictionary = remaining_enemy_loot.pop_front()
		_spawn_loot_from_drop(drop)
	var won := GameState.advance_stage_after_enemy_defeat()
	if won:
		_show_victory()
	else:
		status_label.text = "Stage cleared"
		stage_transition_timer = 0.85


func _handle_knight_defeated() -> void:
	combat_paused = true
	knight_hp = 0.0
	if knight_view != null:
		knight_view.set_health_ratio(0.0)
	GameState.return_to_checkpoint_after_knight_defeat()
	status_label.text = "Knight fell. Back to Stage %d" % GameState.stage
	stage_transition_timer = 1.1


func _spawn_loot_from_drop(drop: Dictionary) -> void:
	if loot_layer == null:
		return
	var loot_id := str(drop.get("id", "scrap"))
	var amount := int(drop.get("amount", 1))
	var loot := DroppedLootViewScript.new()
	loot.size = Vector2(36, 36)
	loot.setup(loot_id, amount, GameState.get_loot_color(loot_id))
	loot.position = _make_loot_position(active_loot.size())
	loot.pressed_loot.connect(_on_loot_pressed)
	loot_layer.add_child(loot)
	active_loot.append(loot)


func _make_loot_position(index: int) -> Vector2:
	var area_size := battle_area.size
	var center := _knight_center()
	var spread := Vector2((index % 4) * 12.0, (index % 3) * 8.0)
	var random_offset := Vector2(GameState.rng.randf_range(54.0, 96.0), GameState.rng.randf_range(-8.0, 28.0))
	var pos := center - random_offset + spread
	pos.x = clampf(pos.x, 14.0, max(14.0, area_size.x - 44.0))
	pos.y = clampf(pos.y, 90.0, max(90.0, area_size.y - 82.0))
	return pos


func _tick_loot(delta: float) -> void:
	_cleanup_loot()
	if porter_view == null:
		return
	var target := _porter_home_center()
	var nearest := _get_nearest_loot()
	if nearest != null:
		target = nearest.position + nearest.size * 0.5
	var speed := GameState.get_porter_speed(porter_hurry_left > 0.0)
	porter_center = porter_center.move_toward(target, speed * delta)
	porter_view.position = porter_center - porter_view.size * 0.5
	porter_view.set_carrying(nearest != null)
	porter_view.set_hurry(porter_hurry_left > 0.0)
	if nearest != null and porter_center.distance_to(nearest.position + nearest.size * 0.5) <= 20.0:
		_collect_loot(nearest)


func _cleanup_loot() -> void:
	for i in range(active_loot.size() - 1, -1, -1):
		if not is_instance_valid(active_loot[i]):
			active_loot.remove_at(i)


func _get_nearest_loot() -> Control:
	var closest: Control = null
	var closest_distance := 1000000.0
	for loot in active_loot:
		if not is_instance_valid(loot):
			continue
		var distance := porter_center.distance_to(loot.position + loot.size * 0.5)
		if distance < closest_distance:
			closest = loot
			closest_distance = distance
	return closest


func _collect_loot(loot: Control) -> void:
	var added := GameState.add_loot(loot.loot_id, loot.amount)
	var discarded: int = max(0, loot.amount - added)
	var loot_name := GameState.get_loot_name(loot.loot_id)
	if discarded <= 0:
		status_label.text = "+%d %s" % [added, loot_name]
	elif added > 0:
		status_label.text = "Bag full: +%d %s, discarded %d" % [added, loot_name, discarded]
	else:
		status_label.text = "Bag full: discarded %s" % loot_name
	active_loot.erase(loot)
	loot.queue_free()


func _on_loot_pressed(loot: Control) -> void:
	porter_hurry_left = GameState.get_porter_hurry_duration()
	if is_instance_valid(loot):
		loot.mark_tapped()
	if porter_view != null:
		porter_view.set_hurry(true)


func _on_heal_pressed() -> void:
	if heal_cooldown_left > 0.0 or knight_hp <= 0.0:
		return
	knight_hp = min(knight_max_hp, knight_hp + knight_max_hp * GameState.get_heal_percent())
	heal_cooldown_left = GameState.get_heal_cooldown()
	if knight_view != null:
		knight_view.set_health_ratio(knight_hp / knight_max_hp)
	status_label.text = "Knight healed"


func _on_tonic_pressed() -> void:
	if tonic_cooldown_left > 0.0 or knight_hp <= 0.0:
		return
	tonic_active_left = GameState.get_tonic_duration()
	tonic_cooldown_left = GameState.get_tonic_cooldown()
	status_label.text = "Power-up active"


func _refresh_tabs() -> void:
	if inventory_content == null:
		return
	_refresh_inventory_tab()
	_refresh_gold_upgrades_tab()
	_refresh_special_upgrades_tab()


func _refresh_inventory_tab() -> void:
	_clear_children(inventory_content)
	inventory_content.add_child(_make_section_label("Bag %d/%d   Gold %d" % [GameState.get_inventory_used(), GameState.get_inventory_capacity(), GameState.gold]))
	var sell_all_button := _make_button("Sell Unlocked")
	sell_all_button.disabled = GameState.get_inventory_used() <= 0
	sell_all_button.pressed.connect(_on_sell_all_pressed)
	inventory_content.add_child(sell_all_button)
	for loot_id in GameState.get_loot_ids():
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		inventory_content.add_child(row)

		var swatch := ColorRect.new()
		swatch.color = GameState.get_loot_color(loot_id)
		swatch.custom_minimum_size = Vector2(18, 18)
		row.add_child(swatch)

		var count := int(GameState.inventory.get(loot_id, 0))
		var label := _make_label("%s: %d  (%dg)" % [GameState.get_loot_name(loot_id), count, GameState.get_loot_sell_value(loot_id)], 13, Color("#f7efd5"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var lock := CheckButton.new()
		lock.text = "Lock"
		lock.button_pressed = GameState.is_loot_locked(loot_id)
		lock.toggled.connect(_on_loot_lock_toggled.bind(loot_id))
		row.add_child(lock)

		var sell := _make_button("Sell")
		sell.custom_minimum_size = Vector2(62, 34)
		sell.disabled = count <= 0
		sell.pressed.connect(_on_sell_kind_pressed.bind(loot_id))
		row.add_child(sell)


func _refresh_gold_upgrades_tab() -> void:
	_clear_children(upgrades_content)
	upgrades_content.add_child(_make_section_label("Damage %.0f   Health %.0f   Bag %d" % [GameState.get_knight_damage(), GameState.get_knight_max_health(), GameState.get_inventory_capacity()]))
	for upgrade_id in GOLD_UPGRADE_ORDER:
		var row := _make_upgrade_row(GameState.get_upgrade_name(upgrade_id), GameState.get_upgrade_level(upgrade_id), "%d gold" % GameState.get_gold_upgrade_cost(upgrade_id))
		var button := row.get_child(1) as Button
		button.disabled = not GameState.can_buy_gold_upgrade(upgrade_id)
		button.pressed.connect(_on_buy_gold_upgrade_pressed.bind(upgrade_id))
		upgrades_content.add_child(row)


func _refresh_special_upgrades_tab() -> void:
	_clear_children(special_content)
	special_content.add_child(_make_section_label("Material Upgrades"))
	for upgrade_id in SPECIAL_UPGRADE_ORDER:
		var row := _make_upgrade_row(GameState.get_upgrade_name(upgrade_id), GameState.get_upgrade_level(upgrade_id), _format_special_cost(upgrade_id))
		var button := row.get_child(1) as Button
		button.disabled = not GameState.can_buy_special_upgrade(upgrade_id)
		button.pressed.connect(_on_buy_special_upgrade_pressed.bind(upgrade_id))
		special_content.add_child(row)


func _make_upgrade_row(title: String, level: int, cost: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var label := _make_label("%s  Lv %d\n%s" % [title, level, cost], 13, Color("#f7efd5"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := _make_button("Buy")
	button.custom_minimum_size = Vector2(72, 42)
	row.add_child(button)
	return row


func _format_special_cost(upgrade_id: String) -> String:
	var parts: Array = []
	for cost in GameState.get_special_upgrade_costs(upgrade_id):
		var loot_id := str(cost.get("loot", ""))
		parts.append("%d %s" % [int(cost.get("amount", 0)), GameState.get_loot_name(loot_id)])
	return ", ".join(parts)


func _on_sell_all_pressed() -> void:
	var earned := GameState.sell_all_unlocked()
	status_label.text = "Sold for %d gold" % earned if earned > 0 else "Nothing to sell"


func _on_sell_kind_pressed(loot_id: String) -> void:
	var earned := GameState.sell_loot_kind(loot_id)
	status_label.text = "Sold %s for %d gold" % [GameState.get_loot_name(loot_id), earned] if earned > 0 else "Nothing to sell"


func _on_loot_lock_toggled(value: bool, loot_id: String) -> void:
	GameState.set_loot_locked(loot_id, value)


func _on_buy_gold_upgrade_pressed(upgrade_id: String) -> void:
	if GameState.buy_gold_upgrade(upgrade_id):
		_sync_knight_stats_after_upgrade()
		status_label.text = "%s upgraded" % GameState.get_upgrade_name(upgrade_id)


func _on_buy_special_upgrade_pressed(upgrade_id: String) -> void:
	if GameState.buy_special_upgrade(upgrade_id):
		_sync_knight_stats_after_upgrade()
		status_label.text = "%s upgraded" % GameState.get_upgrade_name(upgrade_id)


func _on_game_state_changed() -> void:
	_sync_knight_stats_after_upgrade()
	_refresh_tabs()
	_refresh_battle_labels()


func _sync_knight_stats_after_upgrade() -> void:
	if knight_max_hp <= 0.0:
		return
	var old_max := knight_max_hp
	var new_max := GameState.get_knight_max_health()
	if new_max > old_max:
		knight_hp += new_max - old_max
	knight_max_hp = new_max
	knight_hp = clampf(knight_hp, 0.0, knight_max_hp)
	if knight_view != null:
		knight_view.set_health_ratio(knight_hp / knight_max_hp)


func _refresh_battle_labels() -> void:
	if stage_label == null:
		return
	stage_label.text = "Stage %d/%d" % [GameState.stage, GameState.get_max_stage()]
	gold_label.text = "%d gold" % GameState.gold
	enemy_label.text = "%s  %.0f/%.0f" % [str(enemy_stats.get("name", "Enemy")), enemy_hp, enemy_max_hp]
	knight_label.text = "Knight %.0f/%.0f" % [knight_hp, knight_max_hp]
	enemy_health_bar.value = clampf(enemy_hp / enemy_max_hp, 0.0, 1.0) * 100.0
	knight_health_bar.value = clampf(knight_hp / knight_max_hp, 0.0, 1.0) * 100.0
	heal_button.disabled = heal_cooldown_left > 0.0 or knight_hp <= 0.0 or victory_visible
	heal_button.text = "Heal" if heal_cooldown_left <= 0.0 else "Heal %ds" % int(ceil(heal_cooldown_left))
	tonic_button.disabled = tonic_cooldown_left > 0.0 or knight_hp <= 0.0 or victory_visible
	if tonic_active_left > 0.0:
		tonic_button.text = "Power %.0fs" % tonic_active_left
	else:
		tonic_button.text = "Power-up" if tonic_cooldown_left <= 0.0 else "Power %ds" % int(ceil(tonic_cooldown_left))


func _layout_battle_objects() -> void:
	var area_size := battle_area.size
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		return
	if loot_layer != null:
		loot_layer.size = area_size
	if knight_view != null:
		knight_view.position = _knight_center() - knight_view.size * 0.5
	if enemy_view != null:
		enemy_view.position = Vector2(area_size.x * 0.72, area_size.y * 0.58) - enemy_view.size * 0.5
	if porter_center == Vector2.ZERO:
		porter_center = _porter_home_center()
	if ability_row != null:
		ability_row.position = Vector2(10, max(214.0, area_size.y - 48.0))
		ability_row.size = Vector2(max(0.0, area_size.x - 20.0), 40)
	if status_label != null:
		status_label.position = Vector2(10, ability_row.position.y - 24.0)
		status_label.size = Vector2(max(0.0, area_size.x - 20.0), 22)


func _knight_center() -> Vector2:
	var area_size := battle_area.size
	return Vector2(area_size.x * 0.34, area_size.y * 0.63)


func _porter_home_center() -> Vector2:
	var area_size := battle_area.size
	return Vector2(area_size.x * 0.2, area_size.y * 0.7)


func _show_victory() -> void:
	if victory_visible:
		return
	victory_visible = true
	combat_paused = true
	victory_layer = ColorRect.new()
	victory_layer.color = Color(0.05, 0.08, 0.08, 0.82)
	victory_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(victory_layer)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.27
	panel.anchor_bottom = 0.72
	panel.add_theme_stylebox_override("panel", _stylebox(Color("#f2d28a"), Color("#4b3421")))
	victory_layer.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(column)

	var title := _make_label("You cleared the game!", 24, Color("#3b2618"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var body := _make_label("Screenshot this and tell Kent you beat the game.", 16, Color("#3b2618"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)

	var play_again := _make_button("Play Again")
	play_again.pressed.connect(_on_play_again_pressed)
	column.add_child(play_again)


func _on_play_again_pressed() -> void:
	GameState.reset_game()
	victory_visible = false
	if victory_layer != null:
		victory_layer.queue_free()
		victory_layer = null
	_start_stage()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_section_label(text: String) -> Label:
	var label := _make_label(text, 15, Color("#fff1c8"))
	label.custom_minimum_size = Vector2(0, 28)
	return label


func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _stylebox(Color("#d9aa5f"), Color("#443122")))
	button.add_theme_stylebox_override("hover", _stylebox(Color("#edc174"), Color("#443122")))
	button.add_theme_stylebox_override("pressed", _stylebox(Color("#aa7a3d"), Color("#443122")))
	button.add_theme_stylebox_override("disabled", _stylebox(Color("#72695d"), Color("#443122")))
	return button


func _make_bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _stylebox(Color("#24322f"), Color("#17211f")))
	bar.add_theme_stylebox_override("fill", _stylebox(fill, fill.darkened(0.2)))
	return bar


func _stylebox(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
