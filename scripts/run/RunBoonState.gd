extends Node
class_name RunBoonState

## T-007 — Lightweight run boon state container.
## This is intentionally not wired into the main run loop yet.

var owned_boons: Array[Dictionary] = []
var owned_boon_levels: Dictionary = {}
var patron_weight_modifiers: Dictionary = {}

func reset_for_new_run() -> void:
	owned_boons.clear()
	owned_boon_levels.clear()
	patron_weight_modifiers.clear()

func add_boon(boon: Dictionary) -> void:
	var boon_id: String = str(boon.get("id", ""))
	if boon_id == "":
		return
	if has_boon(boon_id):
		owned_boon_levels[boon_id] = int(owned_boon_levels.get(boon_id, 1)) + 1
		return
	owned_boons.append(boon.duplicate(true))
	owned_boon_levels[boon_id] = 1

func has_boon(boon_id: String) -> bool:
	for boon: Dictionary in owned_boons:
		if str(boon.get("id", "")) == boon_id:
			return true
	return false

func get_boon_level(boon_id: String) -> int:
	return int(owned_boon_levels.get(boon_id, 0))

func get_owned_boons_for_patron(patron_id: String) -> Array:
	var results: Array = []
	for boon: Dictionary in owned_boons:
		if str(boon.get("patron_id", "")) == patron_id:
			results.append(boon)
	return results

func count_boons_for_patron(patron_id: String) -> int:
	return get_owned_boons_for_patron(patron_id).size()

func set_patron_weight_modifier(patron_id: String, modifier: float) -> void:
	patron_weight_modifiers[patron_id] = modifier

func get_patron_weight_modifier(patron_id: String) -> float:
	return float(patron_weight_modifiers.get(patron_id, 1.0))

func build_debug_summary() -> String:
	var lines: Array[String] = []
	lines.append("RUN BOONS")
	if owned_boons.is_empty():
		lines.append("- none")
	else:
		for boon: Dictionary in owned_boons:
			var boon_id: String = str(boon.get("id", "unknown"))
			lines.append("- %s L%d" % [str(boon.get("name", boon_id)), get_boon_level(boon_id)])
	return "\n".join(lines)
