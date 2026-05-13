extends Resource
class_name PatronData

## T-007 — Patron data loader.
## Patrons are weighted boon sources, not hard run locks.

const PATRON_FILE_PATH: String = "res://data/patrons/patrons.json"

static func load_all() -> Array:
	var patrons: Array = []
	if not FileAccess.file_exists(PATRON_FILE_PATH):
		push_warning("PatronData: missing patron file: " + PATRON_FILE_PATH)
		return patrons

	var file: FileAccess = FileAccess.open(PATRON_FILE_PATH, FileAccess.READ)
	if file == null:
		push_warning("PatronData: could not open patron file: " + PATRON_FILE_PATH)
		return patrons

	var text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("PatronData: patron file must contain an array.")
		return patrons

	for entry: Variant in parsed:
		if typeof(entry) == TYPE_DICTIONARY:
			patrons.append(entry)
	return patrons

static func get_by_id(patron_id: String) -> Dictionary:
	var patrons: Array = load_all()
	for entry: Variant in patrons:
		var patron: Dictionary = entry as Dictionary
		if str(patron.get("id", "")) == patron_id:
			return patron
	return {}

static func has_patron(patron_id: String) -> bool:
	return not get_by_id(patron_id).is_empty()

static func get_base_weight(patron_id: String) -> float:
	var patron: Dictionary = get_by_id(patron_id)
	if patron.is_empty():
		return 0.0
	return float(patron.get("base_weight", 1.0))

static func build_debug_summary() -> String:
	var patrons: Array = load_all()
	var lines: Array[String] = []
	lines.append("PATRON DATA")
	for entry: Variant in patrons:
		var patron: Dictionary = entry as Dictionary
		lines.append("- %s (%s), weight %.2f" % [
			str(patron.get("display_name", "Unknown Patron")),
			str(patron.get("id", "missing_id")),
			float(patron.get("base_weight", 1.0))
		])
	return "\n".join(lines)
