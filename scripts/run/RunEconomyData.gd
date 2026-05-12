extends RefCounted
class_name RunEconomyData

static var ash_sigils: int = 0
static var lifetime_ash_sigils_earned: int = 0

static func get_ash_sigils() -> int:
	return ash_sigils

static func get_lifetime_ash_sigils_earned() -> int:
	return lifetime_ash_sigils_earned

static func add_ash_sigils(amount: int) -> int:
	var final_amount: int = max(0, amount)
	if final_amount <= 0:
		return 0

	ash_sigils += final_amount
	lifetime_ash_sigils_earned += final_amount
	print("[RunEconomy] Ash Sigils +%d. Current: %d. Lifetime: %d." % [
		final_amount,
		ash_sigils,
		lifetime_ash_sigils_earned
	])
	return final_amount

static func can_spend_ash_sigils(amount: int) -> bool:
	return ash_sigils >= max(0, amount)

static func spend_ash_sigils(amount: int) -> bool:
	var final_amount: int = max(0, amount)
	if final_amount <= 0:
		return true
	if ash_sigils < final_amount:
		return false
	ash_sigils -= final_amount
	print("[RunEconomy] Ash Sigils -%d. Current: %d." % [final_amount, ash_sigils])
	return true

static func reset_session_economy() -> void:
	ash_sigils = 0
	lifetime_ash_sigils_earned = 0

static func get_currency_summary_line() -> String:
	return "Ash Sigils: %d" % ash_sigils

static func build_toll_clerk_panel_text() -> String:
	var lines: Array[String] = []
	lines.append("TOLL CLERK")
	lines.append("")
	lines.append("Ash Sigils are now real session currency.")
	lines.append("")
	lines.append("Current Ash Sigils: %d" % ash_sigils)
	lines.append("Lifetime earned this session: %d" % lifetime_ash_sigils_earned)
	lines.append("")
	lines.append("How to earn them:")
	lines.append("- Complete the current Ash Intake Hall test run.")
	lines.append("- Each completed test run currently grants +1 Ash Sigil.")
	lines.append("")
	lines.append("What they will be used for later:")
	lines.append("- weapon upgrades")
	lines.append("- permanent character upgrades")
	lines.append("- patron offerings")
	lines.append("- starting supplies")
	lines.append("- harder-run reward modifiers")
	lines.append("")
	lines.append("Current V1 limitation:")
	lines.append("Ash Sigils can be earned and displayed, but cannot be spent yet.")
	return "\n".join(lines)
