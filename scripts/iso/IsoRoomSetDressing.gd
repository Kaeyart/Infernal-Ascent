extends Node2D

class_name IsoRoomSetDressing
## V17 — Room Design Consistency Pass.
## Runtime-drawn Circle 0 room dressing. This is not final art; it is a layout/readability pass.

@export var room_type: String = "combat"
@export var variant: String = "ash_intake_hall"
@export var depth: int = 1
@export var debug_labels: bool = false
@export var show_layout_readability_marks: bool = true

var _time: float = 0.0

func setup(data: Dictionary) -> void:
	z_index = -12
	z_as_relative = false
	room_type = str(data.get("room_type", room_type))
	variant = str(data.get("variant", variant))
	depth = int(data.get("depth", depth))
	debug_labels = bool(data.get("debug_labels", debug_labels))
	add_to_group("circle0_room_dressing")
	queue_redraw()

func _ready() -> void:
	add_to_group("circle0_room_dressing")
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	_draw_floor_base()
	_draw_boundary_language()
	if show_layout_readability_marks:
		_draw_layout_readability_marks()
	match variant:
		"cinder_drain":
			_draw_cinder_drain()
		"furnace_vestibule":
			_draw_furnace_vestibule()
		"chain_reservoir":
			_draw_chain_reservoir()
		"ember_sorting_floor":
			_draw_ember_sorting_floor()
		"penitent_crossing":
			_draw_penitent_crossing()
		"reward_altar":
			_draw_reward_altar_room()
		"ash_fountain":
			_draw_fountain_room()
		"cold_forge":
			_draw_forge_room()
		"silent_shop":
			_draw_shop_room()
		"route_gate_crossing":
			_draw_route_crossing()
		_:
			_draw_ash_intake_hall()
	if debug_labels:
		_draw_debug_label()

func _draw_floor_base() -> void:
	var floor: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -282.0),
		Vector2(360.0, -104.0),
		Vector2(286.0, 110.0),
		Vector2(0.0, 196.0),
		Vector2(-286.0, 110.0),
		Vector2(-360.0, -104.0),
	])
	draw_colored_polygon(floor, Color(0.072, 0.062, 0.054, 0.84))
	draw_polyline(PackedVector2Array([floor[0], floor[1], floor[2], floor[3], floor[4], floor[5], floor[0]]), Color(0.48, 0.27, 0.14, 0.78), 2.0)
	for i: int in range(-5, 6):
		var y: float = -104.0 + float(i) * 34.0
		draw_line(Vector2(-318.0, y), Vector2(318.0, y), Color(0.16, 0.115, 0.080, 0.22), 1.0)
	for i: int in range(-4, 5):
		var x: float = float(i) * 70.0
		draw_line(Vector2(x - 160.0, 138.0), Vector2(x + 160.0, -202.0), Color(0.11, 0.085, 0.065, 0.16), 1.0)

func _draw_boundary_language() -> void:
	_draw_wall_segment(Vector2(-262.0, -196.0), Vector2(-92.0, -258.0))
	_draw_wall_segment(Vector2(262.0, -196.0), Vector2(92.0, -258.0))
	_draw_wall_segment(Vector2(-346.0, -95.0), Vector2(-284.0, 64.0))
	_draw_wall_segment(Vector2(346.0, -95.0), Vector2(284.0, 64.0))
	_draw_pillar(Vector2(-300.0, -92.0), 1.15)
	_draw_pillar(Vector2(300.0, -92.0), 1.15)
	_draw_pillar(Vector2(-210.0, 116.0), 0.82)
	_draw_pillar(Vector2(210.0, 116.0), 0.82)
	_draw_ash_pile(Vector2(-252.0, 72.0), 43.0)
	_draw_ash_pile(Vector2(252.0, 72.0), 39.0)

func _draw_layout_readability_marks() -> void:
	# These are deliberately subtle. They make layout zones readable without becoming UI.
	_draw_zone_ellipse(Vector2(0.0, 118.0), Vector2(96.0, 26.0), Color(0.30, 0.45, 0.34, 0.13), Color(0.42, 0.68, 0.47, 0.24))
	_draw_zone_ellipse(Vector2(0.0, -198.0), Vector2(128.0, 28.0), Color(0.55, 0.28, 0.12, 0.12), Color(0.85, 0.42, 0.18, 0.25))
	if room_type == "combat" or room_type == "elite_combat":
		for pos: Vector2 in _enemy_zone_points():
			_draw_zone_ellipse(pos, Vector2(48.0, 15.0), Color(0.58, 0.17, 0.11, 0.09), Color(0.90, 0.35, 0.22, 0.18))

func _enemy_zone_points() -> Array[Vector2]:
	match variant:
		"cinder_drain":
			return [Vector2(-215.0, -82.0), Vector2(215.0, -82.0), Vector2(-82.0, -162.0), Vector2(82.0, -162.0)]
		"furnace_vestibule":
			return [Vector2(-210.0, -132.0), Vector2(210.0, -132.0), Vector2(-130.0, -12.0), Vector2(130.0, -12.0)]
		"chain_reservoir":
			return [Vector2(-230.0, -35.0), Vector2(230.0, -35.0), Vector2(-120.0, -158.0), Vector2(120.0, -158.0)]
		"ember_sorting_floor":
			return [Vector2(-190.0, -58.0), Vector2(190.0, -58.0), Vector2(-42.0, -176.0), Vector2(130.0, 18.0)]
		"penitent_crossing":
			return [Vector2(-208.0, -112.0), Vector2(208.0, -112.0), Vector2(-74.0, -188.0), Vector2(74.0, -188.0)]
	return [Vector2(-175.0, -112.0), Vector2(175.0, -112.0), Vector2(-65.0, -172.0), Vector2(65.0, -172.0)]

func _draw_ash_intake_hall() -> void:
	_draw_room_title_sigil(Vector2(0.0, -210.0), "I")
	_draw_grate(Vector2(0.0, -84.0), 142.0, 50.0)
	_draw_broken_column(Vector2(-135.0, -32.0))
	_draw_broken_column(Vector2(135.0, -22.0))
	_draw_hanging_chain(Vector2(-75.0, -225.0), 105.0)
	_draw_hanging_chain(Vector2(75.0, -225.0), 94.0)
	_draw_ash_pile(Vector2(0.0, 22.0), 36.0)

func _draw_cinder_drain() -> void:
	_draw_room_title_sigil(Vector2(0.0, -210.0), "D")
	_draw_channel(Vector2(-230.0, -58.0), Vector2(230.0, -58.0), 36.0)
	_draw_channel(Vector2(0.0, -176.0), Vector2(0.0, 78.0), 24.0)
	_draw_grate(Vector2(-118.0, -58.0), 76.0, 30.0)
	_draw_grate(Vector2(118.0, -58.0), 76.0, 30.0)
	_draw_ash_pile(Vector2(-42.0, 58.0), 34.0)
	_draw_ash_pile(Vector2(74.0, 62.0), 28.0)

func _draw_furnace_vestibule() -> void:
	_draw_room_title_sigil(Vector2(0.0, -210.0), "F")
	_draw_furnace(Vector2(-224.0, -126.0))
	_draw_furnace(Vector2(224.0, -126.0))
	_draw_grate(Vector2(0.0, -70.0), 170.0, 54.0)
	_draw_hanging_chain(Vector2(0.0, -238.0), 122.0)
	_draw_ash_pile(Vector2(0.0, 76.0), 50.0)
	_draw_chain_on_floor(Vector2(-170.0, 34.0), Vector2(170.0, 50.0))

func _draw_chain_reservoir() -> void:
	_draw_room_title_sigil(Vector2(0.0, -210.0), "C")
	_draw_reservoir(Vector2(0.0, -82.0))
	_draw_hanging_chain(Vector2(-176.0, -244.0), 156.0)
	_draw_hanging_chain(Vector2(176.0, -244.0), 156.0)
	_draw_chain_on_floor(Vector2(-220.0, 30.0), Vector2(-42.0, 112.0))
	_draw_chain_on_floor(Vector2(220.0, 30.0), Vector2(42.0, 112.0))

func _draw_ember_sorting_floor() -> void:
	_draw_room_title_sigil(Vector2(0.0, -210.0), "E")
	_draw_sorting_belt(Vector2(0.0, -78.0))
	_draw_crate(Vector2(-196.0, -2.0))
	_draw_crate(Vector2(204.0, -4.0))
	_draw_grate(Vector2(-82.0, -52.0), 92.0, 34.0)
	_draw_ash_pile(Vector2(108.0, 58.0), 45.0)
	_draw_small_altar(Vector2(0.0, 58.0), Color(0.55, 0.32, 0.16, 0.64))

func _draw_penitent_crossing() -> void:
	_draw_room_title_sigil(Vector2(0.0, -210.0), "P")
	_draw_slab_walkway(Vector2(-238.0, -98.0), Vector2(238.0, -98.0), 42.0)
	_draw_slab_walkway(Vector2(0.0, -214.0), Vector2(0.0, 80.0), 36.0)
	_draw_small_altar(Vector2(0.0, -124.0), Color(0.70, 0.55, 0.34, 0.70))
	_draw_candle_cluster(Vector2(-134.0, -30.0))
	_draw_candle_cluster(Vector2(134.0, -30.0))
	_draw_broken_column(Vector2(-76.0, 38.0))
	_draw_broken_column(Vector2(76.0, 38.0))

func _draw_reward_altar_room() -> void:
	_draw_sigil_circle(Vector2(0.0, -58.0), 132.0, Color(0.55, 0.76, 0.38, 0.34))
	_draw_small_altar(Vector2(0.0, -68.0), Color(0.42, 0.64, 0.30, 0.95))
	_draw_pedestal_socket(Vector2(-128.0, 8.0), Color(0.44, 0.72, 0.36, 0.45))
	_draw_pedestal_socket(Vector2(0.0, -34.0), Color(0.44, 0.72, 0.36, 0.45))
	_draw_pedestal_socket(Vector2(128.0, 8.0), Color(0.44, 0.72, 0.36, 0.45))
	_draw_candle_cluster(Vector2(-160.0, 52.0))
	_draw_candle_cluster(Vector2(160.0, 52.0))

func _draw_fountain_room() -> void:
	_draw_sigil_circle(Vector2(0.0, -66.0), 136.0, Color(0.26, 0.56, 0.80, 0.32))
	_draw_pool(Vector2(0.0, -72.0))
	_draw_candle_cluster(Vector2(-150.0, 38.0))
	_draw_candle_cluster(Vector2(150.0, 38.0))

func _draw_forge_room() -> void:
	_draw_furnace(Vector2(0.0, -142.0))
	_draw_anvil(Vector2(0.0, -56.0))
	_draw_chain_on_floor(Vector2(-152.0, 34.0), Vector2(140.0, 54.0))
	_draw_crate(Vector2(-176.0, -30.0))
	_draw_crate(Vector2(176.0, -30.0))

func _draw_shop_room() -> void:
	_draw_counter(Vector2(0.0, -78.0))
	_draw_crate(Vector2(-178.0, -24.0))
	_draw_crate(Vector2(182.0, -30.0))
	_draw_candle_cluster(Vector2(0.0, 50.0))
	_draw_sigil_circle(Vector2(0.0, -68.0), 108.0, Color(0.74, 0.50, 0.22, 0.18))

func _draw_route_crossing() -> void:
	_draw_sigil_circle(Vector2(0.0, -122.0), 170.0, Color(0.78, 0.44, 0.22, 0.25))
	_draw_gate_socket(Vector2(-220.0, -122.0), Color(0.80, 0.34, 0.16, 0.42))
	_draw_gate_socket(Vector2(0.0, -182.0), Color(0.90, 0.58, 0.20, 0.42))
	_draw_gate_socket(Vector2(220.0, -122.0), Color(0.80, 0.34, 0.16, 0.42))
	_draw_wall_segment(Vector2(-260.0, -165.0), Vector2(-148.0, -230.0))
	_draw_wall_segment(Vector2(260.0, -165.0), Vector2(148.0, -230.0))
	_draw_hanging_chain(Vector2(0.0, -250.0), 86.0)

func _draw_zone_ellipse(pos: Vector2, radius: Vector2, fill: Color, outline: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(36):
		var a: float = TAU * float(i) / 36.0
		pts.append(pos + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, fill)
	draw_polyline(_closed_polyline(pts), outline, 1.0)

func _closed_polyline(points: PackedVector2Array) -> PackedVector2Array:
	var closed: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in points:
		closed.append(point)
	if points.size() > 0:
		closed.append(points[0])
	return closed

func _draw_pillar(pos: Vector2, scale_value: float) -> void:
	draw_rect(Rect2(pos + Vector2(-18.0, -58.0) * scale_value, Vector2(36.0, 76.0) * scale_value), Color(0.11, 0.10, 0.09, 0.94), true)
	draw_rect(Rect2(pos + Vector2(-18.0, -58.0) * scale_value, Vector2(36.0, 76.0) * scale_value), Color(0.52, 0.33, 0.20, 0.72), false, 2.0)
	_draw_ash_pile(pos + Vector2(0.0, 22.0), 20.0 * scale_value)

func _draw_broken_column(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-17.0, -34.0), Vector2(34.0, 48.0)), Color(0.13, 0.12, 0.11, 0.95), true)
	draw_line(pos + Vector2(-14.0, -24.0), pos + Vector2(15.0, -33.0), Color(0.60, 0.38, 0.22, 0.70), 2.0)
	_draw_ash_pile(pos + Vector2(0.0, 19.0), 23.0)

func _draw_wall_segment(a: Vector2, b: Vector2) -> void:
	draw_line(a + Vector2(0.0, 10.0), b + Vector2(0.0, 10.0), Color(0.0, 0.0, 0.0, 0.30), 10.0)
	draw_line(a, b, Color(0.24, 0.17, 0.12, 0.88), 10.0)
	draw_line(a, b, Color(0.66, 0.35, 0.16, 0.52), 2.0)

func _draw_ash_pile(pos: Vector2, size: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(22):
		var a: float = TAU * float(i) / 22.0
		var r: float = size * (0.72 + 0.20 * sin(float(i) * 1.7))
		pts.append(pos + Vector2(cos(a) * r, sin(a) * r * 0.42))
	draw_colored_polygon(pts, Color(0.16, 0.13, 0.11, 0.75))

func _draw_grate(pos: Vector2, width: float, height: float) -> void:
	var rect: Rect2 = Rect2(pos - Vector2(width * 0.5, height * 0.5), Vector2(width, height))
	draw_rect(rect, Color(0.055, 0.045, 0.040, 0.95), true)
	draw_rect(rect, Color(0.66, 0.25, 0.10, 0.80), false, 2.0)
	for i: int in range(7):
		var x: float = rect.position.x + float(i + 1) * rect.size.x / 8.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), Color(0.77, 0.32, 0.12, 0.50), 1.0)

func _draw_channel(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a, b, Color(0.045, 0.035, 0.030, 0.92), width)
	draw_line(a, b, Color(0.76, 0.28, 0.09, 0.35), maxf(2.0, width * 0.25))

func _draw_hanging_chain(pos: Vector2, length: float) -> void:
	var links: int = int(length / 13.0)
	for i: int in range(links):
		var p: Vector2 = pos + Vector2(0.0, float(i) * 13.0)
		draw_arc(p, 5.0, 0.0, TAU, 12, Color(0.45, 0.35, 0.26, 0.76), 1.5)

func _draw_chain_on_floor(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, Color(0.10, 0.08, 0.07, 0.72), 5.0)
	for i: int in range(9):
		var p: Vector2 = a.lerp(b, float(i) / 8.0)
		draw_arc(p, 5.0, 0.0, TAU, 10, Color(0.50, 0.38, 0.24, 0.82), 1.0)

func _draw_furnace(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-52.0, -64.0), Vector2(104.0, 74.0)), Color(0.12, 0.075, 0.052, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-52.0, -64.0), Vector2(104.0, 74.0)), Color(0.72, 0.31, 0.12, 0.72), false, 2.0)
	var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
	draw_rect(Rect2(pos + Vector2(-30.0, -40.0), Vector2(60.0, 28.0)), Color(1.0, 0.23, 0.05, 0.18 + 0.18 * pulse), true)

func _draw_reservoir(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-122.0, -48.0), Vector2(244.0, 76.0)), Color(0.055, 0.050, 0.048, 0.94), true)
	draw_rect(Rect2(pos + Vector2(-122.0, -48.0), Vector2(244.0, 76.0)), Color(0.42, 0.32, 0.23, 0.80), false, 2.0)
	draw_rect(Rect2(pos + Vector2(-102.0, -28.0), Vector2(204.0, 38.0)), Color(0.14, 0.10, 0.08, 0.72), true)

func _draw_sorting_belt(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-176.0, -25.0), Vector2(352.0, 50.0)), Color(0.075, 0.060, 0.050, 0.94), true)
	draw_rect(Rect2(pos + Vector2(-176.0, -25.0), Vector2(352.0, 50.0)), Color(0.52, 0.29, 0.16, 0.74), false, 2.0)
	for i: int in range(8):
		var x: float = pos.x - 152.0 + float(i) * 43.0
		draw_rect(Rect2(Vector2(x, pos.y - 18.0), Vector2(24.0, 36.0)), Color(0.13, 0.10, 0.08, 0.74), true)

func _draw_slab_walkway(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a, b, Color(0.12, 0.105, 0.095, 0.88), width)
	draw_line(a, b, Color(0.55, 0.36, 0.20, 0.38), 2.0)

func _draw_crate(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-24.0, -30.0), Vector2(48.0, 42.0)), Color(0.17, 0.10, 0.055, 0.92), true)
	draw_rect(Rect2(pos + Vector2(-24.0, -30.0), Vector2(48.0, 42.0)), Color(0.55, 0.32, 0.16, 0.72), false, 2.0)
	draw_line(pos + Vector2(-20.0, -26.0), pos + Vector2(20.0, 8.0), Color(0.48, 0.25, 0.12, 0.76), 2.0)
	draw_line(pos + Vector2(20.0, -26.0), pos + Vector2(-20.0, 8.0), Color(0.48, 0.25, 0.12, 0.76), 2.0)

func _draw_sigil_circle(pos: Vector2, radius: float, color: Color) -> void:
	draw_arc(pos, radius, 0.0, TAU, 80, color, 2.0)
	draw_arc(pos, radius * 0.72, 0.0, TAU, 80, Color(color.r, color.g, color.b, color.a * 0.70), 1.5)
	for i: int in range(6):
		var a: float = TAU * float(i) / 6.0
		draw_line(pos, pos + Vector2(cos(a), sin(a)) * radius, Color(color.r, color.g, color.b, color.a * 0.40), 1.0)

func _draw_room_title_sigil(pos: Vector2, glyph: String) -> void:
	_draw_sigil_circle(pos, 28.0, Color(0.80, 0.45, 0.20, 0.22))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-7.0, 7.0), glyph, HORIZONTAL_ALIGNMENT_CENTER, 14.0, 13, Color(0.92, 0.70, 0.44, 0.44))

func _draw_small_altar(pos: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos + Vector2(-42.0, -24.0), Vector2(84.0, 36.0)), Color(0.08, 0.065, 0.052, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-42.0, -24.0), Vector2(84.0, 36.0)), color, false, 2.0)
	draw_line(pos + Vector2(0.0, -58.0), pos + Vector2(0.0, -22.0), Color(0.95, 0.80, 0.50, 0.85), 2.0)
	draw_line(pos + Vector2(-17.0, -40.0), pos + Vector2(17.0, -40.0), Color(0.95, 0.80, 0.50, 0.85), 2.0)

func _draw_pedestal_socket(pos: Vector2, color: Color) -> void:
	_draw_zone_ellipse(pos, Vector2(42.0, 14.0), Color(color.r, color.g, color.b, 0.10), color)
	draw_rect(Rect2(pos + Vector2(-18.0, -25.0), Vector2(36.0, 26.0)), Color(0.09, 0.075, 0.060, 0.90), true)
	draw_rect(Rect2(pos + Vector2(-18.0, -25.0), Vector2(36.0, 26.0)), color, false, 1.5)

func _draw_gate_socket(pos: Vector2, color: Color) -> void:
	_draw_zone_ellipse(pos, Vector2(56.0, 19.0), Color(color.r, color.g, color.b, 0.12), color)
	draw_line(pos + Vector2(-30.0, -18.0), pos + Vector2(-8.0, -42.0), color, 3.0)
	draw_line(pos + Vector2(30.0, -18.0), pos + Vector2(8.0, -42.0), color, 3.0)
	draw_arc(pos + Vector2(0.0, -22.0), 28.0, PI, TAU, 24, color, 2.0)

func _draw_pool(pos: Vector2) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(32):
		var a: float = TAU * float(i) / 32.0
		pts.append(pos + Vector2(cos(a) * 82.0, sin(a) * 33.0))
	draw_colored_polygon(pts, Color(0.10, 0.22, 0.30, 0.82))
	draw_polyline(_closed_polyline(pts), Color(0.40, 0.72, 0.92, 0.78), 2.0)

func _draw_anvil(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-42.0, -25.0), Vector2(84.0, 20.0)), Color(0.16, 0.15, 0.14, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-20.0, -5.0), Vector2(40.0, 24.0)), Color(0.12, 0.11, 0.10, 0.96), true)
	draw_line(pos + Vector2(-45.0, -15.0), pos + Vector2(45.0, -15.0), Color(0.72, 0.62, 0.48, 0.70), 2.0)

func _draw_counter(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-112.0, -36.0), Vector2(224.0, 54.0)), Color(0.11, 0.08, 0.075, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-112.0, -36.0), Vector2(224.0, 54.0)), Color(0.62, 0.40, 0.20, 0.72), false, 2.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-22.0, -4.0), "?", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 22, Color(0.95, 0.77, 0.40, 0.9))

func _draw_candle_cluster(pos: Vector2) -> void:
	for i: int in range(3):
		var x: float = -12.0 + float(i) * 12.0
		draw_rect(Rect2(pos + Vector2(x - 2.0, -16.0), Vector2(4.0, 18.0)), Color(0.74, 0.60, 0.42, 0.90), true)
		draw_circle(pos + Vector2(x, -18.0), 3.0, Color(1.0, 0.62, 0.22, 0.75))

func _draw_debug_label() -> void:
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2(-168.0, 204.0), Vector2(336.0, 34.0)), Color(0.0, 0.0, 0.0, 0.58), true)
	draw_string(font, Vector2(-162.0, 226.0), "%s | %s | depth %d" % [room_type, variant, depth], HORIZONTAL_ALIGNMENT_CENTER, 324.0, 12, Color(0.95, 0.82, 0.58, 1.0))
