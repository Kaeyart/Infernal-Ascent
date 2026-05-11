extends Node

var selected_weapon: WeaponData = null

var broken_souls: int = 0
var lifetime_broken_souls: int = 0

var total_runs_started: int = 0
var total_deaths: int = 0
var total_enemies_killed: int = 0

var enemies_killed_by_kind: Dictionary = {}

var permanent_upgrades: Dictionary = {
	"max_hp": 0,
	"max_armor": 0,
	"move_speed": 0
}

const PERMANENT_UPGRADE_MAX_LEVELS: Dictionary = {
	"max_hp": 10,
	"max_armor": 10,
	"move_speed": 8
}

const PERMANENT_UPGRADE_BASE_COSTS: Dictionary = {
	"max_hp": 18,
	"max_armor": 14,
	"move_speed": 22
}


func record_run_started() -> void:
	total_runs_started += 1


func record_death() -> void:
	total_deaths += 1


func add_broken_souls(amount: int) -> void:
	var safe_amount: int = max(0, amount)

	broken_souls += safe_amount
	lifetime_broken_souls += safe_amount


func spend_broken_souls(amount: int) -> bool:
	var safe_amount: int = max(0, amount)

	if broken_souls < safe_amount:
		return false

	broken_souls -= safe_amount
	return true


func get_broken_souls() -> int:
	return broken_souls


func record_enemy_kill(enemy_kind: String, enemy_rank: String = "normal") -> void:
	var safe_kind := enemy_kind.strip_edges()

	if safe_kind == "":
		safe_kind = "unknown"

	total_enemies_killed += 1

	var previous_count: int = int(enemies_killed_by_kind.get(safe_kind, 0))
	enemies_killed_by_kind[safe_kind] = previous_count + 1


func get_enemy_kill_count(enemy_kind: String) -> int:
	return int(enemies_killed_by_kind.get(enemy_kind, 0))


func get_enemy_display_name(enemy_kind: String) -> String:
	match enemy_kind:
		"imp":
			return "Lesser Imp"
		"goblin":
			return "Malformed Wretch"
		"skelet":
			return "Bonebound Shade"
		"chort":
			return "Horned Chort"
		"masked_orc":
			return "Masked Brute"
		"big_zombie":
			return "Swollen Dead"
		"ogre":
			return "Ogre of the Pit"
		"big_demon":
			return "Greater Demon"
		_:
			return enemy_kind.capitalize()


func get_codex_stage(enemy_kind: String) -> int:
	var kills: int = get_enemy_kill_count(enemy_kind)

	if kills >= 10:
		return 3

	if kills >= 5:
		return 2

	if kills >= 1:
		return 1

	return 0


func get_codex_stage_name(enemy_kind: String) -> String:
	match get_codex_stage(enemy_kind):
		3:
			return "Complete"
		2:
			return "Studied"
		1:
			return "Discovered"
		_:
			return "Unknown"


func get_codex_summary_lines() -> Array[String]:
	var lines: Array[String] = []

	lines.append("Codex records: %d enemy kills." % total_enemies_killed)

	if enemies_killed_by_kind.is_empty():
		lines.append("No enemy has earned an entry yet.")
		lines.append("Kill something in the rooms below. Then I will have ink to waste.")
		return lines

	var known_kinds := enemies_killed_by_kind.keys()
	known_kinds.sort()

	var shown: int = 0

	for kind in known_kinds:
		if shown >= 4:
			break

		var enemy_kind := str(kind)
		var count: int = get_enemy_kill_count(enemy_kind)
		var display_name := get_enemy_display_name(enemy_kind)
		var stage_name := get_codex_stage_name(enemy_kind)

		lines.append("%s — %d killed — %s." % [display_name, count, stage_name])
		shown += 1

	if known_kinds.size() > shown:
		lines.append("There are more entries, but the page is crowded.")

	lines.append("At 1 kill, I name it. At 5, I understand it. At 10, I finish the entry.")

	return lines


func get_permanent_upgrade_level(upgrade_id: String) -> int:
	return int(permanent_upgrades.get(upgrade_id, 0))


func get_permanent_upgrade_max_level(upgrade_id: String) -> int:
	return int(PERMANENT_UPGRADE_MAX_LEVELS.get(upgrade_id, 0))


func get_permanent_upgrade_cost(upgrade_id: String) -> int:
	var level: int = get_permanent_upgrade_level(upgrade_id)
	var base_cost: int = int(PERMANENT_UPGRADE_BASE_COSTS.get(upgrade_id, 20))

	return base_cost + level * base_cost


func get_permanent_upgrade_display_name(upgrade_id: String) -> String:
	match upgrade_id:
		"max_hp":
			return "Sinew of Remorse"
		"max_armor":
			return "Ashen Guard"
		"move_speed":
			return "Pilgrim's Step"
		_:
			return upgrade_id.capitalize()


func get_permanent_upgrade_description(upgrade_id: String) -> String:
	match upgrade_id:
		"max_hp":
			return "+10 maximum HP per level."
		"max_armor":
			return "+5 maximum armor per level."
		"move_speed":
			return "+3% movement speed per level."
		_:
			return "Unknown permanent upgrade."


func buy_permanent_upgrade(upgrade_id: String) -> Dictionary:
	if not permanent_upgrades.has(upgrade_id):
		return {
			"success": false,
			"message": "The Smith does not know that upgrade."
		}

	var level: int = get_permanent_upgrade_level(upgrade_id)
	var max_level: int = get_permanent_upgrade_max_level(upgrade_id)

	if level >= max_level:
		return {
			"success": false,
			"message": "%s is already fully shaped." % get_permanent_upgrade_display_name(upgrade_id)
		}

	var cost: int = get_permanent_upgrade_cost(upgrade_id)

	if not spend_broken_souls(cost):
		return {
			"success": false,
			"message": "Not enough Broken Souls. Need %d." % cost
		}

	permanent_upgrades[upgrade_id] = level + 1

	return {
		"success": true,
		"message": "%s improved to level %d." % [
			get_permanent_upgrade_display_name(upgrade_id),
			level + 1
		]
	}


func get_smith_offer_lines() -> Array[String]:
	var lines: Array[String] = []

	lines.append("Broken Souls carried: %d." % broken_souls)
	lines.append("[1] %s Lv.%d/%d — Cost %d — %s" % [
		get_permanent_upgrade_display_name("max_hp"),
		get_permanent_upgrade_level("max_hp"),
		get_permanent_upgrade_max_level("max_hp"),
		get_permanent_upgrade_cost("max_hp"),
		get_permanent_upgrade_description("max_hp")
	])
	lines.append("[2] %s Lv.%d/%d — Cost %d — %s" % [
		get_permanent_upgrade_display_name("max_armor"),
		get_permanent_upgrade_level("max_armor"),
		get_permanent_upgrade_max_level("max_armor"),
		get_permanent_upgrade_cost("max_armor"),
		get_permanent_upgrade_description("max_armor")
	])
	lines.append("[3] %s Lv.%d/%d — Cost %d — %s" % [
		get_permanent_upgrade_display_name("move_speed"),
		get_permanent_upgrade_level("move_speed"),
		get_permanent_upgrade_max_level("move_speed"),
		get_permanent_upgrade_cost("move_speed"),
		get_permanent_upgrade_description("move_speed")
	])
	lines.append("Stand near me and press 1, 2, or 3 to buy.")

	return lines


func get_permanent_max_hp_bonus() -> float:
	return float(get_permanent_upgrade_level("max_hp")) * 10.0


func get_permanent_max_armor_bonus() -> float:
	return float(get_permanent_upgrade_level("max_armor")) * 5.0


func get_permanent_move_speed_mult() -> float:
	return 1.0 + float(get_permanent_upgrade_level("move_speed")) * 0.03
