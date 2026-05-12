extends Node2D

## V24 — Ash Warden Boss V1.
## Self-contained boss runtime for the demo slice. It avoids static type dependencies so it
## can be loaded safely by IsoRoomLocalLoopController after the V23 parser hotfixes.

signal defeated()
signal health_changed(current_health: int, max_health: int)
signal phase_changed(phase: int)

enum BossState { INTRO, IDLE, WINDUP, ACTIVE, RECOVERY, STAGGERED, DEAD }

@export var max_health: int = 100
@export var contact_radius: float = 52.0
@export var idle_step_speed: float = 22.0
@export var boss_collision_clamp_radius: float = 310.0

@export_category("Phase Thresholds")
@export var phase_two_ratio: float = 0.66
@export var phase_three_ratio: float = 0.33

@export_category("Attacks")
@export var sweep_damage: int = 1
@export var sweep_radius: float = 126.0
@export var sweep_arc_degrees: float = 116.0
@export var chain_slam_damage: int = 1
@export var chain_slam_length: float = 260.0
@export var chain_slam_width: float = 44.0
@export var lunge_damage: int = 1
@export var lunge_speed: float = 335.0
@export var lunge_length: float = 240.0
@export var lunge_width: float = 48.0
@export var cinder_damage: int = 1
@export var cinder_radius: float = 48.0
@export var final_verdict_damage: int = 2

@export_category("Timing")
@export var intro_duration: float = 1.05
@export var idle_duration_min: float = 0.72
@export var idle_duration_max: float = 1.05
@export var sweep_windup: float = 0.72
@export var sweep_active: float = 0.26
@export var sweep_recovery: float = 0.62
@export var chain_windup: float = 0.86
@export var chain_active: float = 0.34
@export var chain_recovery: float = 0.74
@export var lunge_windup: float = 0.76
@export var lunge_active: float = 0.38
@export var lunge_recovery: float = 0.82
@export var cinder_windup: float = 0.88
@export var cinder_active: float = 0.26
@export var cinder_recovery: float = 0.66
@export var verdict_windup: float = 1.05
@export var verdict_active: float = 0.78
@export var verdict_recovery: float = 1.00
@export var stagger_duration: float = 2.10

@export_category("Furnace Seal Stagger")
@export var seal_mechanic_enabled: bool = true
@export var seal_radius: float = 46.0
@export var seal_cycle_duration: float = 5.8
@export var seal_stagger_damage: int = 8
@export var stagger_damage_multiplier: float = 1.40

@export_category("Summons")
@export var summons_enabled: bool = true
@export var max_summons_per_fight: int = 4
@export var summon_count_per_cast: int = 2

@export_category("Readability")
@export var show_boss_nameplate: bool = true
@export var show_attack_labels: bool = true
@export var show_seal_labels: bool = true
@export var draw_debug_arena_bounds: bool = false

var current_health: int = 0
var current_phase: int = 1
var is_dead: bool = false

var _state: int = BossState.INTRO
var _state_timer: float = 0.0
var _current_attack: String = ""
var _attack_direction: Vector2 = Vector2.DOWN
var _attack_hit_player: bool = false
var _attack_index: int = 0
var _arena_origin: Vector2 = Vector2.ZERO
var _setup_done: bool = false
var _hit_flash_remaining: float = 0.0
var _damage_numbers: Array[Dictionary] = []

var _seal_offsets: Array[Vector2] = [Vector2(-150.0, 34.0), Vector2(150.0, 34.0), Vector2(0.0, -132.0)]
var _armed_seal_index: int = 0
var _seal_timer: float = 0.0
var _seal_has_staggered_this_arm: bool = false

var _cinder_targets: Array[Vector2] = []
var _summons_created: int = 0

func setup_boss(spawn_position: Vector2, health_value: int = 100, arena_origin_value: Vector2 = Vector2.ZERO) -> void:
	global_position = spawn_position
	_arena_origin = arena_origin_value if arena_origin_value != Vector2.ZERO else spawn_position + Vector2(0.0, 96.0)
	max_health = maxi(1, health_value)
	current_health = max_health
	current_phase = 1
	_setup_done = true
	_initialize_runtime()

func _ready() -> void:
	if not _setup_done:
		_arena_origin = global_position + Vector2(0.0, 96.0)
		current_health = maxi(1, max_health)
	_initialize_runtime()

func _initialize_runtime() -> void:
	add_to_group("attack_target")
	add_to_group("ash_warden_boss")
	add_to_group("boss_runtime")
	_state = BossState.INTRO
	_state_timer = intro_duration
	_current_attack = ""
	_attack_hit_player = false
	_seal_timer = seal_cycle_duration
	_armed_seal_index = 0
	_seal_has_staggered_this_arm = false
	emit_signal("health_changed", current_health, max_health)
	emit_signal("phase_changed", current_phase)
	queue_redraw()

func _process(delta: float) -> void:
	_update_damage_numbers(delta)
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = maxf(0.0, _hit_flash_remaining - delta)
	if is_dead:
		queue_redraw()
		return
	_update_phase_from_health()
	_update_furnace_seals(delta)
	_state_timer -= delta
	match _state:
		BossState.INTRO:
			if _state_timer <= 0.0:
				_enter_idle()
		BossState.IDLE:
			_update_idle_motion(delta)
			if _state_timer <= 0.0:
				_start_next_attack()
		BossState.WINDUP:
			if _state_timer <= 0.0:
				_enter_active_attack()
		BossState.ACTIVE:
			_update_active_attack(delta)
			_check_furnace_seal_stagger()
			if _state_timer <= 0.0:
				_enter_recovery()
		BossState.RECOVERY:
			if _state_timer <= 0.0:
				_enter_idle()
		BossState.STAGGERED:
			if _state_timer <= 0.0:
				_enter_idle()
	queue_redraw()

func receive_player_hit(amount: int = 1, source_global_position: Vector2 = Vector2.ZERO, hit_direction: Vector2 = Vector2.ZERO, attack_kind: String = "attack") -> bool:
	return take_damage(amount, source_global_position, hit_direction, attack_kind)

func take_damage(amount: int = 1, source_global_position: Vector2 = Vector2.ZERO, hit_direction: Vector2 = Vector2.ZERO, attack_kind: String = "attack") -> bool:
	if is_dead:
		return false
	var final_amount: int = maxi(1, amount)
	if _state == BossState.STAGGERED:
		final_amount = maxi(1, int(ceil(float(final_amount) * stagger_damage_multiplier)))
	current_health = max(0, current_health - final_amount)
	_hit_flash_remaining = 0.16
	_spawn_damage_number(final_amount)
	emit_signal("health_changed", current_health, max_health)
	_update_phase_from_health()
	if current_health <= 0:
		_die()
		return true
	queue_redraw()
	return true

func _die() -> void:
	is_dead = true
	_state = BossState.DEAD
	_current_attack = ""
	remove_from_group("attack_target")
	emit_signal("health_changed", 0, max_health)
	emit_signal("defeated")
	queue_redraw()

func _update_phase_from_health() -> void:
	if max_health <= 0:
		return
	var ratio: float = float(current_health) / float(max_health)
	var new_phase: int = 1
	if ratio <= phase_three_ratio:
		new_phase = 3
	elif ratio <= phase_two_ratio:
		new_phase = 2
	if new_phase != current_phase:
		current_phase = new_phase
		emit_signal("phase_changed", current_phase)

func _enter_idle() -> void:
	_state = BossState.IDLE
	_current_attack = ""
	_attack_hit_player = false
	_state_timer = randf_range(idle_duration_min, idle_duration_max)
	_face_player()

func _start_next_attack() -> void:
	_attack_index += 1
	var sequence: Array[String] = []
	if current_phase == 1:
		sequence = ["sweep", "chain_slam", "sweep"]
	elif current_phase == 2:
		sequence = ["lunge", "sweep", "falling_cinder", "chain_slam", "summon"]
	else:
		sequence = ["final_verdict", "lunge", "chain_slam", "falling_cinder"]
	var next_attack: String = sequence[_attack_index % sequence.size()]
	if next_attack == "summon" and (not summons_enabled or _summons_created >= max_summons_per_fight):
		next_attack = "chain_slam"
	_start_attack(next_attack)

func _start_attack(kind: String) -> void:
	_current_attack = kind
	_attack_hit_player = false
	_face_player()
	_state = BossState.WINDUP
	match kind:
		"sweep":
			_state_timer = sweep_windup
		"chain_slam":
			_state_timer = chain_windup
		"lunge":
			_state_timer = lunge_windup
		"falling_cinder":
			_prepare_cinder_targets()
			_state_timer = cinder_windup
		"summon":
			_state_timer = 0.68
		"final_verdict":
			_prepare_cinder_targets(true)
			_state_timer = verdict_windup
		_:
			_state_timer = sweep_windup

func _enter_active_attack() -> void:
	_state = BossState.ACTIVE
	match _current_attack:
		"sweep":
			_state_timer = sweep_active
		"chain_slam":
			_state_timer = chain_active
		"lunge":
			_state_timer = lunge_active
		"falling_cinder":
			_state_timer = cinder_active
		"summon":
			_spawn_summons()
			_state_timer = 0.08
		"final_verdict":
			_state_timer = verdict_active
		_:
			_state_timer = sweep_active

func _enter_recovery() -> void:
	_state = BossState.RECOVERY
	_attack_hit_player = false
	match _current_attack:
		"sweep":
			_state_timer = sweep_recovery
		"chain_slam":
			_state_timer = chain_recovery
		"lunge":
			_state_timer = lunge_recovery
		"falling_cinder":
			_state_timer = cinder_recovery
		"final_verdict":
			_state_timer = verdict_recovery
		_:
			_state_timer = 0.55

func _enter_staggered() -> void:
	_state = BossState.STAGGERED
	_current_attack = "staggered"
	_attack_hit_player = false
	_state_timer = stagger_duration
	current_health = max(0, current_health - seal_stagger_damage)
	_spawn_damage_number(seal_stagger_damage, Color(0.65, 0.90, 1.0, 1.0))
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0:
		_die()

func _update_idle_motion(delta: float) -> void:
	var player: Node2D = _find_player()
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 170.0:
		global_position += to_player.normalized() * idle_step_speed * delta
		_clamp_to_arena()
	_face_player()

func _face_player() -> void:
	var player: Node2D = _find_player()
	if player == null:
		return
	var dir: Vector2 = player.global_position - global_position
	if dir.length() > 0.01:
		_attack_direction = dir.normalized()

func _update_active_attack(delta: float) -> void:
	if _current_attack == "lunge":
		global_position += _attack_direction.normalized() * lunge_speed * delta
		_clamp_to_arena()
	_apply_active_damage()

func _apply_active_damage() -> void:
	var player: Node2D = _find_player()
	if player == null:
		return
	match _current_attack:
		"sweep":
			if _is_player_in_arc(player, sweep_radius, sweep_arc_degrees):
				_hit_player_once(player, sweep_damage, 210.0)
		"chain_slam":
			if _is_point_in_attack_lane(player.global_position, global_position, global_position + _attack_direction * chain_slam_length, chain_slam_width):
				_hit_player_once(player, chain_slam_damage, 260.0)
		"lunge":
			if _is_point_in_attack_lane(player.global_position, global_position - _attack_direction * 32.0, global_position + _attack_direction * lunge_length * 0.55, lunge_width):
				_hit_player_once(player, lunge_damage, 290.0)
		"falling_cinder":
			for target: Vector2 in _cinder_targets:
				if player.global_position.distance_to(target) <= cinder_radius:
					_hit_player_once(player, cinder_damage, 205.0)
		"final_verdict":
			var in_chain_a: bool = _is_point_in_attack_lane(player.global_position, _arena_origin + Vector2(-260.0, -30.0), _arena_origin + Vector2(260.0, -30.0), 40.0)
			var in_chain_b: bool = _is_point_in_attack_lane(player.global_position, _arena_origin + Vector2(0.0, -220.0), _arena_origin + Vector2(0.0, 150.0), 40.0)
			var in_cinder: bool = false
			for target: Vector2 in _cinder_targets:
				if player.global_position.distance_to(target) <= cinder_radius:
					in_cinder = true
			if in_chain_a or in_chain_b or in_cinder:
				_hit_player_once(player, final_verdict_damage, 300.0)

func _hit_player_once(player: Node2D, damage: int, knockback: float) -> void:
	if _attack_hit_player:
		return
	_attack_hit_player = true
	if player.has_method("receive_enemy_attack"):
		player.call("receive_enemy_attack", damage, global_position, _attack_direction, knockback)
	elif player.has_method("take_damage"):
		player.call("take_damage", damage)

func _update_furnace_seals(delta: float) -> void:
	if not seal_mechanic_enabled:
		return
	_seal_timer -= delta
	if _seal_timer <= 0.0:
		_seal_timer = seal_cycle_duration
		_armed_seal_index = (_armed_seal_index + 1) % _seal_offsets.size()
		_seal_has_staggered_this_arm = false

func _check_furnace_seal_stagger() -> void:
	if not seal_mechanic_enabled or _seal_has_staggered_this_arm:
		return
	if not (_current_attack == "lunge" or _current_attack == "chain_slam" or _current_attack == "final_verdict"):
		return
	var seal_pos: Vector2 = _seal_world_position(_armed_seal_index)
	if global_position.distance_to(seal_pos) <= seal_radius:
		_seal_has_staggered_this_arm = true
		_enter_staggered()

func _prepare_cinder_targets(include_cross: bool = false) -> void:
	_cinder_targets.clear()
	var player: Node2D = _find_player()
	var base: Vector2 = _arena_origin
	if player != null:
		base = player.global_position
	_cinder_targets.append(base)
	_cinder_targets.append(base + Vector2(-74.0, 34.0))
	_cinder_targets.append(base + Vector2(74.0, 34.0))
	if include_cross:
		_cinder_targets.append(_arena_origin + Vector2(-150.0, -30.0))
		_cinder_targets.append(_arena_origin + Vector2(150.0, -30.0))
		_cinder_targets.append(_arena_origin + Vector2(0.0, -150.0))
		_cinder_targets.append(_arena_origin + Vector2(0.0, 96.0))

func _spawn_summons() -> void:
	if not summons_enabled:
		return
	var script = load("res://scripts/iso/IsoTestEnemy.gd")
	if script == null:
		return
	var parent_node: Node = get_parent()
	var profiles: Array[String] = ["ash_grunt", "furnace_imp"]
	for i: int in range(summon_count_per_cast):
		if _summons_created >= max_summons_per_fight:
			return
		var enemy: Node = script.new()
		if enemy == null:
			continue
		parent_node.add_child(enemy)
		if enemy is Node2D:
			(enemy as Node2D).global_position = _arena_origin + Vector2(-130.0 + float(i) * 260.0, 60.0)
		if enemy.has_method("configure_for_encounter_type"):
			enemy.call("configure_for_encounter_type", profiles[i % profiles.size()], current_phase)
		_summons_created += 1

func _clamp_to_arena() -> void:
	var offset: Vector2 = global_position - _arena_origin
	if offset.length() > boss_collision_clamp_radius:
		global_position = _arena_origin + offset.normalized() * boss_collision_clamp_radius

func _is_player_in_arc(player: Node2D, radius: float, arc_degrees: float) -> bool:
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > radius:
		return false
	if to_player.length() <= 0.01:
		return true
	var angle: float = abs(_attack_direction.normalized().angle_to(to_player.normalized()))
	return angle <= deg_to_rad(arc_degrees * 0.5)

func _is_point_in_attack_lane(point: Vector2, a: Vector2, b: Vector2, width: float) -> bool:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.01:
		return point.distance_to(a) <= width
	var t: float = clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var nearest: Vector2 = a + ab * t
	return point.distance_to(nearest) <= width

func _find_player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for node: Node in players:
		if node is Node2D:
			return node as Node2D
	return null

func _seal_world_position(index: int) -> Vector2:
	if _seal_offsets.is_empty():
		return _arena_origin
	return _arena_origin + _seal_offsets[index % _seal_offsets.size()]

func _spawn_damage_number(amount: int, color: Color = Color(1.0, 0.78, 0.42, 1.0)) -> void:
	_damage_numbers.append({"text": "-%d" % amount, "time": 0.62, "offset": Vector2(randf_range(-18.0, 18.0), -96.0), "color": color})

func _update_damage_numbers(delta: float) -> void:
	for i: int in range(_damage_numbers.size() - 1, -1, -1):
		var entry: Dictionary = _damage_numbers[i]
		entry["time"] = float(entry.get("time", 0.0)) - delta
		entry["offset"] = (entry.get("offset", Vector2.ZERO) as Vector2) + Vector2(0.0, -28.0 * delta)
		_damage_numbers[i] = entry
		if float(entry.get("time", 0.0)) <= 0.0:
			_damage_numbers.remove_at(i)

func _draw() -> void:
	_draw_seals()
	_draw_attack_telegraph()
	_draw_body()
	if show_boss_nameplate:
		_draw_nameplate()
	_draw_damage_numbers()
	if draw_debug_arena_bounds:
		draw_arc(to_local(_arena_origin), boss_collision_clamp_radius, 0.0, TAU, 96, Color(0.3, 0.7, 1.0, 0.4), 1.0)

func _draw_seals() -> void:
	if not seal_mechanic_enabled:
		return
	for i: int in range(_seal_offsets.size()):
		var local: Vector2 = to_local(_seal_world_position(i))
		var armed: bool = i == _armed_seal_index and not _seal_has_staggered_this_arm
		var col: Color = Color(0.30, 0.52, 0.65, 0.25)
		var line_col: Color = Color(0.46, 0.78, 0.92, 0.65)
		if armed:
			col = Color(0.35, 0.78, 1.0, 0.30 + 0.12 * sin(Time.get_ticks_msec() * 0.008))
			line_col = Color(0.72, 0.94, 1.0, 0.95)
		draw_circle(local, seal_radius, col)
		draw_arc(local, seal_radius, 0.0, TAU, 48, line_col, 2.5)
		draw_line(local + Vector2(-16.0, 0.0), local + Vector2(16.0, 0.0), line_col, 2.0)
		draw_line(local + Vector2(0.0, -16.0), local + Vector2(0.0, 16.0), line_col, 2.0)
		if armed and show_seal_labels:
			draw_string(ThemeDB.fallback_font, local + Vector2(-48.0, -seal_radius - 10.0), "ARMED SEAL", HORIZONTAL_ALIGNMENT_CENTER, 96.0, 10, Color(0.82, 0.96, 1.0, 0.98))

func _draw_attack_telegraph() -> void:
	if _state != BossState.WINDUP and _state != BossState.ACTIVE:
		return
	var warning: bool = _state == BossState.WINDUP
	var fill: Color = Color(1.0, 0.58, 0.16, 0.20) if warning else Color(1.0, 0.10, 0.03, 0.34)
	var line: Color = Color(1.0, 0.74, 0.26, 0.86) if warning else Color(1.0, 0.18, 0.06, 1.0)
	match _current_attack:
		"sweep":
			_draw_arc_wedge(Vector2.ZERO, sweep_radius, _attack_direction, sweep_arc_degrees, fill, line)
			_draw_attack_label("SWEEP", Vector2(0.0, -150.0), line)
		"chain_slam":
			_draw_lane(global_position, global_position + _attack_direction * chain_slam_length, chain_slam_width, fill, line)
			_draw_attack_label("CHAIN SLAM", to_local(global_position + _attack_direction * 148.0), line)
		"lunge":
			_draw_lane(global_position - _attack_direction * 24.0, global_position + _attack_direction * lunge_length, lunge_width, fill, line)
			_draw_attack_label("LUNGE", to_local(global_position + _attack_direction * 132.0), line)
		"falling_cinder":
			for target: Vector2 in _cinder_targets:
				var local: Vector2 = to_local(target)
				draw_circle(local, cinder_radius, fill)
				draw_arc(local, cinder_radius, 0.0, TAU, 48, line, 3.0)
			_draw_attack_label("FALLING CINDERS", Vector2(0.0, -160.0), line)
		"final_verdict":
			_draw_lane(_arena_origin + Vector2(-260.0, -30.0), _arena_origin + Vector2(260.0, -30.0), 40.0, fill, line)
			_draw_lane(_arena_origin + Vector2(0.0, -220.0), _arena_origin + Vector2(0.0, 150.0), 40.0, fill, line)
			for target: Vector2 in _cinder_targets:
				var local: Vector2 = to_local(target)
				draw_circle(local, cinder_radius, fill)
				draw_arc(local, cinder_radius, 0.0, TAU, 48, line, 3.0)
			_draw_attack_label("FINAL VERDICT", Vector2(0.0, -176.0), line)

func _draw_lane(world_a: Vector2, world_b: Vector2, width: float, fill: Color, line: Color) -> void:
	var a: Vector2 = to_local(world_a)
	var b: Vector2 = to_local(world_b)
	var dir: Vector2 = b - a
	if dir.length() <= 0.01:
		return
	var n: Vector2 = dir.normalized().orthogonal() * width
	var poly: PackedVector2Array = PackedVector2Array([a + n, b + n, b - n, a - n])
	draw_colored_polygon(poly, fill)
	draw_polyline(PackedVector2Array([a + n, b + n, b - n, a - n, a + n]), line, 2.5)

func _draw_arc_wedge(center: Vector2, radius: float, dir: Vector2, arc_degrees: float, fill: Color, line: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	points.append(center)
	var base_angle: float = dir.angle()
	var half: float = deg_to_rad(arc_degrees * 0.5)
	var steps: int = 18
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		var angle: float = base_angle - half + (half * 2.0 * t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, fill)
	var rim: PackedVector2Array = PackedVector2Array()
	for i: int in range(1, points.size()):
		rim.append(points[i])
	draw_polyline(rim, line, 3.0)

func _draw_attack_label(text: String, local_pos: Vector2, color: Color) -> void:
	if not show_attack_labels:
		return
	draw_string(ThemeDB.fallback_font, local_pos + Vector2(-72.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, 144.0, 12, color)

func _draw_body() -> void:
	var flash: float = 1.0 if _hit_flash_remaining <= 0.0 else 1.35
	var armor: Color = Color(0.09 * flash, 0.075 * flash, 0.065 * flash, 1.0)
	var gold: Color = Color(0.72, 0.52, 0.25, 1.0)
	var red: Color = Color(0.48, 0.06, 0.035, 1.0)
	if is_dead:
		armor = Color(0.045, 0.038, 0.034, 0.88)
		red = Color(0.22, 0.035, 0.030, 0.82)
	_draw_filled_ellipse(Rect2(Vector2(-58.0, 26.0), Vector2(116.0, 30.0)), Color(0.0, 0.0, 0.0, 0.36))
	draw_rect(Rect2(Vector2(-34.0, -62.0), Vector2(68.0, 76.0)), armor, true)
	draw_rect(Rect2(Vector2(-34.0, -62.0), Vector2(68.0, 76.0)), gold, false, 2.0)
	draw_rect(Rect2(Vector2(-44.0, 4.0), Vector2(88.0, 46.0)), red, true)
	draw_rect(Rect2(Vector2(-27.0, -100.0), Vector2(54.0, 42.0)), armor, true)
	draw_rect(Rect2(Vector2(-27.0, -100.0), Vector2(54.0, 42.0)), gold, false, 2.0)
	draw_line(Vector2(-16.0, -82.0), Vector2(16.0, -82.0), Color(1.0, 0.66, 0.25, 1.0), 2.0)
	for i: int in range(9):
		var angle: float = PI + float(i) * PI / 8.0
		var a: Vector2 = Vector2(cos(angle), sin(angle)) * 34.0 + Vector2(0.0, -98.0)
		var b: Vector2 = Vector2(cos(angle), sin(angle)) * 44.0 + Vector2(0.0, -98.0)
		draw_line(a, b, gold, 2.0)
	# Chain/weapon silhouette in attack direction.
	var hand: Vector2 = _attack_direction.normalized() * 38.0 + Vector2(0.0, -22.0)
	draw_line(hand, hand + _attack_direction.normalized() * 76.0, Color(0.78, 0.72, 0.62, 1.0), 5.0)
	if _state == BossState.STAGGERED:
		draw_arc(Vector2(0.0, -45.0), 82.0, 0.0, TAU, 48, Color(0.65, 0.90, 1.0, 0.95), 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(-70.0, -132.0), "STAGGERED", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 14, Color(0.80, 0.96, 1.0, 1.0))

func _draw_filled_ellipse(rect: Rect2, color: Color, segments: int = 32) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = rect.position + rect.size * 0.5
	var radius: Vector2 = rect.size * 0.5
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _draw_nameplate() -> void:
	var ratio: float = clampf(float(current_health) / float(maxi(1, max_health)), 0.0, 1.0)
	var panel: Rect2 = Rect2(Vector2(-142.0, -162.0), Vector2(284.0, 46.0))
	draw_rect(panel, Color(0.018, 0.012, 0.010, 0.90), true)
	draw_rect(panel, Color(0.76, 0.48, 0.22, 0.88), false, 2.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(10.0, 17.0), "THE ASH WARDEN  ·  PHASE %d" % current_phase, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 20.0, 13, Color(1.0, 0.82, 0.50, 1.0))
	var back: Rect2 = Rect2(panel.position + Vector2(18.0, 26.0), Vector2(panel.size.x - 36.0, 9.0))
	draw_rect(back, Color(0.16, 0.025, 0.020, 1.0), true)
	draw_rect(Rect2(back.position, Vector2(back.size.x * ratio, back.size.y)), Color(0.72, 0.055, 0.035, 1.0), true)

func _draw_damage_numbers() -> void:
	for entry: Dictionary in _damage_numbers:
		var offset: Vector2 = entry.get("offset", Vector2.ZERO) as Vector2
		var col: Color = entry.get("color", Color(1.0, 0.78, 0.42, 1.0)) as Color
		draw_string(ThemeDB.fallback_font, offset + Vector2(-34.0, 0.0), str(entry.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 68.0, 15, col)
