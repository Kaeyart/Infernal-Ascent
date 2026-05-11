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
			"subtitle": "Speed and wind attacks",
			"role_text": "Fast movement, safer dodges, wind slashes, and orbiting attacks.",
			"simple_text": "Pick Francesca if you want to move fast and damage enemies while dodging.",
			"color": Color("#9fd8ff"),
			"tags": ["dash", "wind", "speed", "multi_hit"],
			"boons": [
				{
					"id": "francesca_crosswind_cut",
					"name": "Crosswind Cut",
					"rarity": "Common",
					"slot": "Attack",
					"summary": "Your basic attacks fire a short wind slash.",
					"trigger_text": "When you hit with your basic attack.",
					"effect_text": "A short wind cut shoots forward and damages enemies in front of you.",
					"build_hint": "Good for safe sword builds that want extra reach.",
					"description": "Basic attacks release a short wind cut.",
					"tags": ["attack", "wind", "projectile"]
				},
				{
					"id": "francesca_last_breath",
					"name": "Last Breath",
					"rarity": "Common",
					"slot": "Dash",
					"summary": "Your dash leaves a slicing wind behind you.",
					"trigger_text": "When you dash.",
					"effect_text": "A brief gust appears where you dashed and damages enemies touching it.",
					"build_hint": "Good if you like dodging through danger and hurting enemies while moving.",
					"description": "Dashing leaves a brief slicing gust behind you.",
					"tags": ["dash", "wind", "zone"]
				},
				{
					"id": "francesca_orbiting_lament",
					"name": "Orbiting Lament",
					"rarity": "Rare",
					"slot": "Passive",
					"summary": "Repeated hits create a blade that circles you.",
					"trigger_text": "Every third time you hit enemies.",
					"effect_text": "Create a small orbiting blade that damages nearby enemies.",
					"build_hint": "Good for fast multi-hit builds that stay near enemies.",
					"description": "Every third hit creates a small orbiting blade.",
					"tags": ["multi_hit", "summon", "wind"]
				}
			]
		},
		PATRON_UGOLINO: {
			"id": PATRON_UGOLINO,
			"display_name": "Ugolino",
			"subtitle": "Survive by hurting enemies",
			"role_text": "Healing, lifesteal, low-health damage, and rewards for finishing wounded enemies.",
			"simple_text": "Pick Ugolino if you want a brutal survival build that heals through combat.",
			"color": Color("#c56a3c"),
			"tags": ["hunger", "lifesteal", "execute", "bleed"],
			"boons": [
				{
					"id": "ugolino_bite_deep",
					"name": "Bite Deep",
					"rarity": "Common",
					"slot": "Attack",
					"summary": "Hitting wounded enemies heals you.",
					"trigger_text": "When your attack hits an enemy that is already wounded.",
					"effect_text": "Restore a small amount of health.",
					"build_hint": "Good if you take damage often and want more sustain.",
					"description": "Hits against wounded enemies restore a little health.",
					"tags": ["attack", "lifesteal", "wounded"]
				},
				{
					"id": "ugolino_starved_verdict",
					"name": "Starved Verdict",
					"rarity": "Common",
					"slot": "Heavy",
					"summary": "Heavy attacks punish enemies with low health.",
					"trigger_text": "When your heavy attack hits a low-health enemy.",
					"effect_text": "Deal extra damage, making wounded enemies easier to finish.",
					"build_hint": "Good if you like setting enemies up and then executing them.",
					"description": "Low-health enemies take extra damage from heavy attacks.",
					"tags": ["heavy", "execute", "hunger"]
				},
				{
					"id": "ugolino_rib_cage",
					"name": "Rib Cage",
					"rarity": "Rare",
					"slot": "Defense",
					"summary": "After you get hurt, your next kill gives armor.",
					"trigger_text": "After an enemy damages you, then you kill an enemy.",
					"effect_text": "Gain temporary armor that helps absorb future damage.",
					"build_hint": "Good for close-range builds that expect to trade hits.",
					"description": "After taking damage, your next kill grants armor.",
					"tags": ["armor", "kill", "survival"]
				}
			]
		},
		PATRON_MINOS: {
			"id": PATRON_MINOS,
			"display_name": "Minos",
			"subtitle": "Mark and execute enemies",
			"role_text": "Mark enemies, punish targets, and deal stronger finishing damage.",
			"simple_text": "Pick Minos if you want to mark enemies first and then finish them with stronger attacks.",
			"color": Color("#ffd36e"),
			"tags": ["mark", "judgment", "execute", "elite"],
			"boons": [
				{
					"id": "minos_sentence_mark",
					"name": "Sentence Mark",
					"rarity": "Common",
					"slot": "Attack",
					"summary": "Basic attacks mark enemies for punishment.",
					"trigger_text": "When your basic attack hits an enemy.",
					"effect_text": "Apply a Judgment Mark. Marked enemies become better targets for Minos boons.",
					"build_hint": "Good if you want a clear setup-and-finish playstyle.",
					"description": "Light attacks mark enemies for judgment.",
					"tags": ["attack", "mark", "judgment"]
				},
				{
					"id": "minos_weight_of_sin",
					"name": "Weight of Sin",
					"rarity": "Common",
					"slot": "Heavy",
					"summary": "Heavy attacks hit marked enemies harder.",
					"trigger_text": "When your heavy attack hits an enemy with a Judgment Mark.",
					"effect_text": "Deal bonus damage to that marked enemy.",
					"build_hint": "Good if you like marking with basic attacks and finishing with heavy attacks.",
					"description": "Heavy attacks deal more damage to marked enemies.",
					"tags": ["heavy", "mark", "execute"]
				},
				{
					"id": "minos_no_appeal",
					"name": "No Appeal",
					"rarity": "Rare",
					"slot": "Passive",
					"summary": "Marked elites are easier to stagger.",
					"trigger_text": "When you damage a marked elite enemy.",
					"effect_text": "That elite takes increased stagger damage, making it easier to interrupt.",
					"build_hint": "Good for boss and elite-heavy rooms.",
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
			"subtitle": "Upgrade or reshape your weapon",
			"type": "utility",
			"color": Color("#f08b38")
		},
		{
			"id": "fountain",
			"display_name": "Fountain",
			"subtitle": "Recover health before going deeper",
			"type": "utility",
			"color": Color("#7ee0a1")
		},
		{
			"id": "shop",
			"display_name": "Toll Market",
			"subtitle": "Spend coins for power or healing",
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

static func get_patron_subtitle(patron_id: String) -> String:
	var patron: Dictionary = get_patron(patron_id)
	return str(patron.get("subtitle", "Patron boon"))

static func get_patron_role_text(patron_id: String) -> String:
	var patron: Dictionary = get_patron(patron_id)
	return str(patron.get("role_text", patron.get("subtitle", "A patron offers power.")))

static func get_patron_simple_text(patron_id: String) -> String:
	var patron: Dictionary = get_patron(patron_id)
	return str(patron.get("simple_text", patron.get("role_text", "Choose this patron to shape your build.")))

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
			"summary": "A basic favor from this patron.",
			"trigger_text": "Always active.",
			"effect_text": "This is a placeholder boon.",
			"build_hint": "Placeholder. Replace later.",
			"description": "A placeholder favor from this patron.",
			"tags": ["favor"],
			"patron_id": patron_id,
			"patron_name": get_patron_name(patron_id),
			"patron_role_text": get_patron_role_text(patron_id),
			"patron_simple_text": get_patron_simple_text(patron_id)
		}
	var index: int = rng.randi_range(0, boons.size() - 1)
	var boon: Dictionary = boons[index].duplicate(true)
	boon["patron_id"] = patron_id
	boon["patron_name"] = get_patron_name(patron_id)
	boon["patron_role_text"] = get_patron_role_text(patron_id)
	boon["patron_simple_text"] = get_patron_simple_text(patron_id)
	return boon
