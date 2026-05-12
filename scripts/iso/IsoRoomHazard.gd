extends Node2D

class_name IsoRoomHazard
## V16 combat readability hazard marker.
## All hazards now use the shared WARNING -> ACTIVE -> COOLDOWN language.
## This pass does not change room flow or add new hazards; it only makes existing danger readable.

signal hazard_fired(hazard_kind: String)

enum HazardState { WINDUP, ACTIVE, COOLDOWN }

@export_enum("ash_vent", "ember_grate", "falling_cinder") var hazard_kind: String = "ash_vent"
@export var radius: float = 56.0
@export var damage: int = 1
@export var windup_duration: float = 1.35
@export var active_duration: float = 0.42
@export var cooldown_duration: float = 2.8
@export var player_knockback_force: float = 155.0
@export var affects_player: bool = true
@export var affects_enemies: bool = true
@export var enabled: bool = true
@export var debug_draw_radius: bool = false
@export var draw_warning_label: bool = true
@export var draw_cooldown_marker: bool = true
@export var warning_ring_width: float = 5.0
@export var active_ring_width: float = 6.0
@export var show_state_text: bool = true

var _state: HazardState = HazardState.WINDUP
var _timer: float = 0.0
var _active_hits: Array[Node] = []

func setup(data: Dictionary, spawn_position: Vector2) -> void:
	global_position = spawn_position
	hazard_kind = str(data.get("hazard_kind", hazard_kind))
	radius = float(data.get("radius", radius))
	damage = int(data.get("damage", damage))
	windup_duration = float(data.get("windup_duration", windup_duration))
	active_duration = float(data.get("active_duration", active_duration))
	cooldown_duration = float(data.get("cooldown_duration", cooldown_duration))
	player_knockback_force = float(data.get("player_knockback_force", player_knockback_force))
	affects_player = bool(data.get("affects_player", affects_player))
	affects_enemies = bool(data.get("affects_enemies", affects_enemies))
	debug_draw_radius = bool(data.get("debug_draw_radius", debug_draw_radius))
	draw_warning_label = bool(data.get("draw_warning_label", draw_warning_label))
	_state = HazardState.WINDUP
	_timer = windup_duration + randf_range(0.0, 0.25)
	z_index = 35
	z_as_relative = false
	add_to_group("circle0_room_hazard")
	queue_redraw()

func _ready() -> void:
	z_index = 35
	z_as_relative = false
	add_to_group("circle0_room_hazard")
	if _timer <= 0.0:
		_timer = windup_duration + randf_range(0.0, 0.25)

func _process(delta: float) -> void:
	if not enabled:
		return
	_timer -= delta
	match _state:
		HazardState.WINDUP:
			if _timer <= 0.0:
				_start_active()
		HazardState.ACTIVE:
			_apply_active_damage()
			if _timer <= 0.0:
				_state = HazardState.COOLDOWN
				_timer = cooldown_duration
		HazardState.COOLDOWN:
			if _timer <= 0.0:
				_state = HazardState.WINDUP
				_timer = windup_duration
	queue_redraw()

func _start_active() -> void:
	_state = HazardState.ACTIVE
	_timer = active_duration
	_active_hits.clear()
	emit_signal("hazard_fired", hazard_kind)

func _apply_active_damage() -> void:
	if affects_player:
		var player_node: Node = get_tree().get_first_node_in_group("player")
		if player_node is Node2D:
			_try_damage_node(player_node as Node2D, true)
	if affects_enemies:
		var enemies: Array[Node] = get_tree().get_nodes_in_group("iso_test_enemy")
		for node: Node in enemies:
			if node is Node2D:
				_try_damage_node(node as Node2D, false)

func _try_damage_node(target: Node2D, is_player: bool) -> void:
	if target == null or not is_instance_valid(target):
		return
	if _active_hits.has(target):
		return
	if global_position.distance_to(target.global_position) > radius:
		return
	_active_hits.append(target)
	var direction: Vector2 = target.global_position - global_position
	if direction.length() <= 0.01:
		direction = Vector2.DOWN
	if is_player:
		if target.has_method("receive_enemy_attack"):
			target.call("receive_enemy_attack", damage, global_position, direction.normalized(), player_knockback_force)
		elif target.has_method("take_damage"):
			target.call("take_damage", damage)
	else:
		if target.has_method("take_damage"):
			target.call("take_damage", damage)

func _draw() -> void:
	_draw_ground_readability_plate()
	_draw_state_warning()
	match hazard_kind:
		"ember_grate":
			_draw_ember_grate()
		"falling_cinder":
			_draw_falling_cinder_marker()
		_:
			_draw_ash_vent()
	if debug_draw_radius:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.15, 0.05, 0.92), 2.0)

func _draw_ground_readability_plate() -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(48):
		var a: float = TAU * float(i) / 48.0
		pts.append(Vector2(cos(a) * radius * 1.16, sin(a) * radius * 0.50 + 7.0))
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.46))

func _draw_state_warning() -> void:
	var t: float = _state_progress()
	if _state == HazardState.WINDUP:
		var alpha: float = 0.36 + 0.48 * t
		_draw_iso_fill(radius * (0.82 + 0.18 * t), Color(1.0, 0.32, 0.06, 0.10 + 0.16 * t))
		_draw_iso_ring(radius * (0.76 + 0.24 * t), Color(1.0, 0.52, 0.10, alpha), warning_ring_width)
		_draw_iso_ring(radius * 0.52, Color(1.0, 0.70, 0.20, 0.25 + 0.40 * t), 2.0)
		_draw_countdown_ticks(t)
		if draw_warning_label and show_state_text:
			_draw_center_text("WARNING", 11, Vector2(0.0, -radius * 0.78), Color(1.0, 0.82, 0.34, 0.96))
	elif _state == HazardState.ACTIVE:
		_draw_iso_fill(radius, Color(1.0, 0.06, 0.02, 0.36))
		_draw_iso_ring(radius, Color(1.0, 0.90, 0.30, 0.98), active_ring_width)
		_draw_iso_ring(radius * 0.68, Color(1.0, 0.22, 0.06, 0.92), 3.0)
		if show_state_text:
			_draw_center_text("DANGER", 12, Vector2(0.0, -radius * 0.82), Color(1.0, 0.94, 0.54, 0.98))
	elif draw_cooldown_marker:
		_draw_iso_ring(radius * 0.62, Color(0.46, 0.20, 0.10, 0.34), 2.0)

func _draw_ash_vent() -> void:
	draw_circle(Vector2.ZERO, radius * 0.36, Color(0.12, 0.075, 0.045, 0.96))
	draw_arc(Vector2.ZERO, radius * 0.42, 0.0, TAU, 40, Color(0.86, 0.38, 0.12, 0.96), 3.0)
	for i: int in range(6):
		var a: float = TAU * float(i) / 6.0
		var inner: Vector2 = Vector2(cos(a), sin(a)) * radius * 0.12
		var outer: Vector2 = Vector2(cos(a), sin(a)) * radius * 0.34
		draw_line(inner, outer, Color(0.92, 0.50, 0.17, 0.76), 2.0)

func _draw_ember_grate() -> void:
	var rect: Rect2 = Rect2(Vector2(-radius, -radius * 0.38), Vector2(radius * 2.0, radius * 0.76))
	draw_rect(rect, Color(0.09, 0.055, 0.035, 0.96), true)
	draw_rect(rect, Color(0.92, 0.32, 0.08, 0.92), false, 3.0)
	for i: int in range(6):
		var x: float = -radius + float(i + 1) * (radius * 2.0 / 7.0)
		draw_line(Vector2(x, -radius * 0.35), Vector2(x, radius * 0.35), Color(1.0, 0.54, 0.16, 0.86), 2.0)
	if _state == HazardState.ACTIVE:
		for j: int in range(4):
			draw_line(Vector2(-radius + j * radius * 0.55, radius * 0.28), Vector2(-radius * 0.50 + j * radius * 0.55, -radius * 0.34), Color(1.0, 0.78, 0.28, 0.78), 2.0)

func _draw_falling_cinder_marker() -> void:
	_draw_iso_ring(radius, Color(1.0, 0.30, 0.08, 0.75 if _state == HazardState.WINDUP else 0.95), 3.0)
	draw_line(Vector2(-radius * 0.70, 0.0), Vector2(radius * 0.70, 0.0), Color(1.0, 0.64, 0.24, 0.80), 2.5)
	draw_line(Vector2(0.0, -radius * 0.70), Vector2(0.0, radius * 0.70), Color(1.0, 0.64, 0.24, 0.80), 2.5)
	if _state == HazardState.ACTIVE:
		draw_circle(Vector2.ZERO, radius * 0.44, Color(1.0, 0.80, 0.24, 0.82))
		draw_circle(Vector2.ZERO, radius * 0.22, Color(1.0, 0.20, 0.04, 0.90))

func _draw_countdown_ticks(progress: float) -> void:
	var total: int = 12
	var lit: int = int(ceil(float(total) * clampf(progress, 0.0, 1.0)))
	for i: int in range(total):
		var a: float = TAU * float(i) / float(total)
		var p1: Vector2 = Vector2(cos(a), sin(a)) * radius * 0.82
		var p2: Vector2 = Vector2(cos(a), sin(a)) * radius * 1.02
		var col: Color = Color(1.0, 0.68, 0.20, 0.82) if i < lit else Color(0.38, 0.18, 0.10, 0.42)
		draw_line(p1, p2, col, 2.0)

func _draw_iso_fill(fill_radius: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(64):
		var a: float = TAU * float(i) / 64.0
		pts.append(Vector2(cos(a) * fill_radius, sin(a) * fill_radius * 0.47))
	draw_colored_polygon(pts, color)

func _draw_iso_ring(ring_radius: float, color: Color, width: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(64):
		var a: float = TAU * float(i) / 64.0
		pts.append(Vector2(cos(a) * ring_radius, sin(a) * ring_radius * 0.47))
	for i: int in range(pts.size()):
		draw_line(pts[i], pts[(i + 1) % pts.size()], color, width)

func _draw_center_text(text: String, font_size: int, pos: Vector2, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos + Vector2(-80.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, font_size, color)

func _state_progress() -> float:
	match _state:
		HazardState.WINDUP:
			return clampf(1.0 - (_timer / maxf(windup_duration, 0.01)), 0.0, 1.0)
		HazardState.ACTIVE:
			return clampf(1.0 - (_timer / maxf(active_duration, 0.01)), 0.0, 1.0)
		HazardState.COOLDOWN:
			return clampf(1.0 - (_timer / maxf(cooldown_duration, 0.01)), 0.0, 1.0)
	return 0.0
