@tool
extends Node2D
class_name IsoMarker

@export var marker_label: String = "Marker":
	set(value):
		marker_label = value
		queue_redraw()
@export var marker_color: Color = Color(0.95, 0.65, 0.22, 0.95):
	set(value):
		marker_color = value
		queue_redraw()
@export var radius: float = 12.0:
	set(value):
		radius = max(4.0, value)
		queue_redraw()
@export var show_label: bool = true:
	set(value):
		show_label = value
		queue_redraw()

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(marker_color.r, marker_color.g, marker_color.b, 0.18))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, marker_color, 2.0)
	draw_line(Vector2(-radius, 0), Vector2(radius, 0), marker_color, 1.2)
	draw_line(Vector2(0, -radius), Vector2(0, radius), marker_color, 1.2)

	if show_label:
		draw_string(ThemeDB.fallback_font, Vector2(radius + 4.0, 4.0), marker_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, marker_color)
