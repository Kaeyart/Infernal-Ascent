extends Node2D

class_name IsoHubTrainingDummy

signal damaged(amount: int, remaining_health: int)
signal died

@export var max_health: int = 12
@export var display_name: String = "Training Dummy"
@export var show_debug_radius: bool = false
@export var hit_radius: float = 30.0

@export_category("Hit Reaction")
@export var recoil_distance_light: float = 7.0
@export var recoil_distance_heavy: float = 12.0
@export var recoil_return_speed: float = 18.0
@export var hit_flash_duration: float = 0.14

var current_health: int = 12
var is_dead: bool = false

var _hit_flash: float = 0.0
var _damage_numbers: Array[Dictionary] = []
var _visual_recoil_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("attack_target")
	current_health = max_health
	queue_redraw()

func reset_dummy() -> void:
	current_health = max_health
	is_dead = false
	_hit_flash = 0.0
	_damage_numbers.clear()
	_visual_recoil_offset = Vector2.ZERO
	queue_redraw()

func receive_player_hit(amount: int, source_global_position: Vector2, hit_direction: Vector2, attack_anim: String = "attack") -> void:
	var away: Vector2 = global_position - source_global_position
	if away.length() <= 0.01:
		away = hit_direction
	var distance: float = recoil_distance_heavy if attack_anim == "heavy_attack" else recoil_distance_light
	if away.length() > 0.01:
		_visual_recoil_offset = away.normalized() * distance
	take_damage(amount)

func take_damage(amount: int) -> void:
	if is_dead:
		_spawn_damage_number("DEAD", Color("#8f806c"))
		return
	var final_amount: int = max(0, amount)
	if final_amount <= 0:
		return
	current_health = max(0, current_health - final_amount)
	_hit_flash = hit_flash_duration
	_spawn_damage_number("-" + str(final_amount), Color("#f2d27b"))
	emit_signal("damaged", final_amount, current_health)
	if current_health <= 0:
		is_dead = true
		_spawn_damage_number("BROKEN", Color("#d06b4c"))
		emit_signal("died")
	queue_redraw()

func get_health_text() -> String:
	return "%d/%d" % [current_health, max_health]

func _process(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
	if _visual_recoil_offset.length() > 0.05:
		_visual_recoil_offset = _visual_recoil_offset.move_toward(Vector2.ZERO, recoil_return_speed * delta)
	else:
		_visual_recoil_offset = Vector2.ZERO
	for i: int in range(_damage_numbers.size() - 1, -1, -1):
		var number_data: Dictionary = _damage_numbers[i]
		number_data["life"] = float(number_data.get("life", 0.0)) - delta
		number_data["offset"] = (number_data.get("offset", Vector2.ZERO) as Vector2) + Vector2(0.0, -34.0 * delta)
		_damage_numbers[i] = number_data
		if float(number_data.get("life", 0.0)) <= 0.0:
			_damage_numbers.remove_at(i)
	queue_redraw()

func _draw() -> void:
	_draw_shadow()
	draw_set_transform(_visual_recoil_offset, 0.0, Vector2.ONE)
	_draw_dummy_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_health_bar()
	_draw_damage_numbers()
	if show_debug_radius:
		draw_arc(Vector2.ZERO, hit_radius, 0.0, TAU, 36, Color(0.3, 0.75, 1.0, 0.6), 1.0)

func _draw_shadow() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = Vector2(0.0, 19.0)
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * 25.0, sin(angle) * 8.0))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.34))

func _draw_dummy_body() -> void:
	var wood: Color = Color("#7b4b2a")
	var dark_wood: Color = Color("#3a2418")
	var cloth: Color = Color("#8b2d2d")
	var rope: Color = Color("#d2a45d")
	var flash: Color = Color("#f2d27b")
	if is_dead:
		wood = Color("#4d3425")
		dark_wood = Color("#211815")
		cloth = Color("#4d2020")
		rope = Color("#7d684e")
	if _hit_flash > 0.0 and not is_dead:
		wood = wood.lerp(flash, 0.55)
		cloth = cloth.lerp(flash, 0.35)
	draw_rect(Rect2(Vector2(-5.0, -36.0), Vector2(10.0, 58.0)), dark_wood, true)
	draw_rect(Rect2(Vector2(-7.0, 18.0), Vector2(14.0, 10.0)), dark_wood, true)
	var arm_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-30.0, -25.0),
		Vector2(30.0, -25.0),
		Vector2(27.0, -16.0),
		Vector2(-27.0, -16.0),
	])
	draw_colored_polygon(arm_poly, wood)
	draw_polyline(PackedVector2Array([arm_poly[0], arm_poly[1], arm_poly[2], arm_poly[3], arm_poly[0]]), dark_wood, 1.5)
	var torso: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -42.0),
		Vector2(20.0, -22.0),
		Vector2(16.0, 8.0),
		Vector2(0.0, 18.0),
		Vector2(-16.0, 8.0),
		Vector2(-20.0, -22.0),
	])
	draw_colored_polygon(torso, cloth)
	draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[4], torso[5], torso[0]]), dark_wood, 2.0)
	draw_circle(Vector2(0.0, -48.0), 12.0, cloth)
	draw_arc(Vector2(0.0, -48.0), 13.0, 0.0, TAU, 24, dark_wood, 2.0)
	draw_line(Vector2(-18.0, -18.0), Vector2(18.0, -13.0), rope, 2.0)
	draw_line(Vector2(-15.0, -3.0), Vector2(15.0, 1.0), rope, 2.0)
	draw_line(Vector2(-9.0, -50.0), Vector2(10.0, -45.0), rope, 2.0)
	draw_line(Vector2(-5.0, -51.0), Vector2(-1.0, -47.0), dark_wood, 1.5)
	draw_line(Vector2(-1.0, -51.0), Vector2(-5.0, -47.0), dark_wood, 1.5)
	draw_line(Vector2(4.0, -51.0), Vector2(8.0, -47.0), dark_wood, 1.5)
	draw_line(Vector2(8.0, -51.0), Vector2(4.0, -47.0), dark_wood, 1.5)
	if is_dead:
		draw_line(Vector2(-24.0, -46.0), Vector2(24.0, 10.0), Color("#d06b4c"), 3.0)
		draw_line(Vector2(24.0, -46.0), Vector2(-24.0, 10.0), Color("#d06b4c"), 3.0)

func _draw_health_bar() -> void:
	var font: Font = ThemeDB.fallback_font
	var bar_pos: Vector2 = Vector2(-36.0, -82.0)
	var bar_size: Vector2 = Vector2(72.0, 8.0)
	var fill_ratio: float = 0.0
	if max_health > 0:
		fill_ratio = float(current_health) / float(max_health)
	draw_rect(Rect2(bar_pos, bar_size), Color(0.0, 0.0, 0.0, 0.68), true)
	draw_rect(Rect2(bar_pos + Vector2(1.0, 1.0), Vector2((bar_size.x - 2.0) * fill_ratio, bar_size.y - 2.0)), Color("#c8503e"), true)
	draw_rect(Rect2(bar_pos, bar_size), Color("#d2a45d"), false, 1.0)
	var title: String = display_name
	if is_dead:
		title += " — Broken"
	draw_string(font, Vector2(-62.0, -91.0), title, HORIZONTAL_ALIGNMENT_CENTER, 124.0, 11, Color("#f2e4c8"))
	draw_string(font, Vector2(-36.0, -66.0), get_health_text(), HORIZONTAL_ALIGNMENT_CENTER, 72.0, 10, Color("#d7c5aa"))

func _draw_damage_numbers() -> void:
	var font: Font = ThemeDB.fallback_font
	for number_data: Dictionary in _damage_numbers:
		var life: float = float(number_data.get("life", 0.0))
		var alpha: float = clamp(life / 0.75, 0.0, 1.0)
		var text: String = str(number_data.get("text", "0"))
		var offset: Vector2 = number_data.get("offset", Vector2.ZERO) as Vector2
		var color: Color = number_data.get("color", Color("#f2d27b")) as Color
		color.a = alpha
		draw_string(font, Vector2(-40.0, -104.0) + offset, text, HORIZONTAL_ALIGNMENT_CENTER, 80.0, 16, color)

func _spawn_damage_number(text: String, color: Color) -> void:
	var random_x: float = randf_range(-10.0, 10.0)
	_damage_numbers.append({
		"text": text,
		"life": 0.75,
		"offset": Vector2(random_x, 0.0),
		"color": color,
	})
