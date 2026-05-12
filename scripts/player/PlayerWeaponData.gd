extends RefCounted
class_name PlayerWeaponData

const WEAPON_PENITENT_BLADE: String = "penitent_blade"

static func get_current_weapon_id() -> String:
	return WEAPON_PENITENT_BLADE

static func get_weapon(weapon_id: String) -> Dictionary:
	var weapons: Dictionary = get_weapons()
	return weapons.get(weapon_id, get_penitent_blade())

static func get_current_weapon() -> Dictionary:
	return get_weapon(get_current_weapon_id())

static func get_weapons() -> Dictionary:
	return {
		WEAPON_PENITENT_BLADE: get_penitent_blade()
	}

static func get_penitent_blade() -> Dictionary:
	return {
		"id": WEAPON_PENITENT_BLADE,
		"display_name": "Penitent Blade",
		"subtitle": "Starting Weapon",
		"status": "Equipped",
		"role": "Balanced melee weapon for close combat.",
		"fantasy": "A reliable sword for learning the run: simple reach, fast enough attacks, and clean close-range control.",
		"stats": {
			"Damage": "1",
			"Attack Range": "82",
			"Attack Cooldown": "0.28s",
			"Move Speed": "260"
		},
		"controls": {
			"Move": "WASD / arrows",
			"Attack": "Space / left mouse",
			"Interact": "E"
		},
		"strengths": [
			"Easy to understand",
			"Good for close combat",
			"Works with all current patron test boons",
			"Reliable for testing rooms and hub flow"
		],
		"weaknesses": [
			"No special aspect yet",
			"No heavy attack variation yet",
			"No real combo chain yet"
		],
		"future_unlocks": [
			"Weapon aspects",
			"Base stat upgrades",
			"Alternate weapons",
			"Forge modifications",
			"Training-yard damage readout"
		]
	}

static func build_weapon_panel_text() -> String:
	var weapon: Dictionary = get_current_weapon()
	var lines: Array[String] = []

	lines.append("%s — %s" % [
		str(weapon.get("display_name", "Unknown Weapon")).to_upper(),
		str(weapon.get("subtitle", "Weapon"))
	])
	lines.append("")
	lines.append("Status: %s" % str(weapon.get("status", "Available")))
	lines.append("")
	lines.append("Role:")
	lines.append(str(weapon.get("role", "No role defined.")))
	lines.append("")
	lines.append("Weapon fantasy:")
	lines.append(str(weapon.get("fantasy", "No fantasy defined.")))
	lines.append("")
	lines.append("Current stats:")

	var stats: Dictionary = weapon.get("stats", {})
	for key: Variant in stats.keys():
		lines.append("- %s: %s" % [str(key), str(stats[key])])

	lines.append("")
	lines.append("Controls:")
	var controls: Dictionary = weapon.get("controls", {})
	for key: Variant in controls.keys():
		lines.append("- %s: %s" % [str(key), str(controls[key])])

	lines.append("")
	lines.append("Strengths:")
	for value: Variant in weapon.get("strengths", []):
		lines.append("- " + str(value))

	lines.append("")
	lines.append("Still missing:")
	for value: Variant in weapon.get("weaknesses", []):
		lines.append("- " + str(value))

	lines.append("")
	lines.append("Future Weapon Altar functions:")
	for value: Variant in weapon.get("future_unlocks", []):
		lines.append("- " + str(value))

	lines.append("")
	lines.append("Current V1 action:")
	lines.append("The Penitent Blade remains equipped. This panel is now the real loadout inspection point, but it does not modify combat yet.")

	return "\n".join(lines)
