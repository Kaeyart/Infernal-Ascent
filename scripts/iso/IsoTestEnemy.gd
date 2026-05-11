extends Node2D
class_name IsoTestEnemy

signal died(enemy: IsoTestEnemy)

@export var max_health: int = 3
@export var move_enabled: bool = false
@export var move_speed: float = 55.0
@export var aggro_radius: float = 360.0

var health: int = 3
var is_dead: bool = false
var _hit_flash_remaining: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("iso_test_enemy")
	queue_redraw()

func _process(delta: float) -> void:
	if is_dead:
		return

	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = maxf(0.0, _hit_flash_remaining - delta)

	if move_enabled:
		_update_simple_chase(delta)

	queue_redraw()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	_hit_flash_remaining = 0.12

	if health <= 0:
		_die()
	else:
		queue_redraw()

func _die() -> void:
	if is_dead:
		return

	is_dead = true
	emit_signal("died", self)
	queue_free()

func _update_simple_chase(delta: float) -> void:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if not (player_node is Node2D):
		return

	var player_2d: Node2D = player_node as Node2D
	var to_player: Vector2 = player_2d.global_position - global_position
	if to_player.length() <= aggro_radius and to_player.length() > 4.0:
		global_position += to_player.normalized() * move_speed * delta

func _draw() -> void:
	_draw_filled_ellipse(Rect2(Vector2(-20.0, 12.0), Vector2(40.0, 13.0)), Color(0.0, 0.0, 0.0, 0.34))

	var body_color: Color = Color("#34201e")
	var outline_color: Color = Color("#c76b3a")
	if _hit_flash_remaining > 0.0:
		body_color = Color("#f2d0a0")
		outline_color = Color("#ffffff")

	var body: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -32.0),
		Vector2(18.0, -8.0),
		Vector2(12.0, 18.0),
		Vector2(-12.0, 18.0),
		Vector2(-18.0, -8.0),
	])

	draw_colored_polygon(body, body_color)
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[0]]), outline_color, 2.0)
	draw_circle(Vector2(0.0, -35.0), 7.0, Color("#120c0b"))
	draw_circle(Vector2(-4.0, -36.0), 1.5, Color("#f08a32"))
	draw_circle(Vector2(4.0, -36.0), 1.5, Color("#f08a32"))

	var hp_width: float = 42.0
	var health_ratio: float = clampf(float(health) / float(max_health), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-21.0, -52.0), Vector2(hp_width, 5.0)), Color(0.0, 0.0, 0.0, 0.65), true)
	draw_rect(Rect2(Vector2(-20.0, -51.0), Vector2((hp_width - 2.0) * health_ratio, 3.0)), Color("#c95438"), true)

func _draw_filled_ellipse(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(24):
		var angle: float = TAU * float(i) / 24.0
		points.append(rect.position + rect.size * 0.5 + Vector2(cos(angle) * rect.size.x * 0.5, sin(angle) * rect.size.y * 0.5))
	draw_colored_polygon(points, color)
