extends Resource
class_name BoonData

## T-007 — Boon data loader.
## Boons replace the old flat temporary reward direction over time.

const BOON_FILE_PATHS: Array[String] = [
	"res://data/boons/azazel_chains_boons.json",
	"res://data/boons/mammon_furnace_boons.json",
	"res://data/boons/minos_judge_boons.json",
]

static func load_all() -> Array:
	var boons: Array = []
	for path: String in BOON_FILE_PATHS:
		boons.append_array(_load_file(path))
	return boons

static func _load_file(path: String) -> Array:
	var boons: Array = []
	if not FileAccess.file_exists(path):
		push_warning("BoonData: missing boon file: " + path)
		return boons

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("BoonData: could not open boon file: " + path)
		return boons

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("BoonData: boon file must contain an array: " + path)
		return boons

	for entry: Variant in parsed:
		if typeof(entry) == TYPE_DICTIONARY:
			boons.append(entry)
	return boons

static func get_by_id(boon_id: String) -> Dictionary:
	var boons: Array = load_all()
	for entry: Variant in boons:
		var boon: Dictionary = entry as Dictionary
		if str(boon.get("id", "")) == boon_id:
			return boon
	return {}

static func get_for_patron(patron_id: String) -> Array:
	var results: Array = []
	var boons: Array = load_all()
	for entry: Variant in boons:
		var boon: Dictionary = entry as Dictionary
		if str(boon.get("patron_id", "")) == patron_id:
			results.append(boon)
	return results

static func get_by_tags(required_tags: Array) -> Array:
	var results: Array = []
	var boons: Array = load_all()
	for entry: Variant in boons:
		var boon: Dictionary = entry as Dictionary
		var tags: Array = boon.get("synergy_tags", []) as Array
		var has_all_tags: bool = true
		for required_tag: Variant in required_tags:
			if not tags.has(str(required_tag)):
				has_all_tags = false
				break
		if has_all_tags:
			results.append(boon)
	return results

static func build_debug_summary() -> String:
	var boons: Array = load_all()
	var counts: Dictionary = {}
	for entry: Variant in boons:
		var boon: Dictionary = entry as Dictionary
		var patron_id: String = str(boon.get("patron_id", "unknown"))
		counts[patron_id] = int(counts.get(patron_id, 0)) + 1

	var lines: Array[String] = []
	lines.append("BOON DATA")
	for patron_id: Variant in counts.keys():
		lines.append("- %s: %d boons" % [str(patron_id), int(counts[patron_id])])
	return "\n".join(lines)
