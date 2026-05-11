extends Node

const ROOM_COMBAT := "combat"
const ROOM_UPGRADE := "upgrade"
const ROOM_SHOP := "shop"
const ROOM_FORGE := "forge"
const ROOM_SHRINE := "shrine"
const ROOM_ELITE := "elite"
const ROOM_MINIBOSS := "miniboss"
const ROOM_BOSS := "boss"
const ROOM_FOUNTAIN := "fountain"
const ROOM_WITNESS := "witness"

const UPGRADE_IRON_LUNG = preload("res://data/upgrades/iron_lung.tres")
const UPGRADE_ASHEN_PLATE = preload("res://data/upgrades/ashen_plate.tres")
const UPGRADE_PILGRIM_STRIDE = preload("res://data/upgrades/pilgrim_stride.tres")
const UPGRADE_QUICKENED_STEP = preload("res://data/upgrades/quickened_step.tres")
const UPGRADE_BURNING_CONFESSION = preload("res://data/upgrades/burning_confession.tres")
const UPGRADE_PENANCE_ENGINE = preload("res://data/upgrades/penance_engine.tres")
const UPGRADE_HEAVY_ABSOLUTION = preload("res://data/upgrades/heavy_absolution.tres")
const UPGRADE_JUDGMENT_DASH = preload("res://data/upgrades/judgment_dash.tres")
const UPGRADE_CHEAP_RAPTURE = preload("res://data/upgrades/cheap_rapture.tres")

const WEIGHTED_ROOM_TABLE := [
	{"type": ROOM_COMBAT, "weight": 45},
	{"type": ROOM_UPGRADE, "weight": 30},
	{"type": ROOM_SHOP, "weight": 12},
	{"type": ROOM_SHRINE, "weight": 8},
	{"type": ROOM_FORGE, "weight": 5}
]

const BOON_POOL := [
	{
		"boon_id": "francesca_open_wound",
		"witness_id": "francesca",
		"witness_name": "Francesca",
		"display_name": "Open Wound",
		"description": "Light attacks apply Bleed for 4 seconds.",
		"rarity": "Common",
		"target_action": "Light",
		"trigger": "on_hit",
		"effect_type": "apply_status",
		"status_id": "bleed",
		"stacks": 1,
		"duration": 4.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "francesca_longing_dash",
		"witness_id": "francesca",
		"witness_name": "Francesca",
		"display_name": "Longing Dash",
		"description": "Q applies 2 Bleed stacks for 4 seconds.",
		"rarity": "Uncommon",
		"target_action": "Q",
		"trigger": "on_hit",
		"effect_type": "apply_status",
		"status_id": "bleed",
		"stacks": 2,
		"duration": 4.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "francesca_lovers_spiral",
		"witness_id": "francesca",
		"witness_name": "Francesca",
		"display_name": "Lovers’ Spiral",
		"description": "Light attacks against Bleeding enemies spread Bleed nearby.",
		"rarity": "Uncommon",
		"target_action": "Light",
		"trigger": "on_hit",
		"effect_type": "spread_status_on_hit",
		"status_id": "bleed",
		"required_status_id": "bleed",
		"stacks": 1,
		"duration": 3.5,
		"spread_radius": 145.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "francesca_last_embrace",
		"witness_id": "francesca",
		"witness_name": "Francesca",
		"display_name": "Last Embrace",
		"description": "Ultimate consumes Bleed stacks for burst damage.",
		"rarity": "Rare",
		"target_action": "Ultimate",
		"trigger": "on_hit",
		"effect_type": "detonate_status_damage",
		"status_id": "bleed",
		"stacks": 0,
		"duration": 0.0,
		"flat_value": 9.0,
		"multiplier_value": 1.0
	},

	{
		"boon_id": "minos_sentence",
		"witness_id": "minos",
		"witness_name": "Minos",
		"display_name": "Sentence",
		"description": "Heavy attacks apply Judgment for 8 seconds.",
		"rarity": "Common",
		"target_action": "Heavy",
		"trigger": "on_hit",
		"effect_type": "apply_status",
		"status_id": "judgment",
		"stacks": 1,
		"duration": 8.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "minos_verdict",
		"witness_id": "minos",
		"witness_name": "Minos",
		"display_name": "Verdict",
		"description": "Q deals +60% damage to enemies under Judgment.",
		"rarity": "Uncommon",
		"target_action": "Q",
		"trigger": "on_hit",
		"effect_type": "bonus_damage_vs_status",
		"status_id": "judgment",
		"stacks": 0,
		"duration": 0.0,
		"flat_value": 0.0,
		"multiplier_value": 1.60
	},
	{
		"boon_id": "minos_no_appeal",
		"witness_id": "minos",
		"witness_name": "Minos",
		"display_name": "No Appeal",
		"description": "Heavy attacks execute Judged enemies below 22% HP.",
		"rarity": "Rare",
		"target_action": "Heavy",
		"trigger": "on_hit",
		"effect_type": "execute_status_below_ratio",
		"status_id": "judgment",
		"execute_threshold_ratio": 0.22,
		"stacks": 0,
		"duration": 0.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "minos_final_appeal_denied",
		"witness_id": "minos",
		"witness_name": "Minos",
		"display_name": "Final Appeal Denied",
		"description": "Ultimate consumes Judgment for heavy burst damage.",
		"rarity": "Rare",
		"target_action": "Ultimate",
		"trigger": "on_hit",
		"effect_type": "detonate_status_damage",
		"status_id": "judgment",
		"stacks": 0,
		"duration": 0.0,
		"flat_value": 42.0,
		"multiplier_value": 1.0
	},

	{
		"boon_id": "geryon_false_gift",
		"witness_id": "geryon",
		"witness_name": "Geryon",
		"display_name": "False Gift",
		"description": "Q applies 2 Poison stacks for 7 seconds.",
		"rarity": "Common",
		"target_action": "Q",
		"trigger": "on_hit",
		"effect_type": "apply_status",
		"status_id": "poison",
		"stacks": 2,
		"duration": 7.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "geryon_contagion",
		"witness_id": "geryon",
		"witness_name": "Geryon",
		"display_name": "Contagion",
		"description": "Q attacks against Poisoned enemies spread Poison nearby.",
		"rarity": "Uncommon",
		"target_action": "Q",
		"trigger": "on_hit",
		"effect_type": "spread_status_on_hit",
		"status_id": "poison",
		"required_status_id": "poison",
		"stacks": 1,
		"duration": 5.0,
		"spread_radius": 155.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "geryon_honeyed_lie",
		"witness_id": "geryon",
		"witness_name": "Geryon",
		"display_name": "Honeyed Lie",
		"description": "Ultimate applies 4 Poison stacks for 8 seconds.",
		"rarity": "Uncommon",
		"target_action": "Ultimate",
		"trigger": "on_hit",
		"effect_type": "apply_status",
		"status_id": "poison",
		"stacks": 4,
		"duration": 8.0,
		"flat_value": 0.0,
		"multiplier_value": 1.0
	},

	{
		"boon_id": "ugolino_hunger",
		"witness_id": "ugolino",
		"witness_name": "Ugolino",
		"display_name": "Hunger",
		"description": "Kills restore 2 HP.",
		"rarity": "Rare",
		"target_action": "On Kill",
		"trigger": "on_kill",
		"effect_type": "on_kill_heal_flat",
		"status_id": "",
		"stacks": 0,
		"duration": 0.0,
		"flat_value": 2.0,
		"multiplier_value": 1.0
	},
	{
		"boon_id": "ugolino_blood_supper",
		"witness_id": "ugolino",
		"witness_name": "Ugolino",
		"display_name": "Blood Supper",
		"description": "Heavy attacks against Bleeding enemies restore 1.5 HP.",
		"rarity": "Uncommon",
		"target_action": "Heavy",
		"trigger": "on_hit",
		"effect_type": "heal_on_hit_vs_status",
		"status_id": "bleed",
		"stacks": 0,
		"duration": 0.0,
		"flat_value": 1.5,
		"multiplier_value": 1.0
	},

	{
		"boon_id": "virgil_measured_escape",
		"witness_id": "virgil",
		"witness_name": "Virgil",
		"display_name": "Measured Escape",
		"description": "Perfect dodges grant +10 ultimate charge.",
		"rarity": "Common",
		"target_action": "Dodge",
		"trigger": "perfect_dodge",
		"effect_type": "perfect_dodge_ultimate_flat",
		"status_id": "",
		"stacks": 0,
		"duration": 0.0,
		"flat_value": 10.0,
		"multiplier_value": 1.0
	}
]

@export var boss_depth := 6

var in_run := false
var depth := 0
var current_room_type := ""
var boss_defeated := false
var room_history: Array = []
var last_offers: Array[String] = []

var rng := RandomNumberGenerator.new()

var upgrade_pool: Array[RunUpgradeData] = []
var chosen_upgrade_ids: Array[String] = []
var chosen_upgrade_names: Array[String] = []

var modifiers := {
	"max_hp_flat": 0.0,
	"max_armor_flat": 0.0,
	"move_speed_mult": 1.0,
	"dash_cooldown_mult": 1.0,
	"ultimate_gain_mult": 1.0,
	"light_damage_flat": 0.0,
	"heavy_radius_mult": 1.0,
	"q_damage_mult": 1.0,
	"ultimate_cost_mult": 1.0
}

var has_saved_player_vitals: bool = false
var saved_player_hp: float = 0.0
var saved_player_armor: float = 0.0

var chosen_boon_ids: Array[String] = []
var chosen_boon_names: Array[String] = []

var boon_modifiers := {
	"light_damage_mult": 1.0,
	"heavy_damage_mult": 1.0,
	"q_damage_mult": 1.0,
	"ultimate_damage_mult": 1.0,
	"perfect_dodge_ultimate_flat": 0.0,
	"on_kill_heal_flat": 0.0
}


func _ready() -> void:
	rng.randomize()


func start_run() -> void:
	in_run = true
	depth = 1
	current_room_type = ROOM_COMBAT
	boss_defeated = false
	room_history.clear()
	last_offers.clear()

	reset_player_vitals()
	_reset_run_upgrades()

	room_history.append({
		"event": "start",
		"depth": depth,
		"room_type": current_room_type
	})


func end_run() -> void:
	in_run = false
	depth = 0
	current_room_type = ""
	boss_defeated = false
	last_offers.clear()

	_reset_run_upgrades()
	reset_player_vitals()


func choose_room(room_type: String) -> void:
	if room_type == "":
		return

	if not in_run:
		start_run()

	depth += 1
	current_room_type = room_type

	room_history.append({
		"event": "enter",
		"depth": depth,
		"room_type": current_room_type
	})


func generate_offers_after_clear() -> Array[String]:
	last_offers.clear()

	if not in_run:
		return last_offers.duplicate()

	room_history.append({
		"event": "clear",
		"depth": depth,
		"room_type": current_room_type
	})

	if current_room_type == ROOM_BOSS:
		boss_defeated = true
		last_offers.append(ROOM_FOUNTAIN)
		return last_offers.duplicate()

	if current_room_type == ROOM_FOUNTAIN:
		return last_offers.duplicate()

	var next_depth := depth + 1

	if not boss_defeated and next_depth >= boss_depth:
		last_offers.append(ROOM_BOSS)
		return last_offers.duplicate()

	last_offers = _generate_weighted_offers(3)
	return last_offers.duplicate()


func _generate_weighted_offers(count: int) -> Array[String]:
	var offers: Array[String] = []
	var excluded: Array[String] = []

	while offers.size() < count:
		var picked := _pick_weighted_room(excluded)

		if picked == "":
			break

		offers.append(picked)
		excluded.append(picked)

	while offers.size() < count:
		offers.append(ROOM_COMBAT)

	return offers


func _pick_weighted_room(excluded: Array[String]) -> String:
	var total_weight := 0

	for entry in WEIGHTED_ROOM_TABLE:
		var room_type := str(entry["type"])
		var weight := int(entry["weight"])

		if not excluded.has(room_type):
			total_weight += weight

	if total_weight <= 0:
		return ""

	var roll := rng.randi_range(1, total_weight)
	var cursor := 0

	for entry in WEIGHTED_ROOM_TABLE:
		var room_type := str(entry["type"])
		var weight := int(entry["weight"])

		if excluded.has(room_type):
			continue

		cursor += weight

		if roll <= cursor:
			return room_type

	return ROOM_COMBAT


func generate_upgrade_offers(count: int = 3) -> Array[RunUpgradeData]:
	_ensure_upgrade_pool_loaded()

	var available: Array[RunUpgradeData] = []

	for upgrade in upgrade_pool:
		if upgrade == null:
			continue

		if chosen_upgrade_ids.has(upgrade.upgrade_id):
			continue

		available.append(upgrade)

	var offers: Array[RunUpgradeData] = []

	while offers.size() < count and not available.is_empty():
		var picked_index := _pick_weighted_upgrade_index(available)
		var picked_upgrade := available[picked_index]
		offers.append(picked_upgrade)
		available.remove_at(picked_index)

	return offers


func apply_upgrade(upgrade: RunUpgradeData) -> void:
	if upgrade == null:
		return

	if upgrade.upgrade_id == "":
		return

	if chosen_upgrade_ids.has(upgrade.upgrade_id):
		return

	chosen_upgrade_ids.append(upgrade.upgrade_id)
	chosen_upgrade_names.append(upgrade.display_name)

	match upgrade.effect_type:
		"max_hp_flat":
			modifiers["max_hp_flat"] = float(modifiers["max_hp_flat"]) + upgrade.flat_value

		"max_armor_flat":
			modifiers["max_armor_flat"] = float(modifiers["max_armor_flat"]) + upgrade.flat_value

		"move_speed_mult":
			modifiers["move_speed_mult"] = float(modifiers["move_speed_mult"]) * upgrade.multiplier_value

		"dash_cooldown_mult":
			modifiers["dash_cooldown_mult"] = float(modifiers["dash_cooldown_mult"]) * upgrade.multiplier_value

		"ultimate_gain_mult":
			modifiers["ultimate_gain_mult"] = float(modifiers["ultimate_gain_mult"]) * upgrade.multiplier_value

		"light_damage_flat":
			modifiers["light_damage_flat"] = float(modifiers["light_damage_flat"]) + upgrade.flat_value

		"heavy_radius_mult":
			modifiers["heavy_radius_mult"] = float(modifiers["heavy_radius_mult"]) * upgrade.multiplier_value

		"q_damage_mult":
			modifiers["q_damage_mult"] = float(modifiers["q_damage_mult"]) * upgrade.multiplier_value

		"ultimate_cost_mult":
			modifiers["ultimate_cost_mult"] = float(modifiers["ultimate_cost_mult"]) * upgrade.multiplier_value

		_:
			push_warning("Unknown upgrade effect_type '%s' on upgrade '%s'." % [upgrade.effect_type, upgrade.upgrade_id])


func get_modifier_value(modifier_name: String, fallback: float = 0.0) -> float:
	if not modifiers.has(modifier_name):
		return fallback

	return float(modifiers[modifier_name])


func reset_player_vitals() -> void:
	has_saved_player_vitals = false
	saved_player_hp = 0.0
	saved_player_armor = 0.0


func save_player_vitals(new_hp: float, new_armor: float) -> void:
	has_saved_player_vitals = true
	saved_player_hp = maxf(0.0, new_hp)
	saved_player_armor = maxf(0.0, new_armor)


func get_saved_player_vitals(default_hp: float, default_armor: float) -> Dictionary:
	if not has_saved_player_vitals:
		return {
			"hp": default_hp,
			"armor": default_armor
		}

	return {
		"hp": saved_player_hp,
		"armor": saved_player_armor
	}


func get_upgrade_summary_text() -> String:
	if chosen_upgrade_names.is_empty():
		return "None"

	var text := ""

	for i in range(chosen_upgrade_names.size()):
		if i > 0:
			text += ", "

		text += chosen_upgrade_names[i]

	return text


func get_enemy_count_for_room(room_type: String, room_depth: int) -> int:
	var safe_depth: int = maxi(room_depth, 1)

	match room_type:
		ROOM_BOSS:
			return 1

		ROOM_ELITE:
			if safe_depth >= 5:
				return 3

			return 2

		ROOM_MINIBOSS:
			return 2

		ROOM_UPGRADE, ROOM_FORGE, ROOM_SHRINE:
			var reward_room_count: int = 2 + int(floor(float(safe_depth - 1) / 3.0))
			return mini(reward_room_count, 4)

		_:
			var count: int = 3 + int(floor(float(safe_depth - 1) / 2.0))
			return mini(count, 5)


func get_enemy_stats_for_room(room_type: String, room_depth: int) -> Dictionary:
	var safe_depth: int = maxi(room_depth, 1)
	var depth_bonus: float = float(safe_depth - 1)

	var hp: float = 30.0 + depth_bonus * 7.0
	var damage: float = 5.0 + depth_bonus * 1.35
	var speed: float = 90.0 + minf(depth_bonus * 4.0, 24.0)
	var contact_radius: float = 28.0
	var rank: String = "normal"

	if room_type == ROOM_ELITE:
		hp = 55.0 + depth_bonus * 11.0
		damage = 7.0 + depth_bonus * 1.8
		speed = 95.0 + minf(depth_bonus * 4.0, 26.0)
		contact_radius = 30.0
		rank = "elite"

	elif room_type == ROOM_MINIBOSS:
		hp = 110.0 + depth_bonus * 16.0
		damage = 9.0 + depth_bonus * 2.0
		speed = 80.0 + minf(depth_bonus * 2.0, 14.0)
		contact_radius = 34.0
		rank = "miniboss"

	elif room_type == ROOM_BOSS:
		hp = 260.0 + depth_bonus * 28.0
		damage = 12.0 + depth_bonus * 2.2
		speed = 72.0 + minf(depth_bonus * 1.5, 10.0)
		contact_radius = 42.0
		rank = "boss"

	elif room_type == ROOM_FORGE:
		hp = 45.0 + depth_bonus * 9.0
		damage = 6.0 + depth_bonus * 1.45
		speed = 82.0 + minf(depth_bonus * 3.0, 18.0)
		contact_radius = 30.0
		rank = "normal"

	elif room_type == ROOM_SHRINE:
		hp = 40.0 + depth_bonus * 8.0
		damage = 6.0 + depth_bonus * 1.55
		speed = 92.0 + minf(depth_bonus * 4.0, 22.0)
		contact_radius = 28.0
		rank = "normal"

	elif room_type == ROOM_UPGRADE:
		hp = 34.0 + depth_bonus * 7.0
		damage = 5.0 + depth_bonus * 1.30
		speed = 90.0 + minf(depth_bonus * 4.0, 22.0)
		contact_radius = 28.0
		rank = "normal"

	return {
		"max_hp": hp,
		"damage": damage,
		"speed": speed,
		"contact_radius": contact_radius,
		"rank": rank
	}


func get_combat_debug_text(room_type: String, room_depth: int) -> String:
	var stats: Dictionary = get_enemy_stats_for_room(room_type, room_depth)
	var count: int = get_enemy_count_for_room(room_type, room_depth)

	return "%d enemies | HP %d | DMG %d | Boons: %s" % [
		count,
		ceil(float(stats["max_hp"])),
		ceil(float(stats["damage"])),
		get_boon_summary_text()
	]


func generate_boon_offers(count: int = 3) -> Array[Dictionary]:
	var available: Array[Dictionary] = []

	for boon in BOON_POOL:
		var boon_id: String = str(boon.get("boon_id", ""))

		if boon_id == "":
			continue

		if chosen_boon_ids.has(boon_id):
			continue

		available.append(boon)

	var offers: Array[Dictionary] = []

	while offers.size() < count and not available.is_empty():
		var picked_index: int = _pick_weighted_boon_index(available)
		var picked_boon: Dictionary = available[picked_index]
		offers.append(picked_boon)
		available.remove_at(picked_index)

	return offers

func debug_get_boon_pool() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for boon in BOON_POOL:
		result.append(boon)

	return result


func debug_get_selected_boons() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for boon_id in chosen_boon_ids:
		var boon: Dictionary = get_boon_data_by_id(str(boon_id))

		if not boon.is_empty():
			result.append(boon)

	return result


func debug_add_boon_by_id(boon_id: String) -> bool:
	for boon in BOON_POOL:
		if str(boon.get("boon_id", "")) == boon_id:
			apply_boon(boon)
			return true

	return false


func debug_remove_boon_by_id(boon_id: String) -> bool:
	if not chosen_boon_ids.has(boon_id):
		return false

	var remaining_boon_ids: Array[String] = []

	for existing_boon_id in chosen_boon_ids:
		if str(existing_boon_id) != boon_id:
			remaining_boon_ids.append(str(existing_boon_id))

	chosen_boon_ids.clear()
	chosen_boon_names.clear()
	_reset_boon_modifiers_only()

	for remaining_id in remaining_boon_ids:
		var boon: Dictionary = get_boon_data_by_id(remaining_id)

		if not boon.is_empty():
			apply_boon(boon)

	return true


func debug_clear_boons() -> void:
	chosen_boon_ids.clear()
	chosen_boon_names.clear()
	_reset_boon_modifiers_only()


func _reset_boon_modifiers_only() -> void:
	boon_modifiers["light_damage_mult"] = 1.0
	boon_modifiers["heavy_damage_mult"] = 1.0
	boon_modifiers["q_damage_mult"] = 1.0
	boon_modifiers["ultimate_damage_mult"] = 1.0
	boon_modifiers["perfect_dodge_ultimate_flat"] = 0.0
	boon_modifiers["on_kill_heal_flat"] = 0.0

func apply_boon(boon: Dictionary) -> void:
	var boon_id: String = str(boon.get("boon_id", ""))

	if boon_id == "":
		return

	if chosen_boon_ids.has(boon_id):
		return

	chosen_boon_ids.append(boon_id)
	chosen_boon_names.append(str(boon.get("display_name", "Unknown Boon")))

	var effect_type: String = str(boon.get("effect_type", ""))
	var flat_value: float = float(boon.get("flat_value", 0.0))
	var multiplier_value: float = float(boon.get("multiplier_value", 1.0))

	match effect_type:
		"light_damage_mult":
			boon_modifiers["light_damage_mult"] = float(boon_modifiers["light_damage_mult"]) * multiplier_value

		"heavy_damage_mult":
			boon_modifiers["heavy_damage_mult"] = float(boon_modifiers["heavy_damage_mult"]) * multiplier_value

		"q_damage_mult":
			boon_modifiers["q_damage_mult"] = float(boon_modifiers["q_damage_mult"]) * multiplier_value

		"ultimate_damage_mult":
			boon_modifiers["ultimate_damage_mult"] = float(boon_modifiers["ultimate_damage_mult"]) * multiplier_value

		"perfect_dodge_ultimate_flat":
			boon_modifiers["perfect_dodge_ultimate_flat"] = float(boon_modifiers["perfect_dodge_ultimate_flat"]) + flat_value

		"on_kill_heal_flat":
			boon_modifiers["on_kill_heal_flat"] = float(boon_modifiers["on_kill_heal_flat"]) + flat_value

		"apply_status":
			pass

		"bonus_damage_vs_status":
			pass

		"detonate_status_damage":
			pass
			"spread_status_on_hit"
			pass

		"execute_status_below_ratio":
			pass

		"heal_on_hit_vs_status":
			pass
		_:
			push_warning("Unknown boon effect_type: %s" % effect_type)


func get_boon_data_by_id(boon_id: String) -> Dictionary:
	for boon in BOON_POOL:
		if str(boon.get("boon_id", "")) == boon_id:
			return boon

	return {}

func get_on_hit_effects_by_type(kind: String, requested_effect_type: String) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var action_name: String = _get_action_name_from_attack_kind(kind)

	for boon_id in chosen_boon_ids:
		var boon: Dictionary = get_boon_data_by_id(str(boon_id))

		if boon.is_empty():
			continue

		if str(boon.get("trigger", "")) != "on_hit":
			continue

		if str(boon.get("effect_type", "")) != requested_effect_type:
			continue

		if str(boon.get("target_action", "")) != action_name:
			continue

		effects.append(boon)

	return effects

func get_on_hit_status_effects(kind: String) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var action_name: String = _get_action_name_from_attack_kind(kind)

	for boon_id in chosen_boon_ids:
		var boon: Dictionary = get_boon_data_by_id(str(boon_id))

		if boon.is_empty():
			continue

		if str(boon.get("trigger", "")) != "on_hit":
			continue

		if str(boon.get("effect_type", "")) != "apply_status":
			continue

		if str(boon.get("target_action", "")) != action_name:
			continue

		effects.append(boon)

	return effects


func get_bonus_damage_multiplier_for_target(kind: String, target: Object) -> float:
	var multiplier: float = 1.0
	var action_name: String = _get_action_name_from_attack_kind(kind)

	for boon_id in chosen_boon_ids:
		var boon: Dictionary = get_boon_data_by_id(str(boon_id))

		if boon.is_empty():
			continue

		if str(boon.get("trigger", "")) != "on_hit":
			continue

		if str(boon.get("effect_type", "")) != "bonus_damage_vs_status":
			continue

		if str(boon.get("target_action", "")) != action_name:
			continue

		var status_id: String = str(boon.get("status_id", ""))

		if status_id == "":
			continue

		if target != null and target.has_method("has_status"):
			if bool(target.call("has_status", status_id)):
				multiplier *= float(boon.get("multiplier_value", 1.0))

	return multiplier


func _get_action_name_from_attack_kind(kind: String) -> String:
	if kind in ["light", "light_1", "light_2", "light_3"]:
		return "Light"

	if kind == "heavy":
		return "Heavy"

	if kind == "q":
		return "Q"

	if kind == "ultimate":
		return "Ultimate"

	return kind.capitalize()


func get_attack_damage_multiplier(kind: String) -> float:
	if kind in ["light", "light_1", "light_2", "light_3"]:
		return float(boon_modifiers["light_damage_mult"])

	if kind == "heavy":
		return float(boon_modifiers["heavy_damage_mult"])

	if kind == "q":
		return float(boon_modifiers["q_damage_mult"])

	if kind == "ultimate":
		return float(boon_modifiers["ultimate_damage_mult"])

	return 1.0

func get_on_hit_status_detonations(kind: String) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var action_name: String = _get_action_name_from_attack_kind(kind)

	for boon_id in chosen_boon_ids:
		var boon: Dictionary = get_boon_data_by_id(str(boon_id))

		if boon.is_empty():
			continue

		if str(boon.get("trigger", "")) != "on_hit":
			continue

		if str(boon.get("effect_type", "")) != "detonate_status_damage":
			continue

		if str(boon.get("target_action", "")) != action_name:
			continue

		effects.append(boon)

	return effects

func get_perfect_dodge_ultimate_bonus() -> float:
	return float(boon_modifiers["perfect_dodge_ultimate_flat"])


func get_on_kill_heal_bonus() -> float:
	return float(boon_modifiers["on_kill_heal_flat"])


func get_boon_summary_text() -> String:
	if chosen_boon_names.is_empty():
		return "None"

	var text := ""

	for i in range(chosen_boon_names.size()):
		if i > 0:
			text += ", "

		text += chosen_boon_names[i]

	return text


func _pick_weighted_boon_index(boons: Array[Dictionary]) -> int:
	var total_weight := 0

	for boon in boons:
		total_weight += _get_boon_rarity_weight(str(boon.get("rarity", "Common")))

	if total_weight <= 0:
		return rng.randi_range(0, boons.size() - 1)

	var roll := rng.randi_range(1, total_weight)
	var cursor := 0

	for i in range(boons.size()):
		cursor += _get_boon_rarity_weight(str(boons[i].get("rarity", "Common")))

		if roll <= cursor:
			return i

	return 0


func _get_boon_rarity_weight(rarity: String) -> int:
	match rarity:
		"Common":
			return 70

		"Uncommon":
			return 24

		"Rare":
			return 6

		_:
			return 50


func _ensure_upgrade_pool_loaded() -> void:
	if not upgrade_pool.is_empty():
		return

	upgrade_pool.append(UPGRADE_IRON_LUNG)
	upgrade_pool.append(UPGRADE_ASHEN_PLATE)
	upgrade_pool.append(UPGRADE_PILGRIM_STRIDE)
	upgrade_pool.append(UPGRADE_QUICKENED_STEP)
	upgrade_pool.append(UPGRADE_BURNING_CONFESSION)
	upgrade_pool.append(UPGRADE_PENANCE_ENGINE)
	upgrade_pool.append(UPGRADE_HEAVY_ABSOLUTION)
	upgrade_pool.append(UPGRADE_JUDGMENT_DASH)
	upgrade_pool.append(UPGRADE_CHEAP_RAPTURE)


func _pick_weighted_upgrade_index(upgrades: Array[RunUpgradeData]) -> int:
	var total_weight := 0

	for upgrade in upgrades:
		total_weight += _get_upgrade_rarity_weight(upgrade.rarity)

	if total_weight <= 0:
		return rng.randi_range(0, upgrades.size() - 1)

	var roll := rng.randi_range(1, total_weight)
	var cursor := 0

	for i in range(upgrades.size()):
		cursor += _get_upgrade_rarity_weight(upgrades[i].rarity)

		if roll <= cursor:
			return i

	return 0


func _get_upgrade_rarity_weight(rarity: String) -> int:
	match rarity:
		"Common":
			return 70

		"Uncommon":
			return 24

		"Rare":
			return 6

		_:
			return 50


func _reset_run_upgrades() -> void:
	chosen_upgrade_ids.clear()
	chosen_upgrade_names.clear()
	chosen_boon_ids.clear()
	chosen_boon_names.clear()

	modifiers["max_hp_flat"] = 0.0
	modifiers["max_armor_flat"] = 0.0
	modifiers["move_speed_mult"] = 1.0
	modifiers["dash_cooldown_mult"] = 1.0
	modifiers["ultimate_gain_mult"] = 1.0
	modifiers["light_damage_flat"] = 0.0
	modifiers["heavy_radius_mult"] = 1.0
	modifiers["q_damage_mult"] = 1.0
	modifiers["ultimate_cost_mult"] = 1.0

	boon_modifiers["light_damage_mult"] = 1.0
	boon_modifiers["heavy_damage_mult"] = 1.0
	boon_modifiers["q_damage_mult"] = 1.0
	boon_modifiers["ultimate_damage_mult"] = 1.0
	boon_modifiers["perfect_dodge_ultimate_flat"] = 0.0
	boon_modifiers["on_kill_heal_flat"] = 0.0


func is_combat_room_type(room_type: String) -> bool:
	return room_type == ROOM_COMBAT \
		or room_type == ROOM_ELITE \
		or room_type == ROOM_MINIBOSS \
		or room_type == ROOM_BOSS \
		or room_type == ROOM_UPGRADE \
		or room_type == ROOM_FORGE \
		or room_type == ROOM_SHRINE \
		or room_type == ROOM_WITNESS


func is_reward_room_type(room_type: String) -> bool:
	return room_type == ROOM_SHOP \
		or room_type == ROOM_FOUNTAIN


func get_room_display_name(room_type: String) -> String:
	match room_type:
		ROOM_COMBAT:
			return "Combat"

		ROOM_UPGRADE:
			return "Upgrade"

		ROOM_SHOP:
			return "Shop"

		ROOM_FORGE:
			return "Forge"

		ROOM_SHRINE:
			return "Shrine"

		ROOM_ELITE:
			return "Elite"

		ROOM_MINIBOSS:
			return "Miniboss"

		ROOM_BOSS:
			return "Boss"

		ROOM_FOUNTAIN:
			return "Fountain"

		ROOM_WITNESS:
			return "Witness"

		_:
			return "Unknown"
