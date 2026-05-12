extends RefCounted
class_name RunEconomyData

## V28 — Save System V1 serialization support.
## Owns permanent Ash Sigils and lifetime earned totals.

static var ash_sigils: int = 0
static var lifetime_ash_sigils_earned: int = 0

static func get_ash_sigils() -> int:
	return ash_sigils

static func get_lifetime_ash_sigils_earned() -> int:
	return lifetime_ash_sigils_earned

static func add_ash_sigils(amount: int) -> int:
	var final_amount: int = maxi(0, amount)
	if final_amount <= 0:
		return 0
	ash_sigils += final_amount
	lifetime_ash_sigils_earned += final_amount
	print("[RunEconomy] Ash Sigils +%d. Current: %d. Lifetime: %d." % [final_amount, ash_sigils, lifetime_ash_sigils_earned])
	return final_amount

static func can_spend_ash_sigils(amount: int) -> bool:
	return ash_sigils >= maxi(0, amount)

static func spend_ash_sigils(amount: int) -> bool:
	var final_amount: int = maxi(0, amount)
	if final_amount <= 0:
		return true
	if ash_sigils < final_amount:
		return false
	ash_sigils -= final_amount
	print("[RunEconomy] Ash Sigils -%d. Current: %d." % [final_amount, ash_sigils])
	return true

static func set_ash_sigils(amount: int) -> void:
	ash_sigils = maxi(0, amount)

static func set_lifetime_ash_sigils_earned(amount: int) -> void:
	lifetime_ash_sigils_earned = maxi(0, amount)

static func reset_session_economy() -> void:
	ash_sigils = 0
	lifetime_ash_sigils_earned = 0

static func to_save_dict() -> Dictionary:
	return {
		"ash_sigils": ash_sigils,
		"lifetime_ash_sigils_earned": lifetime_ash_sigils_earned,
	}

static func apply_save_dict(data: Dictionary) -> void:
	set_ash_sigils(int(data.get("ash_sigils", 0)))
	set_lifetime_ash_sigils_earned(int(data.get("lifetime_ash_sigils_earned", ash_sigils)))

static func get_currency_summary_line() -> String:
	return "Ash Sigils: %d" % ash_sigils

static func build_toll_clerk_panel_text() -> String:
	var lines: Array[String] = []
	lines.append("TOLL CLERK")
	lines.append("")
	lines.append("Ash Sigils are permanent demo currency.")
	lines.append("")
	lines.append("Current Ash Sigils: %d" % ash_sigils)
	lines.append("Lifetime earned: %d" % lifetime_ash_sigils_earned)
	lines.append("")
	lines.append("How to earn them:")
	lines.append("- Defeat The Ash Warden.")
	lines.append("- Claim Ash Sigil reward boons.")
	lines.append("- Some future hub upgrades may improve the payout.")
	lines.append("")
	lines.append("How to spend them:")
	lines.append("- Use the Reliquary Altar in the hub.")
	lines.append("")
	lines.append("Save status:")
	lines.append("- V28 saves this currency to disk.")
	return "\n".join(lines)
