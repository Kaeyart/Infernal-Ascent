extends RefCounted
class_name PermanentUpgradeData

## V27 — Permanent Upgrade V1.
## V28 — Save System V1 serialization support.
## Permanent upgrades are now saved to disk through SaveGameData.

const UPGRADE_ORDER: Array[String] = [
	"max_hp",
	"starting_damage",
	"dash_efficiency",
	"ash_sigil_bonus",
	"reward_choice",
]

const UPGRADE_DEFS: Dictionary = {
	"max_hp": {
		"slot": 1,
		"name": "Iron Vow",
		"short": "+Max HP",
		"description": "Start each run with +1 max HP per level.",
		"max_level": 5,
		"base_cost": 2,
		"cost_step": 2,
	},
	"starting_damage": {
		"slot": 2,
		"name": "Executioner's Edge",
		"short": "+Starting Damage",
		"description": "Start each run with +1 light and heavy attack damage per level.",
		"max_level": 4,
		"base_cost": 3,
		"cost_step": 3,
	},
	"dash_efficiency": {
		"slot": 3,
		"name": "Ashen Footwork",
		"short": "Dash Cooldown Down",
		"description": "Start each run with dash cooldown reduced by 0.04s per level.",
		"max_level": 4,
		"base_cost": 2,
		"cost_step": 2,
	},
	"ash_sigil_bonus": {
		"slot": 4,
		"name": "Pilgrim's Tithe",
		"short": "+Ash Sigil Bonus",
		"description": "Gain +1 bonus Ash Sigil on run outcome per level and +1 starting Run Ash per level.",
		"max_level": 3,
		"base_cost": 4,
		"cost_step": 4,
	},
	"reward_choice": {
		"slot": 5,
		"name": "Relic Sense",
		"short": "Better Reward Choice",
		"description": "At level 1+, reward rooms offer a fourth pedestal when space allows.",
		"max_level": 1,
		"base_cost": 6,
		"cost_step": 0,
	},
}

static var upgrade_levels: Dictionary = {
	"max_hp": 0,
	"starting_damage": 0,
	"dash_efficiency": 0,
	"ash_sigil_bonus": 0,
	"reward_choice": 0,
}

static func get_upgrade_ids() -> Array[String]:
	return UPGRADE_ORDER.duplicate()

static func get_upgrade_id_for_slot(slot: int) -> String:
	for upgrade_id: String in UPGRADE_ORDER:
		var data: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
		if int(data.get("slot", -1)) == slot:
			return upgrade_id
	return ""

static func get_upgrade_def(upgrade_id: String) -> Dictionary:
	return UPGRADE_DEFS.get(upgrade_id, {}).duplicate(true)

static func get_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))

static func get_max_level(upgrade_id: String) -> int:
	var data: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	return int(data.get("max_level", 0))

static func is_maxed(upgrade_id: String) -> bool:
	return get_level(upgrade_id) >= get_max_level(upgrade_id)

static func get_cost(upgrade_id: String) -> int:
	if is_maxed(upgrade_id):
		return 0
	var data: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
	var base_cost: int = int(data.get("base_cost", 1))
	var cost_step: int = int(data.get("cost_step", 1))
	return maxi(1, base_cost + get_level(upgrade_id) * cost_step)

static func can_purchase(upgrade_id: String) -> bool:
	if not UPGRADE_DEFS.has(upgrade_id):
		return false
	if is_maxed(upgrade_id):
		return false
	return RunEconomyData.can_spend_ash_sigils(get_cost(upgrade_id))

static func purchase_upgrade(upgrade_id: String) -> Dictionary:
	if not UPGRADE_DEFS.has(upgrade_id):
		return {"ok": false, "message": "Unknown upgrade."}
	if is_maxed(upgrade_id):
		return {"ok": false, "message": "%s is already maxed." % str(UPGRADE_DEFS[upgrade_id].get("name", upgrade_id))}
	var cost: int = get_cost(upgrade_id)
	if not RunEconomyData.can_spend_ash_sigils(cost):
		return {"ok": false, "message": "Not enough Ash Sigils. Need %d." % cost}
	if not RunEconomyData.spend_ash_sigils(cost):
		return {"ok": false, "message": "Purchase failed."}
	upgrade_levels[upgrade_id] = get_level(upgrade_id) + 1
	return {
		"ok": true,
		"message": "Purchased %s Lv.%d." % [str(UPGRADE_DEFS[upgrade_id].get("name", upgrade_id)), get_level(upgrade_id)],
		"upgrade_id": upgrade_id,
		"level": get_level(upgrade_id),
		"cost": cost,
	}


static func to_save_dict() -> Dictionary:
	return {
		"upgrade_levels": upgrade_levels.duplicate(true),
	}

static func apply_save_dict(data: Dictionary) -> void:
	var saved_levels: Dictionary = data.get("upgrade_levels", {}) as Dictionary
	for upgrade_id: String in UPGRADE_ORDER:
		var raw_level: int = int(saved_levels.get(upgrade_id, 0))
		upgrade_levels[upgrade_id] = clampi(raw_level, 0, get_max_level(upgrade_id))

static func reset_upgrades() -> void:
	for upgrade_id: String in UPGRADE_ORDER:
		upgrade_levels[upgrade_id] = 0

static func apply_to_player(player: Node) -> void:
	if player == null:
		return
	var hp_bonus: int = get_level("max_hp")
	var damage_bonus: int = get_level("starting_damage")
	var dash_level: int = get_level("dash_efficiency")

	if hp_bonus > 0 and player.get("max_health") != null:
		player.set("max_health", int(player.get("max_health")) + hp_bonus)
		if player.get("current_health") != null:
			player.set("current_health", int(player.get("max_health")))

	if damage_bonus > 0:
		if player.get("attack_damage") != null:
			player.set("attack_damage", int(player.get("attack_damage")) + damage_bonus)
		if player.get("heavy_attack_damage") != null:
			player.set("heavy_attack_damage", int(player.get("heavy_attack_damage")) + damage_bonus)

	if dash_level > 0 and player.get("dash_cooldown") != null:
		var current_cd: float = float(player.get("dash_cooldown"))
		player.set("dash_cooldown", maxf(0.24, current_cd - 0.04 * float(dash_level)))

	if player is CanvasItem:
		(player as CanvasItem).queue_redraw()

static func get_run_start_modifiers() -> Dictionary:
	var ash_level: int = get_level("ash_sigil_bonus")
	var reward_level: int = get_level("reward_choice")
	return {
		"bonus_outcome_sigils": ash_level,
		"bonus_starting_run_ash": ash_level,
		"bonus_reward_choices": 1 if reward_level > 0 else 0,
	}

static func build_upgrade_panel_text(last_message: String = "") -> String:
	var lines: Array[String] = []
	lines.append("RELIQUARY ALTAR")
	lines.append("")
	lines.append("Spend Ash Sigils on permanent upgrades.")
	lines.append("These upgrades now persist after quitting through the V28 save system.")
	lines.append("")
	lines.append(RunEconomyData.get_currency_summary_line())
	if last_message.strip_edges() != "":
		lines.append("")
		lines.append(last_message)
	lines.append("")
	lines.append("Press 1–5 to purchase:")
	lines.append("")
	for upgrade_id: String in UPGRADE_ORDER:
		var data: Dictionary = UPGRADE_DEFS.get(upgrade_id, {})
		var slot: int = int(data.get("slot", 0))
		var level: int = get_level(upgrade_id)
		var max_level: int = get_max_level(upgrade_id)
		var status: String = "MAX" if level >= max_level else "Cost %d" % get_cost(upgrade_id)
		lines.append("%d. %s Lv.%d/%d — %s" % [slot, str(data.get("name", upgrade_id)), level, max_level, status])
		lines.append("   %s" % str(data.get("description", "")))
	lines.append("")
	lines.append("Current run-start bonuses:")
	lines.append("- Max HP +%d" % get_level("max_hp"))
	lines.append("- Starting attack damage +%d" % get_level("starting_damage"))
	lines.append("- Dash cooldown -%.2fs" % (0.04 * float(get_level("dash_efficiency"))))
	lines.append("- Outcome Ash Sigils +%d" % get_level("ash_sigil_bonus"))
	lines.append("- Reward choices: %s" % ("+1 pedestal" if get_level("reward_choice") > 0 else "standard"))
	return "\n".join(lines)

static func build_summary_line() -> String:
	return "Upgrades: HP +%d | DMG +%d | Dash -%.2fs | Sigils +%d | Rewards %s" % [
		get_level("max_hp"),
		get_level("starting_damage"),
		0.04 * float(get_level("dash_efficiency")),
		get_level("ash_sigil_bonus"),
		"+1" if get_level("reward_choice") > 0 else "std",
	]
