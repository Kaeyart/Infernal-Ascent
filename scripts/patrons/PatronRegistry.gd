extends RefCounted
class_name PatronRegistry

const PATRON_FRANCESCA: String = "francesca"
const PATRON_UGOLINO: String = "ugolino"
const PATRON_MINOS: String = "minos"

static func get_patrons() -> Dictionary:
	return {
		PATRON_FRANCESCA: {
			"id": PATRON_FRANCESCA,
			"display_name": "Francesca",
			"subtitle": "Longing / Wind / Motion",
			"color": Color("#9fd8ff"),
			"tags": ["dash", "wind", "speed", "multi_hit"],
			"boons": [
				{
					"id": "francesca_crosswind_cut",
					"name": "Crosswind Cut",
					"rarity": "Common",
					"slot": "Attack",
					"description": "Light attacks release a short wind cut.",
					"tags": ["attack", "wind", "projectile"]
				},
				{
					"id": "francesca_last_breath",
					"name": "Last Breath",
					"rarity": "Common",
					"slot": "Dash",
					"description": "Dashing leaves a brief slicing gust behind you.",
					"tags": ["dash", "wind", "zone"]
				},
				{
					"id": "francesca_orbiting_lament",
					"name": "Orbiting Lament",
					"rarity": "Rare",
					"slot": "Passive",
					"description": "Every third hit creates a small orbiting blade.",
					"tags": ["multi_hit", "summon", "wind"]
				}
			]
		},
		PATRON_UGOLINO: {
			"id": PATRON_UGOLINO,
			"display_name": "Ugolino",
			"subtitle": "Hunger / Devour / Survival",
			"color": Color("#c56a3c"),
			"tags": ["hunger", "lifesteal", "execute", "bleed"],
			"boons": [
				{
					"id": "ugolino_bite_deep",
					"name": "Bite Deep",
					"rarity": "Common",
					"slot": "Attack",
					"description": "Hits against wounded enemies restore a little health.",
					"tags": ["attack", "lifesteal", "wounded"]
				},
				{
					"id": "ugolino_starved_verdict",
					"name": "Starved Verdict",
					"rarity": "Common",
					"slot": "Passive",
					"description": "Low-health enemies take extra damage from heavy attacks.",
					"tags": ["heavy", "execute", "hunger"]
				},
				{
					"id": "ugolino_rib_cage",
					"name": "Rib Cage",
					"rarity": "Rare",
					"slot": "Defense",
					"description": "After taking damage, your next kill grants armor.",
					"tags": ["armor", "kill", "survival"]
				}
			]
		},
		PATRON_MINOS: {
			"id": PATRON_MINOS,
			"display_name": "Minos",
			"subtitle": "Judgment / Mark / Execution",
			"color": Color("#ffd36e"),
			"tags": ["mark", "judgment", "execute", "elite"],
			"boons": [
				{
					"id": "minos_sentence_mark",
					"name": "Sentence Mark",
					"rarity": "Common",
					"slot": "Attack",
					"description": "Light attacks mark enemies for judgment.",
					"tags": ["attack", "mark", "judgment"]
				},
				{
					"id": "minos_weight_of_sin",
					"name": "Weight of Sin",
					"rarity": "Common",
					"slot": "Heavy",
					"description": "Heavy attacks deal more damage to marked enemies.",
					"tags": ["heavy", "mark", "execute"]
				},
				{
					"id": "minos_no_appeal",
					"name": "No Appeal",
					"rarity": "Rare",
					"slot": "Passive",
					"description": "Marked elites take increased stagger damage.",
					"tags": ["elite", "mark", "stagger"]
				}
			]
		}
	}

static func get_utility_choices() -> Array[Dictionary]:
	return [
		{
			"id": "forge",
			"display_name": "Forge",
			"subtitle": "Shape the weapon",
			"type": "utility",
			"color": Color("#f08b38")
		},
		{
			"id": "fountain",
			"display_name": "Fountain",
			"subtitle": "Recover before descent",
			"type": "utility",
			"color": Color("#7ee0a1")
		},
		{
			"id": "shop",
			"display_name": "Toll Market",
			"subtitle": "Spend what remains",
			"type": "utility",
			"color": Color("#d8b866")
		}
	]

static func get_patron(patron_id: String) -> Dictionary:
	var patrons: Dictionary = get_patrons()
	return patrons.get(patron_id, {})

static func get_patron_name(patron_id: String) -> String:
	var patron: Dictionary = get_patron(patron_id)
	return str(patron.get("display_name", patron_id.capitalize()))

static func get_patron_color(patron_id: String) -> Color:
	var patron: Dictionary = get_patron(patron_id)
	var value: Variant = patron.get("color", Color("#d8b866"))
	if value is Color:
		return value
	return Color("#d8b866")

static func make_boon_offer(patron_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var patron: Dictionary = get_patron(patron_id)
	var boons: Array = patron.get("boons", [])
	if boons.is_empty():
		return {
			"id": patron_id + "_favor",
			"name": get_patron_name(patron_id) + "'s Favor",
			"rarity": "Common",
			"slot": "Passive",
			"description": "A placeholder favor from this patron.",
			"tags": ["favor"]
		}
	var index: int = rng.randi_range(0, boons.size() - 1)
	var boon: Dictionary = boons[index].duplicate(true)
	boon["patron_id"] = patron_id
	boon["patron_name"] = get_patron_name(patron_id)
	return boon
