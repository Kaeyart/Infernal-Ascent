extends RefCounted
class_name SaveGameData

## V28 — Save System V1.
## Single-file JSON save for demo progress.
## Saves: Ash Sigils, permanent upgrades, best run depth, boss defeated flag, and last run summary.

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://infernal_ascent_demo_save_v1.json"

static var is_loaded: bool = false
static var is_loading: bool = false
static var last_error: String = ""
static var last_save_unix_time: int = 0

static func load_or_create() -> bool:
	if is_loaded:
		return true
	is_loading = true
	last_error = ""
	if not FileAccess.file_exists(SAVE_PATH):
		is_loaded = true
		is_loading = false
		return save_game("create_default")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_error = "Could not open save file. Error %s" % str(FileAccess.get_open_error())
		is_loading = false
		return false
	var text: String = file.get_as_text()
	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(text)
	if parse_error != OK:
		last_error = "Could not parse save file at line %d: %s" % [json.get_error_line(), json.get_error_message()]
		is_loading = false
		return false
	if typeof(json.data) != TYPE_DICTIONARY:
		last_error = "Save file root is not a dictionary."
		is_loading = false
		return false
	apply_save_dict(json.data as Dictionary)
	is_loaded = true
	is_loading = false
	return true

static func save_game(reason: String = "manual") -> bool:
	last_error = ""
	var data: Dictionary = build_save_dict(reason)
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_error = "Could not write save file. Error %s" % str(FileAccess.get_open_error())
		push_warning("[SaveGameData] " + last_error)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	last_save_unix_time = Time.get_unix_time_from_system()
	print("[SaveGameData] Saved demo progress (%s) to %s" % [reason, SAVE_PATH])
	return true

static func build_save_dict(reason: String = "manual") -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"save_reason": reason,
		"economy": RunEconomyData.to_save_dict(),
		"permanent_upgrades": PermanentUpgradeData.to_save_dict(),
		"run_session": RunSessionData.to_save_dict(),
	}

static func apply_save_dict(data: Dictionary) -> void:
	var economy: Dictionary = data.get("economy", {}) as Dictionary
	var upgrades: Dictionary = data.get("permanent_upgrades", {}) as Dictionary
	var run_session: Dictionary = data.get("run_session", {}) as Dictionary
	RunEconomyData.apply_save_dict(economy)
	PermanentUpgradeData.apply_save_dict(upgrades)
	RunSessionData.apply_save_dict(run_session)

static func reset_save_data(delete_file: bool = false) -> void:
	RunEconomyData.reset_session_economy()
	PermanentUpgradeData.reset_upgrades()
	RunSessionData.reset_progress_flags()
	is_loaded = true
	last_error = ""
	if delete_file and FileAccess.file_exists(SAVE_PATH):
		var absolute_path: String = ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.remove_absolute(absolute_path)
	else:
		save_game("reset")

static func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func get_save_path() -> String:
	return SAVE_PATH

static func build_save_status_text() -> String:
	var lines: Array[String] = []
	lines.append("SAVE SYSTEM")
	lines.append("")
	lines.append("Path: %s" % SAVE_PATH)
	lines.append("Loaded: %s" % ("YES" if is_loaded else "NO"))
	lines.append("File exists: %s" % ("YES" if has_save_file() else "NO"))
	if last_error.strip_edges() != "":
		lines.append("Last error: %s" % last_error)
	lines.append("")
	lines.append("Saved data:")
	lines.append("- Ash Sigils")
	lines.append("- Lifetime Ash Sigils")
	lines.append("- Permanent upgrade levels")
	lines.append("- Last run summary")
	lines.append("- Best run depth")
	lines.append("- Ash Warden defeated flag")
	return "\n".join(lines)
