extends Node

signal changed
signal stage_changed
signal inventory_changed
signal upgrades_changed
signal save_loaded
signal game_won

const SAVE_PATH := "user://knights_assistant_save.json"
const COMBAT_DATA_PATH := "res://data/combat.json"
const LOOT_DATA_PATH := "res://data/loot.json"
const STAGE_DATA_PATH := "res://data/stage_scaling.json"
const UPGRADE_DATA_PATH := "res://data/upgrades.json"

var combat_data: Dictionary = {}
var loot_data: Dictionary = {}
var stage_data: Dictionary = {}
var upgrade_data: Dictionary = {}

var stage := 1
var gold := 0
var inventory: Dictionary = {}
var locked_loot: Dictionary = {}
var upgrades: Dictionary = {}
var last_cleared_boss_stage := 0
var victory_cleared := false

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	load_data()
	load_game()


func load_data() -> void:
	combat_data = _read_json(COMBAT_DATA_PATH)
	loot_data = _read_json(LOOT_DATA_PATH)
	stage_data = _read_json(STAGE_DATA_PATH)
	upgrade_data = _read_json(UPGRADE_DATA_PATH)
	_ensure_defaults()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_ensure_defaults()
		emit_signal("save_loaded")
		return
	var parsed := _read_json(SAVE_PATH)
	stage = int(parsed.get("stage", 1))
	gold = int(parsed.get("gold", 0))
	inventory = parsed.get("inventory", {})
	locked_loot = parsed.get("locked_loot", {})
	upgrades = parsed.get("upgrades", {})
	last_cleared_boss_stage = int(parsed.get("last_cleared_boss_stage", 0))
	victory_cleared = bool(parsed.get("victory_cleared", false))
	_ensure_defaults()
	emit_signal("save_loaded")
	emit_signal("changed")


func save_game() -> void:
	var payload := {
		"stage": stage,
		"gold": gold,
		"inventory": inventory,
		"locked_loot": locked_loot,
		"upgrades": upgrades,
		"last_cleared_boss_stage": last_cleared_boss_stage,
		"victory_cleared": victory_cleared
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save game to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))


func reset_game() -> void:
	stage = 1
	gold = 0
	inventory = {}
	locked_loot = {}
	upgrades = {}
	last_cleared_boss_stage = 0
	victory_cleared = false
	_ensure_defaults()
	save_game()
	emit_signal("stage_changed")
	emit_signal("inventory_changed")
	emit_signal("upgrades_changed")
	emit_signal("changed")


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	push_warning("Invalid JSON in %s" % path)
	return {}


func _ensure_defaults() -> void:
	for loot_id in get_loot_ids():
		if not inventory.has(loot_id):
			inventory[loot_id] = 0
		if not locked_loot.has(loot_id):
			locked_loot[loot_id] = false
	for upgrade_id in get_gold_upgrade_ids():
		if not upgrades.has(upgrade_id):
			upgrades[upgrade_id] = 0
	for upgrade_id in get_special_upgrade_ids():
		if not upgrades.has(upgrade_id):
			upgrades[upgrade_id] = 0
	stage = clamp(stage, 1, get_max_stage())
	last_cleared_boss_stage = max(0, last_cleared_boss_stage)


func get_max_stage() -> int:
	return int(combat_data.get("max_stage", 100))


func get_loot_ids() -> Array:
	return loot_data.get("loot_types", {}).keys()


func get_loot_name(loot_id: String) -> String:
	return str(loot_data.get("loot_types", {}).get(loot_id, {}).get("name", loot_id.capitalize()))


func get_loot_color(loot_id: String) -> Color:
	return Color(str(loot_data.get("loot_types", {}).get(loot_id, {}).get("color", "#ffffff")))


func get_loot_sell_value(loot_id: String) -> int:
	return int(loot_data.get("loot_types", {}).get(loot_id, {}).get("sell_value", 1))


func get_inventory_used() -> int:
	var total := 0
	for loot_id in get_loot_ids():
		total += int(inventory.get(loot_id, 0))
	return total


func get_inventory_capacity() -> int:
	var config: Dictionary = upgrade_data.get("gold_upgrades", {}).get("bag_capacity", {})
	var base_capacity := int(config.get("base_capacity", 18))
	var per_level := int(config.get("value_per_level", 5))
	return base_capacity + get_upgrade_level("bag_capacity") * per_level


func get_inventory_room() -> int:
	return max(0, get_inventory_capacity() - get_inventory_used())


func add_loot(loot_id: String, amount: int) -> int:
	_ensure_defaults()
	var room := get_inventory_room()
	var added: int = min(max(amount, 0), room)
	if added <= 0:
		return 0
	inventory[loot_id] = int(inventory.get(loot_id, 0)) + added
	save_game()
	emit_signal("inventory_changed")
	emit_signal("changed")
	return added


func set_loot_locked(loot_id: String, is_locked: bool) -> void:
	locked_loot[loot_id] = is_locked
	save_game()
	emit_signal("inventory_changed")
	emit_signal("changed")


func is_loot_locked(loot_id: String) -> bool:
	return bool(locked_loot.get(loot_id, false))


func sell_loot_kind(loot_id: String) -> int:
	var count := int(inventory.get(loot_id, 0))
	if count <= 0:
		return 0
	var earned := count * get_loot_sell_value(loot_id)
	inventory[loot_id] = 0
	gold += earned
	save_game()
	emit_signal("inventory_changed")
	emit_signal("changed")
	return earned


func sell_all_unlocked() -> int:
	var earned := 0
	for loot_id in get_loot_ids():
		if is_loot_locked(loot_id):
			continue
		var count := int(inventory.get(loot_id, 0))
		if count <= 0:
			continue
		earned += count * get_loot_sell_value(loot_id)
		inventory[loot_id] = 0
	if earned <= 0:
		return 0
	gold += earned
	save_game()
	emit_signal("inventory_changed")
	emit_signal("changed")
	return earned


func get_gold_upgrade_ids() -> Array:
	return upgrade_data.get("gold_upgrades", {}).keys()


func get_special_upgrade_ids() -> Array:
	return upgrade_data.get("special_upgrades", {}).keys()


func get_upgrade_name(upgrade_id: String) -> String:
	var gold_config: Dictionary = upgrade_data.get("gold_upgrades", {}).get(upgrade_id, {})
	if not gold_config.is_empty():
		return str(gold_config.get("name", upgrade_id.capitalize()))
	return str(upgrade_data.get("special_upgrades", {}).get(upgrade_id, {}).get("name", upgrade_id.capitalize()))


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrades.get(upgrade_id, 0))


func get_gold_upgrade_cost(upgrade_id: String) -> int:
	var config: Dictionary = upgrade_data.get("gold_upgrades", {}).get(upgrade_id, {})
	var level := get_upgrade_level(upgrade_id)
	var base_cost := float(config.get("base_cost", 10))
	var growth := float(config.get("cost_growth", 1.4))
	return int(round(base_cost * pow(growth, level)))


func can_buy_gold_upgrade(upgrade_id: String) -> bool:
	var config: Dictionary = upgrade_data.get("gold_upgrades", {}).get(upgrade_id, {})
	if config.is_empty():
		return false
	if get_upgrade_level(upgrade_id) >= int(config.get("max_level", 999)):
		return false
	return gold >= get_gold_upgrade_cost(upgrade_id)


func buy_gold_upgrade(upgrade_id: String) -> bool:
	if not can_buy_gold_upgrade(upgrade_id):
		return false
	var cost := get_gold_upgrade_cost(upgrade_id)
	gold -= cost
	upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	save_game()
	emit_signal("upgrades_changed")
	emit_signal("changed")
	return true


func get_special_upgrade_costs(upgrade_id: String) -> Array:
	var config: Dictionary = upgrade_data.get("special_upgrades", {}).get(upgrade_id, {})
	var level := get_upgrade_level(upgrade_id)
	var sequence_id := str(config.get("cost_sequence", ""))
	var sequence: Array = upgrade_data.get("special_cost_sequences", {}).get(sequence_id, [])
	if not sequence.is_empty():
		var sequence_index: int = min(level, sequence.size() - 1)
		var loot_id := str(sequence[sequence_index])
		var base_value := float(config.get("base_value_cost", 10))
		var value_growth := float(config.get("value_cost_growth", 1.35))
		var target_value := base_value * pow(value_growth, level)
		var loot_value: int = max(1, get_loot_sell_value(loot_id))
		return [{
			"loot": loot_id,
			"amount": max(1, int(ceil(target_value / float(loot_value))))
		}]
	var growth := float(config.get("cost_growth", 1.4))
	var scaled_costs: Array = []
	for cost in config.get("costs", []):
		var scaled: Dictionary = cost.duplicate()
		scaled["amount"] = int(ceil(float(cost.get("amount", 1)) * pow(growth, level)))
		scaled_costs.append(scaled)
	return scaled_costs


func can_buy_special_upgrade(upgrade_id: String) -> bool:
	var config: Dictionary = upgrade_data.get("special_upgrades", {}).get(upgrade_id, {})
	if config.is_empty():
		return false
	if get_upgrade_level(upgrade_id) >= int(config.get("max_level", 999)):
		return false
	for cost in get_special_upgrade_costs(upgrade_id):
		if int(inventory.get(str(cost.get("loot", "")), 0)) < int(cost.get("amount", 0)):
			return false
	return true


func buy_special_upgrade(upgrade_id: String) -> bool:
	if not can_buy_special_upgrade(upgrade_id):
		return false
	for cost in get_special_upgrade_costs(upgrade_id):
		var loot_id := str(cost.get("loot", ""))
		inventory[loot_id] = int(inventory.get(loot_id, 0)) - int(cost.get("amount", 0))
	upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	save_game()
	emit_signal("inventory_changed")
	emit_signal("upgrades_changed")
	emit_signal("changed")
	return true


func get_knight_damage() -> float:
	var base_damage := float(combat_data.get("knight", {}).get("base_damage", 7))
	var config: Dictionary = upgrade_data.get("gold_upgrades", {}).get("knight_damage", {})
	return base_damage + get_upgrade_level("knight_damage") * float(config.get("value_per_level", 4))


func get_knight_max_health() -> float:
	var base_health := float(combat_data.get("knight", {}).get("base_health", 90))
	var gold_config: Dictionary = upgrade_data.get("gold_upgrades", {}).get("knight_health", {})
	var special_config: Dictionary = upgrade_data.get("special_upgrades", {}).get("health_multiplier", {})
	var flat_health := base_health + get_upgrade_level("knight_health") * float(gold_config.get("value_per_level", 25))
	var multiplier := 1.0 + get_upgrade_level("health_multiplier") * float(special_config.get("value_per_level", 0.08))
	return flat_health * multiplier


func get_knight_attack_interval() -> float:
	var base_interval := float(combat_data.get("knight", {}).get("base_attack_interval", 1.2))
	var config: Dictionary = upgrade_data.get("special_upgrades", {}).get("attack_speed", {})
	var speed_bonus := get_upgrade_level("attack_speed") * float(config.get("value_per_level", 0.05))
	return max(0.35, base_interval / (1.0 + speed_bonus))


func get_knight_regen_per_second() -> float:
	var config: Dictionary = upgrade_data.get("special_upgrades", {}).get("health_regen", {})
	return get_upgrade_level("health_regen") * float(config.get("value_per_level", 1.2))


func get_heal_percent() -> float:
	return float(combat_data.get("porter", {}).get("heal_percent", 0.8))


func get_heal_cooldown() -> float:
	var porter: Dictionary = combat_data.get("porter", {})
	var base_cooldown := float(porter.get("base_heal_cooldown", 18.0))
	var reduction := get_upgrade_level("porter_heal_cooldown") * float(porter.get("heal_cooldown_reduction", 0.8))
	return max(float(porter.get("min_heal_cooldown", 6.0)), base_cooldown - reduction)


func get_tonic_multiplier() -> float:
	var porter: Dictionary = combat_data.get("porter", {})
	return float(porter.get("base_tonic_multiplier", 1.6)) + get_upgrade_level("porter_tonic_multiplier") * float(porter.get("tonic_multiplier_per_level", 0.18))


func get_tonic_cooldown() -> float:
	var porter: Dictionary = combat_data.get("porter", {})
	var base_cooldown := float(porter.get("base_tonic_cooldown", 28.0))
	var reduction := get_upgrade_level("porter_tonic_cooldown") * float(porter.get("tonic_cooldown_reduction", 1.1))
	return max(float(porter.get("min_tonic_cooldown", 10.0)), base_cooldown - reduction)


func get_tonic_duration() -> float:
	return float(combat_data.get("porter", {}).get("tonic_duration", 7.0))


func get_porter_speed(is_hurrying: bool) -> float:
	var porter: Dictionary = combat_data.get("porter", {})
	return float(porter.get("hurry_speed", 170.0) if is_hurrying else porter.get("base_speed", 70.0))


func get_porter_hurry_duration() -> float:
	return float(combat_data.get("porter", {}).get("hurry_duration", 1.25))


func get_enemy_stats(stage_number: int = -1) -> Dictionary:
	var checked_stage := stage if stage_number <= 0 else stage_number
	var is_boss := checked_stage % 10 == 0
	var damage_stage := checked_stage - 1
	if is_boss:
		damage_stage = max(0, checked_stage - 2)
	var health := float(stage_data.get("base_health", 45)) * pow(float(stage_data.get("health_growth", 1.08)), checked_stage - 1)
	var damage := float(stage_data.get("base_damage", 7)) * pow(float(stage_data.get("damage_growth", 1.045)), damage_stage)
	if is_boss:
		health *= float(stage_data.get("boss_health_multiplier", 4.5))
		damage *= float(stage_data.get("boss_damage_multiplier", 1.15))
	return {
		"stage": checked_stage,
		"is_boss": is_boss,
		"max_health": max(1, int(round(health))),
		"damage": max(1, int(round(damage))),
		"attack_interval": float(combat_data.get("enemy", {}).get("base_attack_interval", 2.5)),
		"name": "Boss %d" % checked_stage if is_boss else "Stage Enemy %d" % checked_stage
	}


func get_loot_drop_thresholds() -> Array:
	return combat_data.get("loot_drop_thresholds", [0.75, 0.5, 0.25])


func get_attack_loot_drop_chance(is_boss: bool) -> float:
	var config: Dictionary = combat_data.get("loot_rain", {})
	var key := "boss_attack_drop_chance" if is_boss else "attack_drop_chance"
	return clampf(float(config.get(key, 0.0)), 0.0, 1.0)


func get_attack_loot_burst_count(is_boss: bool) -> int:
	var config: Dictionary = combat_data.get("loot_rain", {})
	var min_count: int = max(1, int(config.get("burst_min", 1)))
	var max_key := "boss_burst_max" if is_boss else "burst_max"
	var max_count: int = max(min_count, int(config.get(max_key, min_count)))
	return rng.randi_range(min_count, max_count)


func get_max_active_loot() -> int:
	var config: Dictionary = combat_data.get("loot_rain", {})
	return max(1, int(config.get("max_active_loot", 18)))


func get_drops_per_enemy(is_boss: bool) -> int:
	var key := "boss" if is_boss else "normal"
	return int(loot_data.get("drops_per_enemy", {}).get(key, 4))


func roll_loot_drop(is_boss: bool) -> Dictionary:
	var table_name := "boss" if is_boss else "normal"
	var table: Array = loot_data.get("drop_tables", {}).get(table_name, [])
	var total_weight := 0
	for entry in table:
		total_weight += int(entry.get("weight", 0))
	if total_weight <= 0 or table.is_empty():
		return {"id": "scrap", "amount": 1}
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for entry in table:
		cursor += int(entry.get("weight", 0))
		if roll <= cursor:
			return {
				"id": str(entry.get("id", "scrap")),
				"amount": 1
			}
	return {"id": "scrap", "amount": 1}


func advance_stage_after_enemy_defeat() -> bool:
	if stage % 10 == 0:
		last_cleared_boss_stage = max(last_cleared_boss_stage, stage)
	if stage >= get_max_stage():
		victory_cleared = true
		save_game()
		emit_signal("game_won")
		emit_signal("changed")
		return true
	stage += 1
	save_game()
	emit_signal("stage_changed")
	emit_signal("changed")
	return false


func return_to_checkpoint_after_knight_defeat() -> void:
	stage = clamp(last_cleared_boss_stage + 1, 1, get_max_stage())
	save_game()
	emit_signal("stage_changed")
	emit_signal("changed")
