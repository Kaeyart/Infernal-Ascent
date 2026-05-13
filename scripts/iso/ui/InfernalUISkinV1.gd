
extends RefCounted
class_name InfernalUISkinV1

const ROOT := "res://art/iso/ui/infernal_skin_v1"

static func texture(path: String) -> Texture2D:
	var loaded: Resource = load(path)
	if loaded is Texture2D:
		return loaded as Texture2D
	return null

static func panel_texture(kind: String) -> Texture2D:
	match kind:
		"reward": return texture(ROOT + "/panels/ui_panel_reward_choice.png")
		"route": return texture(ROOT + "/panels/ui_panel_route_choice.png")
		"forge": return texture(ROOT + "/panels/ui_panel_forge.png")
		"ascension": return texture(ROOT + "/panels/ui_panel_weapon_ascension.png")
		"shop": return texture(ROOT + "/panels/ui_panel_shop.png")
		"run_result": return texture(ROOT + "/panels/ui_panel_run_result.png")
	return texture(ROOT + "/panels/ui_tooltip_frame.png")

static func icon_texture(kind: String) -> Texture2D:
	match kind:
		"azazel", "patron_azazel_chains": return texture(ROOT + "/icons/patron_azazel_icon.png")
		"mammon", "patron_mammon_furnace": return texture(ROOT + "/icons/patron_mammon_icon.png")
		"minos", "patron_minos_judge": return texture(ROOT + "/icons/patron_minos_icon.png")
		"gold": return texture(ROOT + "/icons/ui_icon_gold.png")
		"health": return texture(ROOT + "/icons/ui_icon_health.png")
		"forge": return texture(ROOT + "/icons/ui_icon_forge.png")
		"fountain": return texture(ROOT + "/icons/ui_icon_fountain.png")
		"elite": return texture(ROOT + "/icons/ui_icon_elite.png")
		"boss": return texture(ROOT + "/icons/ui_icon_boss.png")
		"ascension": return texture(ROOT + "/icons/ui_icon_ascension.png")
	return texture(ROOT + "/icons/ui_icon_boon.png")

static func patron_color(patron_id: String) -> Color:
	match patron_id:
		"patron_azazel_chains": return Color(0.83, 0.56, 0.26, 1.0)
		"patron_mammon_furnace": return Color(0.94, 0.34, 0.14, 1.0)
		"patron_minos_judge": return Color(0.74, 0.66, 0.48, 1.0)
	return Color(0.78, 0.62, 0.38, 1.0)

static func rarity_color(rarity: String) -> Color:
	match rarity.to_lower():
		"rare": return Color(0.38, 0.68, 0.90, 1.0)
		"legendary", "epic": return Color(1.0, 0.68, 0.18, 1.0)
	return Color(0.72, 0.66, 0.56, 1.0)
