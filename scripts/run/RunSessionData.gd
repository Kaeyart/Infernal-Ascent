extends RefCounted
class_name RunSessionData

## V28 — Save System V1 serialization support.
## Stores the latest run summary and simple demo progress flags.

static var last_run_summary: Dictionary = {}
static var completed_run_count: int = 0
static var best_run_depth: int = 0
static var boss_defeated: bool = false

static func has_last_run() -> bool:
	return not last_run_summary.is_empty()

static func clear_last_run() -> void:
	last_run_summary.clear()

static func record_completed_run(summary: Dictionary) -> void:
	completed_run_count += 1
	last_run_summary = summary.duplicate(true)
	last_run_summary["completed_run_count"] = completed_run_count
	best_run_depth = maxi(best_run_depth, int(summary.get("rooms_cleared", 0)))
	if bool(summary.get("boss_defeated", false)) or str(summary.get("outcome", "")) == "victory":
		boss_defeated = true

static func get_last_run_summary() -> Dictionary:
	return last_run_summary.duplicate(true)

static func get_completed_run_count() -> int:
	return completed_run_count

static func get_best_run_depth() -> int:
	return best_run_depth

static func has_defeated_boss() -> bool:
	return boss_defeated

static func to_save_dict() -> Dictionary:
	return {
		"last_run_summary": last_run_summary.duplicate(true),
		"completed_run_count": completed_run_count,
		"best_run_depth": best_run_depth,
		"boss_defeated": boss_defeated,
	}

static func apply_save_dict(data: Dictionary) -> void:
	last_run_summary = (data.get("last_run_summary", {}) as Dictionary).duplicate(true)
	completed_run_count = maxi(0, int(data.get("completed_run_count", 0)))
	best_run_depth = maxi(0, int(data.get("best_run_depth", int(last_run_summary.get("rooms_cleared", 0)))))
	boss_defeated = bool(data.get("boss_defeated", false)) or bool(last_run_summary.get("boss_defeated", false))
	if not last_run_summary.is_empty() and not last_run_summary.has("completed_run_count"):
		last_run_summary["completed_run_count"] = completed_run_count

static func reset_progress_flags() -> void:
	last_run_summary.clear()
	completed_run_count = 0
	best_run_depth = 0
	boss_defeated = false

static func build_last_run_panel_text() -> String:
	if not has_last_run():
		return _build_no_run_text()
	var summary: Dictionary = get_last_run_summary()
	var lines: Array[String] = []
	lines.append("LAST RUN RESULTS")
	lines.append("")
	lines.append("Status: %s" % str(summary.get("status", "Unknown")))
	lines.append("Outcome: %s" % str(summary.get("outcome", "unknown")))
	lines.append("Runs Completed: %s" % str(summary.get("completed_run_count", completed_run_count)))
	lines.append("Best Depth: %d" % best_run_depth)
	lines.append("Rooms Cleared: %s" % str(summary.get("rooms_cleared", "0")))
	lines.append("")
	lines.append("Boss:")
	lines.append("Ash Warden defeated: %s" % ("YES" if boss_defeated else "NO"))
	lines.append("")
	lines.append("Boons:")
	lines.append(str(summary.get("boon", "No boon recorded.")))
	lines.append("")
	lines.append("Currency:")
	lines.append("Ash Sigils gained this run: %s" % str(summary.get("ash_sigils_earned", summary.get("ash_sigils_gained", "0"))))
	lines.append("Current Ash Sigils: %d" % RunEconomyData.get_ash_sigils())
	lines.append("Lifetime Ash Sigils earned: %d" % RunEconomyData.get_lifetime_ash_sigils_earned())
	lines.append("")
	lines.append("Save status:")
	lines.append("This result is saved by V28.")
	return "\n".join(lines)

static func build_fountain_panel_text() -> String:
	if has_last_run():
		return build_last_run_panel_text()
	return _build_no_run_text()

static func _build_no_run_text() -> String:
	var lines: Array[String] = []
	lines.append("MEMORY POOL")
	lines.append("")
	lines.append("No completed run has been recorded yet.")
	lines.append("")
	lines.append("Current Ash Sigils: %d" % RunEconomyData.get_ash_sigils())
	lines.append("Runs Completed: %d" % completed_run_count)
	lines.append("Best Depth: %d" % best_run_depth)
	lines.append("Ash Warden defeated: %s" % ("YES" if boss_defeated else "NO"))
	lines.append("")
	lines.append("Save status:")
	lines.append("V28 will preserve this progress after quitting once a save file exists.")
	return "\n".join(lines)
