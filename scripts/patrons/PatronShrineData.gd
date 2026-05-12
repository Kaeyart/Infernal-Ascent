extends RefCounted
class_name PatronShrineData

const PATRON_ORDER: Array[String] = [
	PatronRegistry.PATRON_FRANCESCA,
	PatronRegistry.PATRON_UGOLINO,
	PatronRegistry.PATRON_MINOS
]

static func get_relationship_rank(patron_id: String) -> String:
	var ranks: Dictionary = {
		PatronRegistry.PATRON_FRANCESCA: "Unmet / Rank 0",
		PatronRegistry.PATRON_UGOLINO: "Unmet / Rank 0",
		PatronRegistry.PATRON_MINOS: "Unmet / Rank 0"
	}
	return str(ranks.get(patron_id, "Unmet / Rank 0"))

static func get_relationship_goal(patron_id: String) -> String:
	var goals: Dictionary = {
		PatronRegistry.PATRON_FRANCESCA: "Future unlock: choose Francesca as your first patron before a run.",
		PatronRegistry.PATRON_UGOLINO: "Future unlock: choose Ugolino as your first patron before a run.",
		PatronRegistry.PATRON_MINOS: "Future unlock: choose Minos as your first patron before a run."
	}
	return str(goals.get(patron_id, "Future unlock: starting-patron choice."))

static func get_patron_build_example(patron_id: String) -> String:
	var examples: Dictionary = {
		PatronRegistry.PATRON_FRANCESCA: "Example build: dash often, stay mobile, and add wind damage while repositioning.",
		PatronRegistry.PATRON_UGOLINO: "Example build: fight close, heal through damage, and finish wounded enemies.",
		PatronRegistry.PATRON_MINOS: "Example build: mark enemies with basic attacks, then punish them with stronger hits."
	}
	return str(examples.get(patron_id, "Example build: shape your run around this patron's boons."))

static func build_patron_shrine_panel_text() -> String:
	var lines: Array[String] = []

	lines.append("PATRON SHRINE")
	lines.append("")
	lines.append("This shrine records the powers that can appear during a run.")
	lines.append("")
	lines.append("Current run rule:")
	lines.append("- Your first patron appears after the first clear.")
	lines.append("- Your second patron locks the run.")
	lines.append("- Future boons then come from those locked patrons.")
	lines.append("")
	lines.append("Relationship system:")
	lines.append("- Placeholder for now.")
	lines.append("- Later, repeated runs and offerings will improve patron relationships.")
	lines.append("- Higher relationship can unlock starting-patron control and patron records.")
	lines.append("")

	for patron_id: String in PATRON_ORDER:
		lines.append("--------------------------------")
		lines.append(PatronRegistry.get_patron_name(patron_id).to_upper())
		lines.append(PatronRegistry.get_patron_subtitle(patron_id))
		lines.append("")
		lines.append("What they do:")
		lines.append(PatronRegistry.get_patron_role_text(patron_id))
		lines.append("")
		lines.append("Why pick them:")
		lines.append(PatronRegistry.get_patron_simple_text(patron_id))
		lines.append("")
		lines.append("Build example:")
		lines.append(get_patron_build_example(patron_id))
		lines.append("")
		lines.append("Relationship:")
		lines.append(get_relationship_rank(patron_id))
		lines.append(get_relationship_goal(patron_id))
		lines.append("")

	lines.append("--------------------------------")
	lines.append("Current V1 action:")
	lines.append("This shrine is an information station only. It does not change which patrons appear yet.")

	return "\n".join(lines)

static func build_attendant_panel_text() -> String:
	var lines: Array[String] = []
	lines.append("The Veiled Attendant watches the patron shrine.")
	lines.append("")
	lines.append("She will eventually manage patron relationship progress.")
	lines.append("")
	lines.append("Current patrons:")
	for patron_id: String in PATRON_ORDER:
		lines.append("- %s: %s" % [
			PatronRegistry.get_patron_name(patron_id),
			PatronRegistry.get_patron_subtitle(patron_id)
		])
	lines.append("")
	lines.append("Future functions:")
	lines.append("- inspect discovered boons")
	lines.append("- view patron relationship ranks")
	lines.append("- unlock first-patron selection")
	lines.append("- read patron-specific records")
	lines.append("- offer resources to improve affinity")
	lines.append("")
	lines.append("Current state: placeholder NPC plus real Patron Shrine information panel.")
	return "\n".join(lines)
