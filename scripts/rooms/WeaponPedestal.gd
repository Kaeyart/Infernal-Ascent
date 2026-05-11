extends Node2D

signal weapon_selected(weapon: WeaponData)

@export var weapon: WeaponData
@export var interact_radius: float = 96.0
@export var display_name: String = "Weapon"

var player: Node2D = null
var is_player_near: bool = false
var pulse_time: float = 0.0
var just_equipped_timer: float = 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	pulse_time += delta
	just_equipped_timer = maxf(0.0, just_equipped_timer - delta)

	player = get_tree().get_first_node_in_group("player") as Node2D
	is_player_near = false

	if player != null:
		is_player_near = global_position.distance_to(player.global_position) <= interact_radius

		if is_player_near and _is_interact_pressed():
			_equip_weapon()

	queue_redraw()


func _is_interact_pressed() -> bool:
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		return true

	return Input.is_physical_key_pressed(KEY_E)


func _equip_weapon() -> void:
	if weapon == null:
		return

	if has_node("/root/GameState"):
		var game_state: Node = get_node("/root/GameState")

		if game_state != null:
			game_state.set("selected_weapon", weapon)

	var found_player: Node = get_tree().get_first_node_in_group("player")

	if found_player != null and found_player.has_node("WeaponController"):
		var controller: Node = found_player.get_node("WeaponController")

		if controller != null and controller.has_method("set_weapon"):
			controller.call("set_weapon", weapon)

	just_equipped_timer = 1.0
	weapon_selected.emit(weapon)


func _draw() -> void:
	_draw_pedestal_base()
	_draw_weapon_marker()
	_draw_weapon_name()

	if is_player_near:
		_draw_interaction_prompt()
		_draw_weapon_card()

	if just_equipped_timer > 0.0:
		_draw_equipped_flash()


func _draw_pedestal_base() -> void:
	var base_color: Color = Color("#21151a")
	var ring_color: Color = Color("#dfaa46")

	if is_player_near:
		base_color = Color("#33201a")
		ring_color = Color("#f0b24f")

	if weapon != null:
		ring_color = weapon.primary_color

	var pulse: float = 0.5 + 0.25 * absf(sin(pulse_time * 2.4))

	draw_circle(Vector2.ZERO, 56.0, Color(0, 0, 0, 0.38))
	draw_circle(Vector2.ZERO, 47.0, base_color)
	draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 64, ring_color.darkened(0.28), 4.0)
	draw_arc(Vector2.ZERO, 54.0 + pulse * 4.0, 0.0, TAU, 64, Color(ring_color.r, ring_color.g, ring_color.b, 0.22), 2.0)
	draw_line(Vector2(-36, 0), Vector2(36, 0), Color(ring_color.r, ring_color.g, ring_color.b, 0.16), 2.0)
	draw_line(Vector2(0, -36), Vector2(0, 36), Color(ring_color.r, ring_color.g, ring_color.b, 0.14), 2.0)


func _draw_weapon_marker() -> void:
	var color: Color = Color("#dfaa46")

	if weapon != null:
		color = weapon.primary_color

	draw_line(Vector2(-18, 16), Vector2(22, -28), color, 5.0)
	draw_line(Vector2(-20, 13), Vector2(10, 24), color.lightened(0.18), 4.0)
	draw_line(Vector2(-4, -6), Vector2(13, 10), Color("#f7e8d4"), 2.0)
	draw_circle(Vector2(22, -28), 4.0, color.lightened(0.25))


func _draw_weapon_name() -> void:
	var name_text: String = display_name

	if weapon != null:
		name_text = weapon.display_name

	draw_string(ThemeDB.fallback_font, Vector2(-92, 72), name_text, HORIZONTAL_ALIGNMENT_CENTER, 184, 14, Color("#f7e8d4"))
	draw_string(ThemeDB.fallback_font, Vector2(-92, 88), "Armament Chapel", HORIZONTAL_ALIGNMENT_CENTER, 184, 10, Color("#c4a98f"))


func _draw_interaction_prompt() -> void:
	var panel: Rect2 = Rect2(Vector2(-134, -110), Vector2(268, 34))
	var color: Color = Color("#dfaa46")

	if weapon != null:
		color = weapon.primary_color

	draw_rect(panel, Color(0.018, 0.010, 0.008, 0.88))
	draw_rect(panel, Color(color.r, color.g, color.b, 0.12))
	draw_rect(panel, color, false, 1.5)
	draw_rect(panel.grow(-5), Color(1, 1, 1, 0.05), false, 1.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(0, 22), "[E] Equip Weapon — Penitent Blade", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 13, Color("#f7e8d4"))


func _draw_weapon_card() -> void:
	if weapon == null:
		return

	var panel: Rect2 = Rect2(Vector2(-205, -245), Vector2(410, 142))

	draw_rect(panel, Color(0.025, 0.014, 0.012, 0.94))
	draw_rect(Rect2(panel.position + Vector2(9, 9), panel.size - Vector2(18, 18)), Color(0.09, 0.035, 0.028, 0.86))
	draw_rect(panel, Color("#6b2a1f"), false, 3.0)
	draw_rect(panel.grow(-7), weapon.primary_color, false, 1.0)

	draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 25), weapon.display_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 380, 18, weapon.primary_color.lightened(0.15))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 47), weapon.get_tags_text(), HORIZONTAL_ALIGNMENT_LEFT, 380, 12, Color("#c4a98f"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 70), "Light: %s" % weapon.light_description, HORIZONTAL_ALIGNMENT_LEFT, 380, 11, Color("#f7e8d4"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 88), "Heavy: %s" % weapon.heavy_description, HORIZONTAL_ALIGNMENT_LEFT, 380, 11, Color("#f7e8d4"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 106), "Q: %s" % weapon.q_description, HORIZONTAL_ALIGNMENT_LEFT, 380, 11, Color("#f7e8d4"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(14, 127), "Enter the Reliquary to change your current weapon.", HORIZONTAL_ALIGNMENT_CENTER, 380, 11, Color("#8f7a64"))


func _draw_equipped_flash() -> void:
	var alpha: float = clampf(just_equipped_timer, 0.0, 1.0)
	var color: Color = Color("#dfaa46")

	if weapon != null:
		color = weapon.primary_color

	draw_arc(Vector2.ZERO, 64.0 + (1.0 - alpha) * 28.0, 0.0, TAU, 64, Color(color.r, color.g, color.b, alpha), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(-82, -78), "EQUIPPED", HORIZONTAL_ALIGNMENT_CENTER, 164, 15, Color(color.r, color.g, color.b, alpha))
