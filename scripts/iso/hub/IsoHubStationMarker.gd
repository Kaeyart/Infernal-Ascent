extends Node2D
class_name IsoHubStationMarker

## V26 — Hub Stations V1.
## Lightweight world-space station marker used by the hub runtime.
## It is intentionally drawn in code so V26 does not require scene editing.

@export var station_title: String = "Station"
@export var station_kind: String = "station"
@export var action_label: String = "[E] Inspect"
@export var accent_color: Color = Color("#c59254")
@export var locked: bool = false
@export var focused: bool = false
@export var show_prompt_when_focused: bool = true

func setup(p_title: String, p_kind: String, p_action_label: String, p_accent_color: Color, p_locked: bool = false) -> void:
	station_title = p_title
	station_kind = p_kind
	action_label = p_action_label
	accent_color = p_accent_color
	locked = p_locked
	queue_redraw()

func set_focused(p_focused: bool) -> void:
	if focused == p_focused:
		return
	focused = p_focused
	queue_redraw()

func _draw() -> void:
	_draw_shadow()
	_draw_station_icon()
	_draw_nameplate()
	if show_prompt_when_focused and focused:
		_draw_prompt()

func _draw_shadow() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = Vector2(0.0, 23.0)
	for i: int in range(32):
		var angle: float = TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * 33.0, sin(angle) * 9.0))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.34))

func _draw_station_icon() -> void:
	var fill: Color = Color(0.045, 0.035, 0.030, 0.92)
	var border: Color = accent_color
	if locked:
		fill = Color(0.028, 0.026, 0.027, 0.86)
		border = Color(0.44, 0.38, 0.33, 0.95)
	if focused:
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 48, Color(accent_color.r, accent_color.g, accent_color.b, 0.40), 4.0)

	# Isometric stone plinth.
	var diamond: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -30.0),
		Vector2(34.0, -8.0),
		Vector2(0.0, 17.0),
		Vector2(-34.0, -8.0),
	])
	draw_colored_polygon(diamond, fill)
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), border, 2.0)

	# Station glyphs. Simple, readable placeholder symbols; final art comes later.
	if station_kind == "run_start":
		draw_arc(Vector2(0.0, -9.0), 16.0, -PI * 0.80, PI * 0.80, 24, accent_color, 3.0)
		draw_line(Vector2(0.0, -25.0), Vector2(0.0, 5.0), accent_color, 2.0)
	elif station_kind == "training_dummy":
		draw_circle(Vector2(0.0, -11.0), 12.0, Color(accent_color.r, accent_color.g, accent_color.b, 0.20))
		draw_arc(Vector2(0.0, -11.0), 12.0, 0.0, TAU, 32, accent_color, 2.0)
		draw_line(Vector2(-13.0, -11.0), Vector2(13.0, -11.0), accent_color, 1.5)
		draw_line(Vector2(0.0, -24.0), Vector2(0.0, 2.0), accent_color, 1.5)
	elif station_kind == "memory_pool":
		draw_arc(Vector2(0.0, -10.0), 16.0, 0.0, TAU, 36, accent_color, 2.0)
		draw_arc(Vector2(0.0, -10.0), 9.0, 0.0, TAU, 24, Color(accent_color.r, accent_color.g, accent_color.b, 0.45), 1.5)
	elif station_kind == "upgrade_altar":
		draw_line(Vector2(-12.0, 3.0), Vector2(0.0, -24.0), accent_color, 3.0)
		draw_line(Vector2(12.0, 3.0), Vector2(0.0, -24.0), accent_color, 3.0)
		draw_line(Vector2(-14.0, -8.0), Vector2(14.0, -8.0), accent_color, 2.0)
	elif station_kind == "hub_forge":
		draw_rect(Rect2(Vector2(-13.0, -20.0), Vector2(26.0, 19.0)), Color(accent_color.r, accent_color.g, accent_color.b, 0.18), true)
		draw_rect(Rect2(Vector2(-13.0, -20.0), Vector2(26.0, 19.0)), accent_color, false, 2.0)
		draw_line(Vector2(-18.0, 3.0), Vector2(18.0, 3.0), accent_color, 2.0)
	elif station_kind == "codex":
		draw_rect(Rect2(Vector2(-14.0, -23.0), Vector2(24.0, 29.0)), Color(0.12, 0.09, 0.06, 0.92), true)
		draw_rect(Rect2(Vector2(-14.0, -23.0), Vector2(24.0, 29.0)), accent_color, false, 2.0)
		draw_line(Vector2(-9.0, -14.0), Vector2(6.0, -14.0), accent_color, 1.0)
		draw_line(Vector2(-9.0, -7.0), Vector2(6.0, -7.0), accent_color, 1.0)
	elif station_kind == "sealed_door":
		draw_rect(Rect2(Vector2(-15.0, -25.0), Vector2(30.0, 31.0)), Color(0.035, 0.030, 0.032, 0.95), true)
		draw_rect(Rect2(Vector2(-15.0, -25.0), Vector2(30.0, 31.0)), border, false, 2.0)
		draw_line(Vector2(-9.0, -9.0), Vector2(9.0, -9.0), border, 2.0)
		draw_circle(Vector2(0.0, -9.0), 4.0, border)
	else:
		draw_circle(Vector2(0.0, -10.0), 13.0, Color(accent_color.r, accent_color.g, accent_color.b, 0.18))
		draw_arc(Vector2(0.0, -10.0), 13.0, 0.0, TAU, 32, accent_color, 2.0)

func _draw_nameplate() -> void:
	var font: Font = ThemeDB.fallback_font
	var plate_width: float = clamp(float(station_title.length()) * 7.2 + 34.0, 112.0, 190.0)
	var plate: Rect2 = Rect2(Vector2(-plate_width * 0.5, 32.0), Vector2(plate_width, 32.0))
	var plate_color: Color = Color(0.025, 0.019, 0.016, 0.78)
	var border: Color = accent_color if not locked else Color(0.42, 0.36, 0.32, 0.95)
	draw_rect(plate, plate_color, true)
	draw_rect(plate, border, false, 1.0)
	draw_string(font, Vector2(plate.position.x + 8.0, 51.0), station_title, HORIZONTAL_ALIGNMENT_CENTER, plate_width - 16.0, 13, Color("#f2e4c8"))

func _draw_prompt() -> void:
	var font: Font = ThemeDB.fallback_font
	var prompt_width: float = clamp(float(action_label.length()) * 7.0 + 34.0, 120.0, 220.0)
	var prompt_rect: Rect2 = Rect2(Vector2(-prompt_width * 0.5, 68.0), Vector2(prompt_width, 28.0))
	draw_rect(prompt_rect, Color(0.055, 0.039, 0.027, 0.92), true)
	draw_rect(prompt_rect, accent_color, false, 1.0)
	draw_string(font, Vector2(prompt_rect.position.x + 9.0, 87.0), action_label, HORIZONTAL_ALIGNMENT_CENTER, prompt_width - 18.0, 12, Color("#f0d7a2"))
