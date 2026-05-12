extends Node2D
class_name IsoHubNPC

@export var npc_id: String = "npc"
@export var display_name: String = "Hub NPC"
@export var role_text: String = "Placeholder NPC"
@export var accent_color: Color = Color("#c59254")
@export var silhouette_color: Color = Color("#181316")
@export var show_nameplate: bool = true

func setup(p_npc_id: String, p_display_name: String, p_role_text: String, p_accent_color: Color) -> void:
	npc_id = p_npc_id
	display_name = p_display_name
	role_text = p_role_text
	accent_color = p_accent_color
	queue_redraw()

func _draw() -> void:
	_draw_shadow()
	_draw_body()
	if show_nameplate:
		_draw_nameplate()

func _draw_shadow() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = Vector2(0.0, 17.0)
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * 22.0, sin(angle) * 7.0))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.32))

func _draw_body() -> void:
	# Cloaked isometric placeholder. Distinct enough to read as a person,
	# cheap enough to replace later with real NPC art.
	var robe: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -42.0),
		Vector2(18.0, -18.0),
		Vector2(15.0, 16.0),
		Vector2(0.0, 25.0),
		Vector2(-15.0, 16.0),
		Vector2(-18.0, -18.0),
	])
	draw_colored_polygon(robe, silhouette_color)
	draw_polyline(PackedVector2Array([robe[0], robe[1], robe[2], robe[3], robe[4], robe[5], robe[0]]), accent_color, 2.0)

	# Hood / head
	draw_circle(Vector2(0.0, -42.0), 10.0, Color("#0d0b0d"))
	draw_arc(Vector2(0.0, -42.0), 12.0, 0.0, TAU, 28, accent_color, 1.5)

	# Face slit / eye glow
	draw_rect(Rect2(Vector2(-6.0, -44.0), Vector2(12.0, 3.0)), Color(0.0, 0.0, 0.0, 0.75), true)
	draw_circle(Vector2(-3.0, -42.5), 1.2, accent_color)
	draw_circle(Vector2(4.0, -42.5), 1.2, accent_color)

	# Role object variations
	if npc_id == "weapon_keeper":
		draw_line(Vector2(16.0, -26.0), Vector2(27.0, 8.0), Color("#d9d2c0"), 3.0)
		draw_line(Vector2(13.0, -20.0), Vector2(21.0, -23.0), accent_color, 2.0)
	elif npc_id == "shrine_attendant":
		draw_circle(Vector2(0.0, -10.0), 8.0, Color(accent_color.r, accent_color.g, accent_color.b, 0.22))
		draw_arc(Vector2(0.0, -10.0), 10.0, 0.0, TAU, 24, accent_color, 2.0)
	elif npc_id == "archivist":
		draw_rect(Rect2(Vector2(-18.0, -18.0), Vector2(13.0, 16.0)), Color("#7f6745"), true)
		draw_line(Vector2(-17.0, -12.0), Vector2(-6.0, -12.0), Color("#d6c5aa"), 1.0)
		draw_line(Vector2(-17.0, -7.0), Vector2(-6.0, -7.0), Color("#d6c5aa"), 1.0)
	elif npc_id == "toll_clerk":
		draw_circle(Vector2(15.0, -11.0), 6.0, Color("#8d6c32"))
		draw_line(Vector2(9.0, -11.0), Vector2(21.0, -11.0), Color("#d8b866"), 1.0)

	# Small base marker
	draw_arc(Vector2(0.0, 18.0), 20.0, 0.0, TAU, 36, Color(accent_color.r, accent_color.g, accent_color.b, 0.42), 1.0)

func _draw_nameplate() -> void:
	var font: Font = ThemeDB.fallback_font
	var plate: Rect2 = Rect2(Vector2(-68.0, 32.0), Vector2(136.0, 34.0))
	draw_rect(plate, Color(0.02, 0.016, 0.014, 0.72), true)
	draw_rect(plate, accent_color, false, 1.0)
	draw_string(font, Vector2(-62.0, 47.0), display_name, HORIZONTAL_ALIGNMENT_CENTER, 124.0, 12, Color("#f2e4c8"))
	draw_string(font, Vector2(-62.0, 61.0), role_text, HORIZONTAL_ALIGNMENT_CENTER, 124.0, 10, Color("#bca98d"))
