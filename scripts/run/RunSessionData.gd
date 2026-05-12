extends RefCounted
class_name RunSessionData

static var last_run_summary: Dictionary = {}
static var completed_run_count: int = 0

static func has_last_run() -> bool:
	return not last_run_summary.is_empty()

static func clear_last_run() -> void:
	last_run_summary.clear()

static func record_completed_run(summary: Dictionary) -> void:
	completed_run_count += 1
	last_run_summary = summary.duplicate(true)
	last_run_summary["completed_run_count"] = completed_run_count

static func get_last_run_summary() -> Dictionary:
	return last_run_summary.duplicate(true)

static func build_last_run_panel_text() -> String:
	if not has_last_run():
		return _build_no_run_text()

	var summary: Dictionary = get_last_run_summary()
	var lines: Array[String] = []

	lines.append("LAST RUN RESULTS")
	lines.append("")
	lines.append("Status: %s" % str(summary.get("status", "Unknown")))
	lines.append("Runs Completed: %s" % str(summary.get("completed_run_count", "0")))
	lines.append("Rooms Cleared: %s" % str(summary.get("rooms_cleared", "0")))
	lines.append("Room Cycles: %s" % str(summary.get("room_cycles", "0")))
	lines.append("")
	lines.append("Weapon Used:")
	lines.append(str(summary.get("weapon_name", "Penitent Blade")))
	lines.append("")
	lines.append("Patron State:")
	lines.append(str(summary.get("patron_state", "No patron record.")))
	lines.append("")
	lines.append("Reward:")
	lines.append(str(summary.get("reward_text", "No reward recorded.")))
	lines.append("")
	lines.append("Notes:")
	lines.append(str(summary.get("note", "No notes.")))
	lines.append("")
	lines.append("Future Run Results features:")
	lines.append("- currency payout")
	lines.append("- weapon mastery gain")
	lines.append("- patron relationship gain")
	lines.append("- enemy kill records")
	lines.append("- room history")
	lines.append("- death / victory details")
	lines.append("")
	lines.append("Current V1 action:")
	lines.append("This is only a summary display. Rewards are not spendable yet.")

	return "\n".join(lines)

static func build_fountain_panel_text() -> String:
	if has_last_run():
		return build_last_run_panel_text()

	return _build_no_run_text()

static func _build_no_run_text() -> String:
	var lines: Array[String] = []
	lines.append("FOUNTAIN")
	lines.append("")
	lines.append("No completed run has been recorded yet.")
	lines.append("")
	lines.append("Current function:")
	lines.append("- return here after a completed test run")
	lines.append("- view the last run summary")
	lines.append("")
	lines.append("Future function:")
	lines.append("- restore health")
	lines.append("- cleanse temporary penalties")
	lines.append("- review run history")
	lines.append("- collect or inspect post-run rewards")
	lines.append("")
	lines.append("To generate a result:")
	lines.append("Go to the Hell Gate, complete the Ash Intake Hall loop, then return to the hub.")
	return "\n".join(lines)
