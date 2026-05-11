extends Resource
class_name WeaponData

@export var id: String = "penitent_blade"
@export var display_name: String = "Penitent Blade"
@export_multiline var description: String = "A chained crusader blade built for fast confession cuts, charged absolution, and judgment movement."
@export var tags: Array[String] = ["Slash", "Combo", "Judgment", "Mobile"]
@export var weapon_family: String = "blade"
@export var base_action_tags: Array[String] = ["weapon", "penitent", "blade"]

@export_group("Light Combo")
@export var light_description: String = "Three-hit slash chain. The third hit is wider and heavier."
@export var light_action_tags: Array[String] = ["attack", "light", "melee", "slash", "combo", "blade"]
@export var light_radius: float = 58.0
@export var light_damage: float = 18.0
@export var light_cooldown: float = 0.22
@export var light_startup: float = 0.045
@export var light_active_time: float = 0.075
@export var light_recovery: float = 0.12

@export_group("Heavy")
@export var heavy_description: String = "Wind up, then release a broad absolution slash."
@export var heavy_action_tags: Array[String] = ["attack", "heavy", "melee", "cleave", "charged", "stagger", "blade"]
@export var heavy_radius: float = 92.0
@export var heavy_damage: float = 48.0
@export var heavy_cooldown: float = 0.78
@export var heavy_startup: float = 0.035
@export var heavy_active_time: float = 0.13
@export var heavy_recovery: float = 0.30
@export var heavy_windup_time: float = 0.36

@export_group("Q Skill")
@export var q_description: String = "Forward judgment dash slash with a clean blue-gold trail."
@export var q_action_tags: Array[String] = ["attack", "skill", "q", "movement", "dash_slash", "melee", "judgment", "blade"]
@export var q_radius: float = 98.0
@export var q_damage: float = 34.0
@export var q_cooldown: float = 3.0
@export var q_offset: float = 76.0
@export var q_startup: float = 0.035
@export var q_active_time: float = 0.12
@export var q_recovery: float = 0.18

@export_group("Ultimate")
@export var ultimate_description: String = "Circular penance burst. High hit stop, large radius, strong status payoff."
@export var ultimate_action_tags: Array[String] = ["attack", "ultimate", "area", "judgment", "execute", "high_cost", "blade"]
@export var ultimate_radius: float = 215.0
@export var ultimate_damage: float = 98.0
@export var ultimate_cooldown: float = 1.0
@export var ultimate_cost: float = 100.0
@export var ultimate_startup: float = 0.09
@export var ultimate_active_time: float = 0.18
@export var ultimate_recovery: float = 0.40

@export_group("Presentation")
@export var primary_color: Color = Color("#dfaa46")
@export var secondary_color: Color = Color("#ff684a")
@export var q_color: Color = Color("#9ed8cd")
@export var ultimate_color: Color = Color("#ffd36a")


func get_tags_text() -> String:
	if tags.is_empty():
		return "None"

	var text := ""

	for i in range(tags.size()):
		if i > 0:
			text += " / "

		text += tags[i]

	return text


func get_action_tags(action_kind: String) -> Array[String]:
	var result: Array[String] = []
	result.append_array(base_action_tags)

	match action_kind:
		"light", "light_1", "light_2", "light_3":
			result.append_array(light_action_tags)
		"heavy", "heavy_windup":
			result.append_array(heavy_action_tags)
		"q":
			result.append_array(q_action_tags)
		"ultimate":
			result.append_array(ultimate_action_tags)
		_:
			result.append("attack")

	return _dedupe_tags(result)


func get_action_display_name(action_kind: String) -> String:
	match action_kind:
		"light_1":
			return "First Confession"
		"light_2":
			return "Second Confession"
		"light_3":
			return "Final Confession"
		"heavy", "heavy_windup":
			return "Absolution Cleave"
		"q":
			return "Judgment Dash"
		"ultimate":
			return "Penance Burst"
		_:
			return display_name


func _dedupe_tags(input_tags: Array[String]) -> Array[String]:
	var seen: Dictionary = {}
	var result: Array[String] = []

	for tag in input_tags:
		var normalized: String = str(tag).strip_edges().to_lower()

		if normalized == "":
			continue

		if seen.has(normalized):
			continue

		seen[normalized] = true
		result.append(normalized)

	return result
