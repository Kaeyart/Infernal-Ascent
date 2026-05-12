extends Node2D

class_name AshBoltProjectile

@export var damage: int = 1
@export var speed: float = 185.0
@export var radius: float = 13.0
@export var lifetime: float = 2.6
@export var player_knockback_force: float = 170.0
@export var debug_draw_radius: bool = false
@export var draw_readability_trail: bool = true
@export var danger_ring_alpha: float = 0.78

var direction: Vector2 = Vector2.RIGHT
var _life_remaining: float = 0.0
var _has_hit: bool = false
var _pulse_time: float = 0.0

func setup(start_position: Vector2, shot_direction: Vector2, shot_speed: float, shot_damage: int, shot_lifetime: float, shot_radius: float, knockback_force: float) -> void:
	global_position = start_position
	direction = shot_direction.normalized() if shot_direction.length() > 0.01 else Vector2.RIGHT
	speed = shot_speed
	damage = shot_damage
	lifetime = shot_lifetime
	radius = shot_radius
	player_knockback_force = knockback_force
	_life_remaining = lifetime

func _ready() -> void:
	if _life_remaining <= 0.0:
		_life_remaining = lifetime
	queue_redraw()

func _process(delta: float) -> void:
	if _has_hit:
		return
	_life_remaining -= delta
	if _life_remaining <= 0.0:
		queue_free()
		return
	_pulse_time += delta
	global_position += direction * speed * delta
	_check_player_hit()
	queue_redraw()

func _check_player_hit() -> void:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if not (player_node is Node2D):
		return
	var player_2d: Node2D = player_node as Node2D
	if global_position.distance_to(player_2d.global_position) > radius + 10.0:
		return
	_has_hit = true
	if player_node.has_method("receive_enemy_attack"):
		player_node.call("receive_enemy_attack", damage, global_position, direction, player_knockback_force)
	elif player_node.has_method("take_damage"):
		player_node.call("take_damage", damage)
	queue_free()

func _draw() -> void:
	var dir: Vector2 = direction.normalized()
	var side: Vector2 = Vector2(-dir.y, dir.x)
	var pulse: float = 0.5 + 0.5 * sin(_pulse_time * 18.0)
	if draw_readability_trail:
		var tail: Vector2 = -dir * radius * 2.6
		var tail_pts: PackedVector2Array = PackedVector2Array([
			side * radius * 0.62,
			tail + side * radius * 0.22,
			tail - side * radius * 0.22,
			-side * radius * 0.62,
		])
		draw_colored_polygon(tail_pts, Color(1.0, 0.30, 0.08, 0.28))
	draw_circle(Vector2.ZERO, radius + 7.0 + pulse * 2.0, Color(1.0, 0.14, 0.04, 0.16))
	draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 24, Color(1.0, 0.78, 0.28, danger_ring_alpha), 3.0)
	draw_circle(Vector2.ZERO, radius, Color(0.95, 0.30, 0.13, 0.34))
	draw_circle(Vector2.ZERO, maxf(4.0, radius * 0.42), Color(1.0, 0.74, 0.30, 0.98))
	draw_line(-dir * radius * 1.20, dir * radius * 0.45, Color(0.15, 0.04, 0.02, 0.72), 2.5)
	if debug_draw_radius:
		draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 24, Color(0.3, 0.7, 1.0, 0.7), 1.0)
