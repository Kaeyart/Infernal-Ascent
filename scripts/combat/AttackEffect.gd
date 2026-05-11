extends Node2D

var kind := "light"
var radius := 60.0
var direction := Vector2.RIGHT
var lifetime := 0.18
var max_lifetime := 0.18
var spin_offset := 0.0
var drift := Vector2.ZERO


func setup(new_kind: String, new_radius: float, new_direction: Vector2) -> void:
	kind = new_kind
	radius = maxf(8.0, new_radius)

	if new_direction.length() > 0.01:
		direction = new_direction.normalized()
	else:
		direction = Vector2.RIGHT

	spin_offset = randf_range(-0.08, 0.08)
	drift = direction * 16.0

	match kind:
		"light", "light_1":
			lifetime = 0.16
		"light_2":
			lifetime = 0.16
		"light_3":
			lifetime = 0.20
		"heavy":
			lifetime = 0.25
		"q":
			lifetime = 0.30
		"ultimate":
			lifetime = 0.46
		"perfect":
			lifetime = 0.24
		"death":
			lifetime = 0.30
		_:
			lifetime = 0.18

	max_lifetime = lifetime
	z_index = 95
	queue_redraw()


func _process(delta: float) -> void:
	lifetime -= delta

	if kind in ["q", "dash"]:
		global_position += drift * delta

	if lifetime <= 0.0:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var remaining := clampf(lifetime / max_lifetime, 0.0, 1.0)
	var progress := 1.0 - remaining
	var alpha := remaining

	match kind:
		"light", "light_1":
			_draw_weapon_slash(progress, alpha, 0.55, Color(1.0, 0.78, 0.30, alpha), 1.0, 1.0)
		"light_2":
			_draw_weapon_slash(progress, alpha, 0.58, Color(1.0, 0.84, 0.36, alpha), -1.0, 1.08)
		"light_3":
			_draw_weapon_slash(progress, alpha, 0.92, Color(1.0, 0.92, 0.48, alpha), 1.0, 1.20)
		"heavy":
			_draw_heavy_slash(progress, alpha)
		"q":
			_draw_q_burst(progress, alpha)
		"ultimate":
			_draw_ultimate(progress, alpha)
		"perfect":
			_draw_perfect(progress, alpha)
		"death":
			_draw_death_burst(progress, alpha)
		_:
			_draw_weapon_slash(progress, alpha, 0.58, Color(1.0, 0.78, 0.30, alpha), 1.0, 1.0)


func _draw_weapon_slash(progress: float, alpha: float, arc_width: float, color: Color, side: float, force: float) -> void:
	var angle := direction.angle() + spin_offset
	var sweep_center := angle + lerpf(-0.20 * side, 0.18 * side, progress)
	var start_angle := sweep_center - arc_width
	var end_angle := sweep_center + arc_width
	var outer_radius := radius * force
	var inner_radius := radius * 0.48

	_draw_wedge_fill(inner_radius, outer_radius, start_angle, end_angle, Color(color.r, color.g, color.b, 0.12 * alpha))
	draw_arc(Vector2.ZERO, outer_radius, start_angle, end_angle, 42, Color(color.r, color.g, color.b, 0.96 * alpha), 8.0)
	draw_arc(Vector2.ZERO, outer_radius * 0.78, start_angle, end_angle, 36, Color(1.0, 0.96, 0.70, 0.46 * alpha), 3.0)
	draw_arc(Vector2.ZERO, outer_radius * 0.54, start_angle, end_angle, 30, Color(color.r, color.g, color.b, 0.34 * alpha), 2.0)

	var tip := Vector2.RIGHT.rotated(sweep_center) * outer_radius
	var base := Vector2.RIGHT.rotated(sweep_center) * 10.0
	draw_line(base, tip, Color(1.0, 0.93, 0.62, 0.40 * alpha), 3.0)

	if kind in ["light_3", "heavy"]:
		_draw_sparks(sweep_center, outer_radius, color, alpha, 5)
	else:
		_draw_sparks(sweep_center, outer_radius, color, alpha, 3)


func _draw_heavy_slash(progress: float, alpha: float) -> void:
	var color := Color(1.0, 0.34, 0.18, alpha)
	_draw_weapon_slash(progress, alpha, 1.10, color, 1.0, 1.18)

	var angle := direction.angle()
	var shock_radius := radius * lerpf(0.55, 1.05, progress)
	draw_arc(Vector2.ZERO, shock_radius, angle - 1.18, angle + 1.18, 56, Color(1.0, 0.18, 0.10, 0.26 * alpha), 4.0)
	draw_line(-direction * radius * 0.18, direction * radius * 1.04, Color(1.0, 0.70, 0.34, 0.28 * alpha), 6.0)


func _draw_q_burst(progress: float, alpha: float) -> void:
	var color := Color(0.55, 0.90, 1.0, alpha)
	var angle := direction.angle()
	var length := radius * 1.08
	var width := radius * 0.30 * (1.0 - progress * 0.35)

	var p0 := -direction * radius * 0.38
	var p1 := direction * length
	var side := Vector2(-direction.y, direction.x)
	var slash_poly := PackedVector2Array([
		p0 + side * width,
		p1 + side * width * 0.28,
		p1 - side * width * 0.28,
		p0 - side * width
	])

	draw_colored_polygon(slash_poly, Color(0.25, 0.75, 1.0, 0.16 * alpha))
	draw_line(p0, p1, color, 7.0)
	draw_line(p0 - side * width * 0.65, p1 - side * width * 0.18, Color(0.90, 0.98, 1.0, 0.38 * alpha), 3.0)
	draw_arc(Vector2.ZERO, radius * lerpf(0.45, 1.0, progress), angle - 0.80, angle + 0.80, 42, Color(0.62, 0.92, 1.0, 0.62 * alpha), 4.0)
	_draw_sparks(angle, radius, color, alpha, 6)


func _draw_ultimate(progress: float, alpha: float) -> void:
	var gold := Color(1.0, 0.78, 0.26, alpha)
	var hot := Color(1.0, 0.36, 0.12, alpha)
	var pulse_radius := radius * lerpf(0.42, 1.0, progress)

	draw_circle(Vector2.ZERO, pulse_radius, Color(1.0, 0.48, 0.10, 0.10 * alpha))
	draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 96, gold, 8.0)
	draw_arc(Vector2.ZERO, pulse_radius * 0.68, 0.0, TAU, 96, Color(1.0, 0.95, 0.58, 0.72 * alpha), 3.0)
	draw_arc(Vector2.ZERO, pulse_radius * 0.38, 0.0, TAU, 72, hot, 3.0)

	for i in range(10):
		var a := TAU * float(i) / 10.0 + progress * 1.6
		var p1 := Vector2.RIGHT.rotated(a) * pulse_radius * 0.24
		var p2 := Vector2.RIGHT.rotated(a) * pulse_radius
		draw_line(p1, p2, Color(1.0, 0.66, 0.20, 0.58 * alpha), 3.0)


func _draw_perfect(progress: float, alpha: float) -> void:
	var ring_radius := radius * lerpf(0.60, 1.16, progress)
	draw_circle(Vector2.ZERO, ring_radius, Color(0.85, 0.95, 1.0, 0.10 * alpha))
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 72, Color(0.90, 0.98, 1.0, alpha), 5.0)
	draw_arc(Vector2.ZERO, ring_radius * 0.56, 0.0, TAU, 72, Color(0.45, 0.82, 1.0, 0.70 * alpha), 2.0)

	for i in range(6):
		var a := TAU * float(i) / 6.0
		draw_line(Vector2.RIGHT.rotated(a) * ring_radius * 0.42, Vector2.RIGHT.rotated(a) * ring_radius, Color(0.85, 0.96, 1.0, 0.52 * alpha), 2.0)


func _draw_death_burst(progress: float, alpha: float) -> void:
	var burst_radius := radius * lerpf(0.35, 1.08, progress)
	draw_circle(Vector2.ZERO, burst_radius, Color(0.86, 0.12, 0.08, 0.12 * alpha))
	draw_arc(Vector2.ZERO, burst_radius, 0.0, TAU, 52, Color(0.86, 0.22, 0.14, alpha), 4.0)

	for i in range(7):
		var a := TAU * float(i) / 7.0 + progress * 0.6
		var p1 := Vector2.RIGHT.rotated(a) * 8.0
		var p2 := Vector2.RIGHT.rotated(a) * burst_radius
		draw_line(p1, p2, Color(1.0, 0.62, 0.32, 0.78 * alpha), 3.0)


func _draw_wedge_fill(inner_radius: float, outer_radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 26

	for i in range(steps + 1):
		var ratio := float(i) / float(steps)
		var angle := lerpf(start_angle, end_angle, ratio)
		points.append(Vector2.RIGHT.rotated(angle) * outer_radius)

	for i in range(steps, -1, -1):
		var ratio := float(i) / float(steps)
		var angle := lerpf(start_angle, end_angle, ratio)
		points.append(Vector2.RIGHT.rotated(angle) * inner_radius)

	draw_colored_polygon(points, color)


func _draw_sparks(angle: float, spark_radius: float, color: Color, alpha: float, count: int) -> void:
	for i in range(count):
		var spread := randf_range(-0.42, 0.42)
		var spark_angle := angle + spread
		var length := randf_range(8.0, 18.0)
		var start := Vector2.RIGHT.rotated(spark_angle) * spark_radius * randf_range(0.70, 1.02)
		var end := start + Vector2.RIGHT.rotated(spark_angle) * length
		draw_line(start, end, Color(color.r, color.g, color.b, 0.42 * alpha), 2.0)
