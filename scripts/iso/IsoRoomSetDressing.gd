extends Node2D

class_name IsoRoomSetDressing

@export var room_type: String = "combat"
@export var variant: String = "ash_intake_hall"
@export var depth: int = 1
@export var debug_labels: bool = false

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
	_draw_boundary_shapes()
	match variant:
		"cinder_drain":
			_draw_cinder_drain()
		"furnace_vestibule":
			_draw_furnace_vestibule()
		"chain_reservoir":
			_draw_chain_reservoir()
		"ember_sorting_floor":
			_draw_ember_sorting_floor()
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
		Vector2(0.0, -260.0),
		Vector2(330.0, -95.0),
		Vector2(265.0, 95.0),
		Vector2(0.0, 170.0),
		Vector2(-265.0, 95.0),
		Vector2(-330.0, -95.0),
	])
	draw_colored_polygon(floor, Color(0.085, 0.072, 0.060, 0.72))
	draw_polyline(PackedVector2Array([floor[0], floor[1], floor[2], floor[3], floor[4], floor[5], floor[0]]), Color(0.42, 0.23, 0.12, 0.74), 2.0)
	for i: int in range(-4, 5):
		draw_line(Vector2(-300.0, -80.0 + i * 34.0), Vector2(300.0, -80.0 + i * 34.0), Color(0.18, 0.12, 0.08, 0.22), 1.0)

func _draw_boundary_shapes() -> void:
	_draw_pillar(Vector2(-286.0, -92.0), 1.0)
	_draw_pillar(Vector2(286.0, -92.0), 1.0)
	_draw_wall_segment(Vector2(-210.0, -190.0), Vector2(-55.0, -245.0))
	_draw_wall_segment(Vector2(210.0, -190.0), Vector2(55.0, -245.0))
	_draw_ash_pile(Vector2(-230.0, 80.0), 42.0)
	_draw_ash_pile(Vector2(230.0, 80.0), 38.0)

func _draw_ash_intake_hall() -> void:
	_draw_grate(Vector2(0.0, -74.0), 118.0, 42.0)
	_draw_broken_column(Vector2(-125.0, -35.0))
	_draw_broken_column(Vector2(122.0, -18.0))
	_draw_hanging_chain(Vector2(-65.0, -205.0), 92.0)
	_draw_hanging_chain(Vector2(65.0, -205.0), 82.0)

func _draw_cinder_drain() -> void:
	_draw_channel(Vector2(-180.0, -50.0), Vector2(180.0, -50.0), 32.0)
	_draw_channel(Vector2(0.0, -145.0), Vector2(0.0, 70.0), 22.0)
	_draw_grate(Vector2(-92.0, -48.0), 70.0, 28.0)
	_draw_grate(Vector2(96.0, -45.0), 70.0, 28.0)
	_draw_ash_pile(Vector2(-40.0, 55.0), 32.0)

func _draw_furnace_vestibule() -> void:
	_draw_furnace(Vector2(-190.0, -112.0))
	_draw_furnace(Vector2(190.0, -112.0))
	_draw_grate(Vector2(0.0, -56.0), 150.0, 48.0)
	_draw_hanging_chain(Vector2(0.0, -220.0), 110.0)
	_draw_ash_pile(Vector2(0.0, 76.0), 48.0)

func _draw_chain_reservoir() -> void:
	_draw_reservoir(Vector2(0.0, -74.0))
	_draw_hanging_chain(Vector2(-155.0, -230.0), 145.0)
	_draw_hanging_chain(Vector2(155.0, -230.0), 145.0)
	_draw_chain_on_floor(Vector2(-185.0, 35.0), Vector2(-45.0, 105.0))
	_draw_chain_on_floor(Vector2(185.0, 35.0), Vector2(45.0, 105.0))

func _draw_ember_sorting_floor() -> void:
	_draw_sorting_belt(Vector2(0.0, -70.0))
	_draw_crate(Vector2(-175.0, -10.0))
	_draw_crate(Vector2(185.0, -8.0))
	_draw_grate(Vector2(-70.0, -42.0), 90.0, 32.0)
	_draw_ash_pile(Vector2(95.0, 54.0), 44.0)

func _draw_reward_altar_room() -> void:
	_draw_sigil_circle(Vector2(0.0, -50.0), 116.0, Color(0.55, 0.76, 0.38, 0.34))
	_draw_small_altar(Vector2(0.0, -62.0), Color(0.42, 0.64, 0.30, 0.95))
	_draw_candle_cluster(Vector2(-120.0, 8.0))
	_draw_candle_cluster(Vector2(120.0, 8.0))

func _draw_fountain_room() -> void:
	_draw_sigil_circle(Vector2(0.0, -62.0), 128.0, Color(0.26, 0.56, 0.80, 0.32))
	_draw_pool(Vector2(0.0, -70.0))
	_draw_candle_cluster(Vector2(-135.0, 35.0))
	_draw_candle_cluster(Vector2(135.0, 35.0))

func _draw_forge_room() -> void:
	_draw_furnace(Vector2(0.0, -130.0))
	_draw_anvil(Vector2(0.0, -50.0))
	_draw_chain_on_floor(Vector2(-130.0, 30.0), Vector2(120.0, 50.0))
	_draw_crate(Vector2(-160.0, -36.0))
	_draw_crate(Vector2(160.0, -36.0))

func _draw_shop_room() -> void:
	_draw_counter(Vector2(0.0, -70.0))
	_draw_crate(Vector2(-160.0, -28.0))
	_draw_crate(Vector2(165.0, -34.0))
	_draw_candle_cluster(Vector2(0.0, 48.0))

func _draw_route_crossing() -> void:
	_draw_sigil_circle(Vector2(0.0, -105.0), 155.0, Color(0.78, 0.44, 0.22, 0.25))
	_draw_wall_segment(Vector2(-235.0, -160.0), Vector2(-140.0, -215.0))
	_draw_wall_segment(Vector2(235.0, -160.0), Vector2(140.0, -215.0))
	_draw_hanging_chain(Vector2(0.0, -240.0), 80.0)

func _draw_pillar(pos: Vector2, scale_value: float) -> void:
	draw_rect(Rect2(pos + Vector2(-18.0, -58.0) * scale_value, Vector2(36.0, 76.0) * scale_value), Color(0.11, 0.10, 0.09, 0.92), true)
	draw_rect(Rect2(pos + Vector2(-18.0, -58.0) * scale_value, Vector2(36.0, 76.0) * scale_value), Color(0.46, 0.31, 0.20, 0.72), false, 2.0)
	_draw_ash_pile(pos + Vector2(0.0, 22.0), 20.0 * scale_value)

func _draw_broken_column(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-17.0, -34.0), Vector2(34.0, 48.0)), Color(0.13, 0.12, 0.11, 0.95), true)
	draw_line(pos + Vector2(-14.0, -24.0), pos + Vector2(15.0, -33.0), Color(0.60, 0.38, 0.22, 0.70), 2.0)
	_draw_ash_pile(pos + Vector2(0.0, 19.0), 23.0)

func _draw_wall_segment(a: Vector2, b: Vector2) -> void:
	draw_line(a + Vector2(0.0, 10.0), b + Vector2(0.0, 10.0), Color(0.0, 0.0, 0.0, 0.30), 9.0)
	draw_line(a, b, Color(0.23, 0.17, 0.12, 0.88), 9.0)
	draw_line(a, b, Color(0.62, 0.34, 0.16, 0.52), 2.0)

func _draw_ash_pile(pos: Vector2, size: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(22):
		var a: float = TAU * float(i) / 22.0
		var r: float = size * (0.72 + 0.20 * sin(float(i) * 1.7))
		pts.append(pos + Vector2(cos(a) * r, sin(a) * r * 0.42))
	draw_colored_polygon(pts, Color(0.16, 0.13, 0.11, 0.74))

func _draw_grate(pos: Vector2, width: float, height: float) -> void:
	var rect: Rect2 = Rect2(pos - Vector2(width * 0.5, height * 0.5), Vector2(width, height))
	draw_rect(rect, Color(0.055, 0.045, 0.040, 0.95), true)
	draw_rect(rect, Color(0.58, 0.24, 0.11, 0.78), false, 2.0)
	for i: int in range(6):
		var x: float = rect.position.x + float(i + 1) * rect.size.x / 7.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), Color(0.70, 0.30, 0.12, 0.48), 1.0)

func _draw_channel(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a, b, Color(0.045, 0.035, 0.030, 0.92), width)
	draw_line(a, b, Color(0.76, 0.28, 0.09, 0.35), maxf(2.0, width * 0.25))

func _draw_hanging_chain(pos: Vector2, length: float) -> void:
	var links: int = int(length / 13.0)
	for i: int in range(links):
		var p: Vector2 = pos + Vector2(0.0, float(i) * 13.0)
		draw_arc(p, 5.0, 0.0, TAU, 12, Color(0.45, 0.35, 0.26, 0.75), 1.5)

func _draw_chain_on_floor(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, Color(0.10, 0.08, 0.07, 0.70), 5.0)
	var steps: int = 8
	for i: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		draw_arc(p, 5.0, 0.0, TAU, 10, Color(0.50, 0.38, 0.24, 0.80), 1.0)

func _draw_furnace(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-48.0, -62.0), Vector2(96.0, 70.0)), Color(0.12, 0.075, 0.052, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-48.0, -62.0), Vector2(96.0, 70.0)), Color(0.72, 0.31, 0.12, 0.72), false, 2.0)
	var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
	draw_rect(Rect2(pos + Vector2(-28.0, -38.0), Vector2(56.0, 26.0)), Color(1.0, 0.23, 0.05, 0.18 + 0.18 * pulse), true)

func _draw_reservoir(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-110.0, -44.0), Vector2(220.0, 72.0)), Color(0.055, 0.050, 0.048, 0.94), true)
	draw_rect(Rect2(pos + Vector2(-110.0, -44.0), Vector2(220.0, 72.0)), Color(0.42, 0.32, 0.23, 0.80), false, 2.0)
	draw_rect(Rect2(pos + Vector2(-92.0, -26.0), Vector2(184.0, 36.0)), Color(0.14, 0.10, 0.08, 0.72), true)

func _draw_sorting_belt(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-160.0, -24.0), Vector2(320.0, 48.0)), Color(0.075, 0.060, 0.050, 0.94), true)
	draw_rect(Rect2(pos + Vector2(-160.0, -24.0), Vector2(320.0, 48.0)), Color(0.52, 0.29, 0.16, 0.74), false, 2.0)
	for i: int in range(7):
		var x: float = pos.x - 130.0 + float(i) * 43.0
		draw_rect(Rect2(Vector2(x, pos.y - 18.0), Vector2(24.0, 36.0)), Color(0.13, 0.10, 0.08, 0.74), true)

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

func _draw_small_altar(pos: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos + Vector2(-42.0, -24.0), Vector2(84.0, 36.0)), Color(0.08, 0.065, 0.052, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-42.0, -24.0), Vector2(84.0, 36.0)), color, false, 2.0)
	draw_line(pos + Vector2(0.0, -58.0), pos + Vector2(0.0, -22.0), Color(0.95, 0.80, 0.50, 0.85), 2.0)
	draw_line(pos + Vector2(-17.0, -40.0), pos + Vector2(17.0, -40.0), Color(0.95, 0.80, 0.50, 0.85), 2.0)

func _draw_pool(pos: Vector2) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(32):
		var a: float = TAU * float(i) / 32.0
		pts.append(pos + Vector2(cos(a) * 82.0, sin(a) * 33.0))
	draw_colored_polygon(pts, Color(0.10, 0.22, 0.30, 0.82))
	draw_polyline(pts, Color(0.40, 0.72, 0.92, 0.78), 2.0)

func _draw_anvil(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-42.0, -25.0), Vector2(84.0, 20.0)), Color(0.16, 0.15, 0.14, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-20.0, -5.0), Vector2(40.0, 24.0)), Color(0.12, 0.11, 0.10, 0.96), true)
	draw_line(pos + Vector2(-45.0, -15.0), pos + Vector2(45.0, -15.0), Color(0.72, 0.62, 0.48, 0.70), 2.0)

func _draw_counter(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-105.0, -34.0), Vector2(210.0, 52.0)), Color(0.11, 0.08, 0.075, 0.96), true)
	draw_rect(Rect2(pos + Vector2(-105.0, -34.0), Vector2(210.0, 52.0)), Color(0.62, 0.40, 0.20, 0.72), false, 2.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-22.0, -4.0), "?", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 22, Color(0.95, 0.77, 0.40, 0.9))

func _draw_candle_cluster(pos: Vector2) -> void:
	for i: int in range(3):
		var x: float = -12.0 + float(i) * 12.0
		draw_rect(Rect2(pos + Vector2(x - 2.0, -16.0), Vector2(4.0, 18.0)), Color(0.74, 0.60, 0.42, 0.90), true)
		draw_circle(pos + Vector2(x, -18.0), 3.0, Color(1.0, 0.62, 0.22, 0.75))

func _draw_debug_label() -> void:
	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(Vector2(-150.0, 174.0), Vector2(300.0, 34.0)), Color(0.0, 0.0, 0.0, 0.58), true)
	draw_string(font, Vector2(-145.0, 196.0), "%s | %s | depth %d" % [room_type, variant, depth], HORIZONTAL_ALIGNMENT_CENTER, 290.0, 12, Color(0.95, 0.82, 0.58, 1.0))
