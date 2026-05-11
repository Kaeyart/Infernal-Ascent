extends Node2D

var text: String = "0"
var color: Color = Color.WHITE

var velocity: Vector2 = Vector2(0, -48)
var lifetime: float = 0.65
var max_lifetime: float = 0.65

var scale_start: float = 1.0
var scale_end: float = 0.75
var wobble_seed: float = 0.0
var big_hit: bool = false


func setup(amount: float, new_color: Color = Color.WHITE, is_big: bool = false) -> void:
	var rounded_amount: int = int(ceil(amount))

	if rounded_amount >= 900:
		text = "EXECUTE"
	else:
		text = str(rounded_amount)

	color = new_color
	big_hit = is_big
	wobble_seed = randf_range(0.0, TAU)

	if is_big:
		scale_start = 1.45
		scale_end = 0.90
		velocity = Vector2(randf_range(-18.0, 18.0), -78.0)
		lifetime = 0.82
	else:
		scale_start = 1.08
		scale_end = 0.72
		velocity = Vector2(randf_range(-13.0, 13.0), -54.0)
		lifetime = 0.66

	max_lifetime = lifetime
	queue_redraw()


func _process(delta: float) -> void:
	lifetime -= delta
	velocity.y += 18.0 * delta
	position += velocity * delta

	if lifetime <= 0.0:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var remaining_ratio := clampf(lifetime / max_lifetime, 0.0, 1.0)
	var progress := 1.0 - remaining_ratio
	var alpha := smoothstep(0.0, 0.18, remaining_ratio)
	var pop := sin(clampf(progress * 2.5, 0.0, 1.0) * PI)
	var s := lerpf(scale_start, scale_end, progress) + pop * 0.16

	var draw_color := Color(color.r, color.g, color.b, alpha)
	var outline_color := Color(0.0, 0.0, 0.0, 0.82 * alpha)
	var glow_color := Color(color.r, color.g, color.b, 0.18 * alpha)

	var font := ThemeDB.fallback_font
	var font_size := int(22 * s)
	var width := 112.0
	var base_pos := Vector2(-width * 0.5, 8.0)
	var wobble := Vector2(sin(wobble_seed + progress * 9.0) * 2.0 * remaining_ratio, 0.0)

	if big_hit:
		draw_circle(Vector2(0, -7) + wobble, 16.0 * s, glow_color)
		draw_arc(Vector2(0, -7) + wobble, 18.0 * s, -0.2, TAU - 0.2, 28, Color(color.r, color.g, color.b, 0.32 * alpha), 2.0)

	_draw_centered_text(font, base_pos + wobble + Vector2(2, 2), width, font_size, outline_color)
	_draw_centered_text(font, base_pos + wobble + Vector2(-2, 1), width, font_size, outline_color)
	_draw_centered_text(font, base_pos + wobble + Vector2(1, -2), width, font_size, outline_color)
	_draw_centered_text(font, base_pos + wobble + Vector2(0, 0), width, font_size, draw_color)


func _draw_centered_text(font: Font, pos: Vector2, width: float, font_size: int, draw_color: Color) -> void:
	draw_string(
		font,
		pos,
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		width,
		font_size,
		draw_color
	)
