extends Node2D

class_name AshBoltProjectile

@export var damage: int = 1
@export var speed: float = 185.0
@export var radius: float = 13.0
@export var lifetime: float = 2.6
@export var player_knockback_force: float = 170.0
@export var debug_draw_radius: bool = false

var direction: Vector2 = Vector2.RIGHT
var _life_remaining: float = 0.0
var _has_hit: bool = false

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
	draw_circle(Vector2.ZERO, radius, Color(0.95, 0.30, 0.13, 0.18))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(1.0, 0.56, 0.20, 0.85), 2.0)
	draw_circle(Vector2.ZERO, maxf(3.0, radius * 0.36), Color(1.0, 0.72, 0.32, 0.95))
	draw_line(-direction.normalized() * radius * 0.9, direction.normalized() * radius * 0.35, Color(0.15, 0.04, 0.02, 0.65), 2.0)
	if debug_draw_radius:
		draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 24, Color(0.3, 0.7, 1.0, 0.7), 1.0)
