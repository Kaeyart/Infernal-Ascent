extends Resource
class_name PatronSynergyData

## T-007 — Patron synergy data loader.
## Synergies appear from owned compatible boons, not from a hard two-patron lock.

const SYNERGY_FILE_PATH: String = "res://data/boons/patron_synergies.json"

static func load_all() -> Array:
	var synergies: Array = []
	if not FileAccess.file_exists(SYNERGY_FILE_PATH):
		push_warning("PatronSynergyData: missing synergy file: " + SYNERGY_FILE_PATH)
		return synergies

	var file: FileAccess = FileAccess.open(SYNERGY_FILE_PATH, FileAccess.READ)
	if file == null:
		push_warning("PatronSynergyData: could not open synergy file: " + SYNERGY_FILE_PATH)
		return synergies

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("PatronSynergyData: synergy file must contain an array.")
		return synergies

	for entry: Variant in parsed:
		if typeof(entry) == TYPE_DICTIONARY:
			synergies.append(entry)
	return synergies

static func get_available_synergies(owned_boons: Array) -> Array:
	var owned_patrons: Dictionary = {}
	var owned_tags: Dictionary = {}

	for entry: Variant in owned_boons:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var boon: Dictionary = entry as Dictionary
		owned_patrons[str(boon.get("patron_id", ""))] = true
		var tags: Array = boon.get("synergy_tags", []) as Array
		for tag: Variant in tags:
			owned_tags[str(tag)] = true

	var results: Array = []
	for entry: Variant in load_all():
		var synergy: Dictionary = entry as Dictionary
		var required_patrons: Array = synergy.get("required_patrons", []) as Array
		var required_tags: Array = synergy.get("required_tags", []) as Array
		var valid: bool = true

		for patron_id: Variant in required_patrons:
			if not owned_patrons.has(str(patron_id)):
				valid = false
				break

		if valid:
			for tag: Variant in required_tags:
				if not owned_tags.has(str(tag)):
					valid = false
					break

		if valid:
			results.append(synergy)

	return results
