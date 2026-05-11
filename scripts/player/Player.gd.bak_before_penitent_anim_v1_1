extends CharacterBody2D

signal attack_performed(kind: String, origin: Vector2, direction: Vector2, radius: float, damage: float)
signal combat_action_started(action: Dictionary)
signal combat_action_performed(action: Dictionary)
signal player_dash_started(action: Dictionary)
signal player_perfect_dodge(action: Dictionary)
signal perfect_dodge_triggered()
signal died()

@export var max_hp := 100.0
@export var max_armor := 20.0
@export var move_speed := 260.0
@export var dash_speed := 820.0
@export var dash_time := 0.14
@export var dash_cooldown := 0.62

@onready var weapon_controller = $WeaponController
@onready var visuals = $Visuals

var weapon_socket: Node2D = null
var last_combat_action: Dictionary = {}
var last_started_action: Dictionary = {}

var hp := max_hp
var armor := max_armor
var ultimate := 0.0

var facing := Vector2.RIGHT

var dash_timer := 0.0
var dash_cd_timer := 0.0
var invuln_timer := 0.0
var perfect_window_timer := 0.0

var q_dash_timer := 0.0
var q_dash_duration := 0.12
var q_dash_speed := 720.0

var heavy_windup_timer := 0.0
var heavy_windup_active := false
var heavy_release_ready := false

var visual_state := "idle"
var visual_pulse := 0.0
var hit_flash := 0.0
var action_visual_timer: float = 0.0
var hurt_feedback_timer: float = 0.0
var hurt_feedback_duration: float = 0.28
var hurt_source_direction: Vector2 = Vector2.RIGHT

var hurt_screen_flash_timer: float = 0.0
var hurt_screen_flash_duration: float = 0.24
var dodge_feedback_timer: float = 0.0
var dodge_feedback_duration: float = 0.34
var dodge_feedback_direction: Vector2 = Vector2.RIGHT
var low_health_visual_time: float = 0.0
var player_particles: Array[Dictionary] = []
var player_rings: Array[Dictionary] = []
var feedback_canvas: CanvasLayer = null
var hurt_screen_rect: ColorRect = null

var dead: bool = false
var death_timer: float = 0.0
var death_return_started: bool = false
var death_duration: float = 1.35


func _ready() -> void:
	add_to_group("player")

	weapon_controller.attack_requested.connect(_on_weapon_attack_requested)

	if weapon_controller.has_signal("weapon_action_started"):
		weapon_controller.weapon_action_started.connect(_on_weapon_action_started)

	if weapon_controller.has_signal("weapon_action_queued"):
		weapon_controller.weapon_action_queued.connect(_on_weapon_action_queued)

	if weapon_controller.has_signal("weapon_action_performed"):
		weapon_controller.weapon_action_performed.connect(_on_weapon_action_performed)

	_ensure_weapon_socket()

	if GameState.selected_weapon != null:
		weapon_controller.set_weapon(GameState.selected_weapon)

	if RunState.in_run:
		apply_run_modifiers()
		_load_or_initialize_run_vitals()
	else:
		hp = max_hp
		armor = max_armor

	_ensure_feedback_overlay()
	queue_redraw()


func apply_run_modifiers() -> void:
	if not RunState.in_run:
		return

	var hp_bonus := RunState.get_modifier_value("max_hp_flat", 0.0)
	var armor_bonus := RunState.get_modifier_value("max_armor_flat", 0.0)
	var move_mult := RunState.get_modifier_value("move_speed_mult", 1.0)
	var dash_cd_mult := RunState.get_modifier_value("dash_cooldown_mult", 1.0)

	var permanent_hp_bonus: float = 0.0
	var permanent_armor_bonus: float = 0.0
	var permanent_move_mult: float = 1.0

	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")

		if game_state != null:
			if game_state.has_method("get_permanent_max_hp_bonus"):
				permanent_hp_bonus = float(game_state.call("get_permanent_max_hp_bonus"))

			if game_state.has_method("get_permanent_max_armor_bonus"):
				permanent_armor_bonus = float(game_state.call("get_permanent_max_armor_bonus"))

			if game_state.has_method("get_permanent_move_speed_mult"):
				permanent_move_mult = float(game_state.call("get_permanent_move_speed_mult"))

	var previous_max_hp := max_hp
	var previous_max_armor := max_armor

	max_hp = 100.0 + hp_bonus + permanent_hp_bonus
	max_armor = 20.0 + armor_bonus + permanent_armor_bonus
	move_speed = 260.0 * move_mult * permanent_move_mult
	dash_cooldown = 0.62 * dash_cd_mult

	hp = minf(max_hp, hp + maxf(0.0, max_hp - previous_max_hp))
	armor = minf(max_armor, armor + maxf(0.0, max_armor - previous_max_armor))

	if weapon_controller and weapon_controller.has_method("apply_run_modifiers"):
		weapon_controller.apply_run_modifiers()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if dead:
		_update_death(delta)

		if visuals and visuals.has_method("set_visual_state"):
			visuals.set_visual_state("death", facing, hit_flash, dash_timer)

		queue_redraw()
		return

	if _is_interface_blocking_gameplay():
		velocity = Vector2.ZERO
		move_and_slide()

		ultimate = weapon_controller.ultimate_charge

		if not visual_state in ["hit", "death"]:
			visual_state = "idle"
			action_visual_timer = 0.0

		if visuals and visuals.has_method("set_visual_state"):
			visuals.set_visual_state(visual_state, facing, hit_flash, dash_timer)

		visual_pulse += delta
		queue_redraw()
		return

	ultimate = weapon_controller.ultimate_charge

	_read_facing()
	_handle_actions()
	_update_heavy_windup(delta)
	_move(delta)

	if visuals and visuals.has_method("set_visual_state"):
		visuals.set_visual_state(visual_state, facing, hit_flash, dash_timer)

	_save_run_vitals()

	visual_pulse += delta
	queue_redraw()


func _tick_timers(delta: float) -> void:
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cd_timer = maxf(0.0, dash_cd_timer - delta)
	q_dash_timer = maxf(0.0, q_dash_timer - delta)
	action_visual_timer = maxf(0.0, action_visual_timer - delta)

	invuln_timer = maxf(0.0, invuln_timer - delta)
	perfect_window_timer = maxf(0.0, perfect_window_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	hurt_feedback_timer = maxf(0.0, hurt_feedback_timer - delta)
	hurt_screen_flash_timer = maxf(0.0, hurt_screen_flash_timer - delta)
	dodge_feedback_timer = maxf(0.0, dodge_feedback_timer - delta)
	low_health_visual_time += delta

	_tick_player_feedback_fx(delta)
	_update_feedback_overlay()

	weapon_controller.tick(delta)


func _read_facing() -> void:
	var mouse_dir := get_global_mouse_position() - global_position

	if mouse_dir.length() > 8.0:
		facing = mouse_dir.normalized()


func _handle_actions() -> void:
	if dead:
		return

	if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0.0 and not heavy_windup_active:
		dash_timer = dash_time
		dash_cd_timer = dash_cooldown
		invuln_timer = dash_time + 0.08
		perfect_window_timer = 0.18
		visual_state = "dash"
		action_visual_timer = dash_time
		dodge_feedback_timer = maxf(dodge_feedback_timer, 0.16)
		dodge_feedback_direction = facing.normalized()
		_spawn_player_ring("dash_start", dodge_feedback_direction)
		_emit_player_dash_action("dash", facing.normalized())

	if Input.is_action_just_pressed("light_attack") and not heavy_windup_active:
		weapon_controller.try_light(global_position, facing)

	if Input.is_action_just_pressed("heavy_attack") and not heavy_windup_active:
		if weapon_controller.try_begin_heavy():
			heavy_windup_active = true
			heavy_windup_timer = weapon_controller.get_heavy_windup_time()
			heavy_release_ready = false
			visual_state = "heavy_windup"
			action_visual_timer = heavy_windup_timer

	if Input.is_action_just_pressed("skill_q") and not heavy_windup_active:
		if weapon_controller.try_q(global_position, facing):
			q_dash_timer = q_dash_duration
			invuln_timer = maxf(invuln_timer, q_dash_duration)
			visual_state = "q"
			action_visual_timer = maxf(action_visual_timer, q_dash_duration + 0.18)
			dodge_feedback_timer = maxf(dodge_feedback_timer, 0.14)
			dodge_feedback_direction = facing.normalized()
			_spawn_player_ring("dash_start", dodge_feedback_direction)

	if Input.is_action_just_pressed("ultimate") and not heavy_windup_active:
		weapon_controller.try_ultimate(global_position, facing)


func _update_heavy_windup(delta: float) -> void:
	if not heavy_windup_active:
		return

	heavy_windup_timer -= delta
	visual_state = "heavy_windup"

	if heavy_windup_timer <= 0.0:
		heavy_windup_active = false
		heavy_release_ready = true
		weapon_controller.release_heavy(global_position, facing)


func _move(_delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if heavy_windup_active:
		velocity = input_vec * move_speed * 0.25
		visual_state = "heavy_windup"

	elif q_dash_timer > 0.0:
		velocity = facing * q_dash_speed
		visual_state = "q"

	elif dash_timer > 0.0:
		velocity = facing * dash_speed
		visual_state = "dash"

	else:
		velocity = input_vec * move_speed

		if action_visual_timer > 0.0 and visual_state in ["light", "light_1", "light_2", "light_3", "heavy", "q", "ultimate"]:
			pass
		elif input_vec.length() > 0.1:
			visual_state = "move"
		elif not visual_state in ["hit", "death"]:
			visual_state = "idle"

	move_and_slide()


func _on_weapon_action_started(kind: String, visual_duration: float) -> void:
	visual_state = kind
	action_visual_timer = maxf(visual_duration, 0.08)


func _on_weapon_action_queued(action: Dictionary) -> void:
	last_started_action = action.duplicate(true)
	combat_action_started.emit(last_started_action.duplicate(true))


func _on_weapon_action_performed(action: Dictionary) -> void:
	last_combat_action = action.duplicate(true)
	combat_action_performed.emit(last_combat_action.duplicate(true))


func _on_weapon_attack_requested(kind: String, origin: Vector2, direction: Vector2, radius: float, damage: float) -> void:
	if weapon_controller != null and weapon_controller.has_method("get_last_emitted_action"):
		var action: Variant = weapon_controller.call("get_last_emitted_action")

		if action is Dictionary and not action.is_empty():
			last_combat_action = action.duplicate(true)

	attack_performed.emit(kind, origin, direction, radius, damage)


func get_last_combat_action() -> Dictionary:
	return last_combat_action.duplicate(true)


func get_last_started_action() -> Dictionary:
	return last_started_action.duplicate(true)


func _ensure_weapon_socket() -> void:
	weapon_socket = get_node_or_null("WeaponSocket") as Node2D

	if weapon_socket != null:
		return

	weapon_socket = Node2D.new()
	weapon_socket.name = "WeaponSocket"
	weapon_socket.z_index = 86
	add_child(weapon_socket)


func _emit_player_dash_action(action_kind: String, direction: Vector2) -> void:
	player_dash_started.emit(_build_player_action_payload(action_kind, direction))


func _build_player_action_payload(action_kind: String, direction: Vector2) -> Dictionary:
	var safe_direction: Vector2 = direction

	if safe_direction.length() <= 0.01:
		safe_direction = facing

	if safe_direction.length() <= 0.01:
		safe_direction = Vector2.RIGHT

	safe_direction = safe_direction.normalized()

	return {
		"kind": action_kind,
		"action_id": "player.%s" % action_kind,
		"action_type": action_kind,
		"display_name": action_kind.capitalize(),
		"weapon_id": "player",
		"weapon_name": "Penitent Knight",
		"tags": _get_player_action_tags(action_kind),
		"origin": global_position,
		"direction": safe_direction,
		"radius": 0.0,
		"damage": 0.0,
		"visual_duration": action_visual_timer
	}


func _get_player_action_tags(action_kind: String) -> Array[String]:
	match action_kind:
		"dash":
			return ["movement", "dash", "i_frame", "mobility"]
		"perfect_dodge":
			return ["movement", "dodge", "perfect", "i_frame", "trigger"]
		_:
			return ["player_action"]


func take_damage(amount: float, source_position: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return

	if invuln_timer > 0.0:
		var safe_source_direction := _get_safe_direction_from_source(source_position)
		dodge_feedback_direction = safe_source_direction

		if perfect_window_timer > 0.0:
			perfect_window_timer = 0.0
			gain_ultimate(18.0)
			dodge_feedback_timer = dodge_feedback_duration
			_spawn_player_ring("perfect", safe_source_direction)
			_spawn_player_particles("perfect", safe_source_direction)
			perfect_dodge_triggered.emit()
			player_perfect_dodge.emit(_build_player_action_payload("perfect_dodge", safe_source_direction))
		else:
			dodge_feedback_timer = maxf(dodge_feedback_timer, 0.16)
			_spawn_player_ring("invuln", safe_source_direction)

		return

	var remaining := amount

	if armor > 0.0:
		var absorbed := minf(armor, remaining * 0.7)
		armor -= absorbed
		remaining -= absorbed

	hp -= remaining
	hp = maxf(0.0, hp)

	hit_flash = 0.19
	hurt_feedback_timer = hurt_feedback_duration
	hurt_source_direction = global_position - source_position

	if hurt_source_direction.length() <= 0.01:
		hurt_source_direction = -facing

	hurt_source_direction = hurt_source_direction.normalized()
	hurt_screen_flash_timer = hurt_screen_flash_duration
	_spawn_player_ring("hurt", hurt_source_direction)
	_spawn_player_particles("hurt", hurt_source_direction)
	visual_state = "hit"
	action_visual_timer = 0.16

	_save_run_vitals()

	if hp <= 0.0:
		_start_death()


func gain_ultimate(amount: float) -> void:
	weapon_controller.gain_ultimate(amount)
	ultimate = weapon_controller.ultimate_charge


func _start_death() -> void:
	if dead:
		return

	dead = true
	death_timer = death_duration
	death_return_started = false

	velocity = Vector2.ZERO
	visual_state = "death"
	action_visual_timer = 0.0

	dash_timer = 0.0
	q_dash_timer = 0.0
	heavy_windup_active = false
	heavy_windup_timer = 0.0
	heavy_release_ready = false

	invuln_timer = 999.0
	perfect_window_timer = 0.0

	_disable_player_collision()

	if weapon_controller:
		weapon_controller.ultimate_charge = 0.0

	if visuals and visuals.has_method("set_visual_state"):
		visuals.set_visual_state("death", facing, hit_flash, dash_timer)


func _is_interface_blocking_gameplay() -> bool:
	for dialogue_box in get_tree().get_nodes_in_group("dialogue_box"):
		if dialogue_box != null and dialogue_box.has_method("is_dialogue_active"):
			if bool(dialogue_box.call("is_dialogue_active")):
				return true

	for menu in get_tree().get_nodes_in_group("smith_menu"):
		if menu != null and menu.has_method("is_menu_active"):
			if bool(menu.call("is_menu_active")):
				return true

	for menu in get_tree().get_nodes_in_group("codex_menu"):
		if menu != null and menu.has_method("is_menu_active"):
			if bool(menu.call("is_menu_active")):
				return true

	for menu in get_tree().get_nodes_in_group("training_dummy_menu"):
		if menu != null and menu.has_method("is_menu_active"):
			if bool(menu.call("is_menu_active")):
				return true

	return false


func _update_death(delta: float) -> void:
	death_timer = maxf(0.0, death_timer - delta)
	velocity = Vector2.ZERO
	move_and_slide()

	if death_timer <= 0.0 and not death_return_started:
		death_return_started = true
		died.emit()
		_request_death_return_to_hub()


func _disable_player_collision() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			var shape := child as CollisionShape2D
			shape.disabled = true
		elif child is CollisionPolygon2D:
			var polygon := child as CollisionPolygon2D
			polygon.disabled = true


func _request_death_return_to_hub() -> void:
	if Engine.has_singleton("RunState"):
		pass

	if has_node("/root/RunState"):
		var run_state := get_node("/root/RunState")

		if run_state != null and run_state.has_method("end_run"):
			run_state.call("end_run")

	var room := get_parent()

	if room != null and room.has_signal("return_to_hub_requested"):
		room.emit_signal("return_to_hub_requested")
		return

	if room != null and room.has_method("return_to_hub"):
		room.call("return_to_hub")
		return

	push_warning("Player died, but current room has no return-to-hub signal or method.")


func _load_or_initialize_run_vitals() -> void:
	if not RunState.in_run:
		return

	if not RunState.has_method("get_saved_player_vitals"):
		return

	var vitals: Dictionary = RunState.get_saved_player_vitals(max_hp, max_armor)

	hp = clampf(float(vitals.get("hp", max_hp)), 0.0, max_hp)
	armor = clampf(float(vitals.get("armor", max_armor)), 0.0, max_armor)

	_save_run_vitals()


func _save_run_vitals() -> void:
	if not RunState.in_run:
		return

	if not RunState.has_method("save_player_vitals"):
		return

	RunState.save_player_vitals(hp, armor)



func _ensure_feedback_overlay() -> void:
	feedback_canvas = get_node_or_null("PlayerFeedbackCanvas") as CanvasLayer

	if feedback_canvas == null:
		feedback_canvas = CanvasLayer.new()
		feedback_canvas.name = "PlayerFeedbackCanvas"
		feedback_canvas.layer = 80
		add_child(feedback_canvas)

	hurt_screen_rect = feedback_canvas.get_node_or_null("HurtScreenFlash") as ColorRect

	if hurt_screen_rect == null:
		hurt_screen_rect = ColorRect.new()
		hurt_screen_rect.name = "HurtScreenFlash"
		feedback_canvas.add_child(hurt_screen_rect)

	hurt_screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hurt_screen_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_screen_rect.offset_left = 0.0
	hurt_screen_rect.offset_top = 0.0
	hurt_screen_rect.offset_right = 0.0
	hurt_screen_rect.offset_bottom = 0.0
	hurt_screen_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	hurt_screen_rect.visible = false


func _update_feedback_overlay() -> void:
	if hurt_screen_rect == null:
		return

	var overlay_alpha := 0.0

	if hurt_screen_flash_timer > 0.0:
		var hurt_ratio := clampf(hurt_screen_flash_timer / hurt_screen_flash_duration, 0.0, 1.0)
		overlay_alpha = maxf(overlay_alpha, 0.22 * hurt_ratio)

	if not dead and hp > 0.0:
		var hp_ratio := clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)

		if hp_ratio <= 0.30:
			var danger_strength := 1.0 - clampf(hp_ratio / 0.30, 0.0, 1.0)
			var pulse := 0.5 + 0.5 * sin(low_health_visual_time * 5.4)
			overlay_alpha = maxf(overlay_alpha, 0.055 * danger_strength * pulse)

	hurt_screen_rect.visible = overlay_alpha > 0.002
	hurt_screen_rect.color = Color(0.82, 0.02, 0.01, overlay_alpha)


func _get_safe_direction_from_source(source_position: Vector2) -> Vector2:
	var safe_direction := global_position - source_position

	if safe_direction.length() <= 0.01:
		safe_direction = -facing

	if safe_direction.length() <= 0.01:
		safe_direction = Vector2.RIGHT

	return safe_direction.normalized()


func _spawn_player_ring(kind: String, direction: Vector2) -> void:
	var safe_direction := direction

	if safe_direction.length() <= 0.01:
		safe_direction = Vector2.RIGHT

	safe_direction = safe_direction.normalized()

	var color := Color(1.0, 0.18, 0.08, 0.56)
	var start_radius := 14.0
	var end_radius := 46.0
	var duration := 0.26
	var center := -safe_direction * 12.0 + Vector2(0.0, -8.0)

	match kind:
		"perfect":
			color = Color(0.70, 0.95, 1.0, 0.78)
			start_radius = 18.0
			end_radius = 70.0
			duration = 0.36
			center = Vector2.ZERO
		"invuln":
			color = Color(0.48, 0.78, 1.0, 0.52)
			start_radius = 14.0
			end_radius = 44.0
			duration = 0.20
			center = Vector2.ZERO
		"dash_start":
			color = Color(0.52, 0.82, 1.0, 0.38)
			start_radius = 10.0
			end_radius = 36.0
			duration = 0.16
			center = Vector2.ZERO
		_:
			pass

	player_rings.append({
		"kind": kind,
		"time": duration,
		"max_time": duration,
		"start_radius": start_radius,
		"end_radius": end_radius,
		"center": center,
		"color": color
	})


func _spawn_player_particles(kind: String, direction: Vector2) -> void:
	var safe_direction := direction

	if safe_direction.length() <= 0.01:
		safe_direction = Vector2.RIGHT

	safe_direction = safe_direction.normalized()

	var count := 9
	var base_color := Color(1.0, 0.22, 0.08, 0.78)
	var start := -safe_direction * 16.0 + Vector2(0.0, -8.0)
	var speed_min := 42.0
	var speed_max := 118.0

	if kind == "perfect":
		count = 12
		base_color = Color(0.72, 0.94, 1.0, 0.82)
		start = Vector2.ZERO
		speed_min = 64.0
		speed_max = 150.0

	for _i in range(count):
		var spread := randf_range(-0.95, 0.95)
		var particle_direction := safe_direction.rotated(spread).normalized()
		var speed := randf_range(speed_min, speed_max)
		var duration := randf_range(0.18, 0.34)

		player_particles.append({
			"time": duration,
			"max_time": duration,
			"position": start + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)),
			"velocity": particle_direction * speed,
			"radius": randf_range(2.0, 4.0),
			"color": base_color
		})


func _tick_player_feedback_fx(delta: float) -> void:
	for i in range(player_particles.size() - 1, -1, -1):
		var particle := player_particles[i]
		var time_left := float(particle.get("time", 0.0)) - delta
		var position: Vector2 = particle.get("position", Vector2.ZERO)
		var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)

		position += velocity * delta
		velocity = velocity.lerp(Vector2.ZERO, 8.0 * delta)

		particle["time"] = time_left
		particle["position"] = position
		particle["velocity"] = velocity
		player_particles[i] = particle

		if time_left <= 0.0:
			player_particles.remove_at(i)

	for i in range(player_rings.size() - 1, -1, -1):
		var ring := player_rings[i]
		var time_left := float(ring.get("time", 0.0)) - delta
		ring["time"] = time_left
		player_rings[i] = ring

		if time_left <= 0.0:
			player_rings.remove_at(i)


func _draw_dash_invulnerability_feedback() -> void:
	if dead:
		return

	if invuln_timer <= 0.0:
		return

	var alpha := clampf(invuln_timer / 0.24, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(low_health_visual_time * 28.0)
	var radius := 29.0 + pulse * 4.0
	var color := Color(0.42, 0.72, 1.0, 0.18 * alpha)
	var edge := Color(0.72, 0.92, 1.0, 0.42 * alpha)

	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 64, edge, 2.0)


func _draw_low_health_feedback() -> void:
	if dead or hp <= 0.0:
		return

	var hp_ratio := clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)

	if hp_ratio > 0.30:
		return

	var danger_strength := 1.0 - clampf(hp_ratio / 0.30, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(low_health_visual_time * 5.4)
	var alpha := danger_strength * pulse
	var radius := 36.0 + pulse * 8.0

	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(1.0, 0.08, 0.03, 0.20 * alpha), 2.0)
	draw_circle(Vector2.ZERO, radius * 0.72, Color(1.0, 0.02, 0.0, 0.035 * alpha))


func _draw_dodge_feedback() -> void:
	if dodge_feedback_timer <= 0.0:
		return

	var remaining_ratio := clampf(dodge_feedback_timer / dodge_feedback_duration, 0.0, 1.0)
	var progress := 1.0 - remaining_ratio
	var radius := lerpf(20.0, 62.0, progress)
	var alpha := remaining_ratio
	var dir := dodge_feedback_direction

	if dir.length() <= 0.01:
		dir = Vector2.RIGHT

	dir = dir.normalized()
	draw_circle(Vector2.ZERO, radius * 0.72, Color(0.42, 0.80, 1.0, 0.09 * alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(0.82, 0.96, 1.0, 0.64 * alpha), 4.0)
	draw_line(-dir * 24.0, dir * 34.0, Color(0.82, 0.96, 1.0, 0.32 * alpha), 3.0)


func _draw_hurt_feedback() -> void:
	if hurt_feedback_timer <= 0.0:
		return

	var remaining_ratio := clampf(hurt_feedback_timer / hurt_feedback_duration, 0.0, 1.0)
	var progress := 1.0 - remaining_ratio
	var alpha := remaining_ratio
	var dir := hurt_source_direction

	if dir.length() <= 0.01:
		dir = Vector2.RIGHT

	dir = dir.normalized()

	var impact_center := -dir * 18.0 + Vector2(0.0, -8.0)
	var ring_radius := 18.0 + progress * 40.0
	var warning_color := Color(1.0, 0.08, 0.04, 0.30 * alpha)
	var hot_color := Color(1.0, 0.70, 0.22, 0.62 * alpha)

	draw_circle(impact_center, ring_radius * 0.58, warning_color)
	draw_arc(impact_center, ring_radius, 0.0, TAU, 48, hot_color, maxf(1.0, 4.0 * alpha))
	draw_line(impact_center - dir * 20.0, impact_center + dir * 26.0, Color(1.0, 0.18, 0.06, 0.48 * alpha), maxf(1.0, 4.0 * alpha))

	var side := dir.orthogonal().normalized()
	draw_line(impact_center - side * 15.0, impact_center + side * 15.0, Color(1.0, 0.86, 0.42, 0.32 * alpha), maxf(1.0, 2.0 * alpha))


func _draw_player_rings() -> void:
	for ring in player_rings:
		var time_left := float(ring.get("time", 0.0))
		var max_time := maxf(float(ring.get("max_time", 0.01)), 0.01)
		var remaining_ratio := clampf(time_left / max_time, 0.0, 1.0)
		var progress := 1.0 - remaining_ratio
		var center: Vector2 = ring.get("center", Vector2.ZERO)
		var color: Color = ring.get("color", Color.WHITE)
		var start_radius := float(ring.get("start_radius", 14.0))
		var end_radius := float(ring.get("end_radius", 42.0))
		var radius := lerpf(start_radius, end_radius, progress)
		var alpha := color.a * remaining_ratio

		draw_circle(center, radius * 0.60, Color(color.r, color.g, color.b, 0.10 * alpha))
		draw_arc(center, radius, 0.0, TAU, 64, Color(color.r, color.g, color.b, alpha), maxf(1.0, 3.0 * remaining_ratio))


func _draw_player_particles() -> void:
	for particle in player_particles:
		var time_left := float(particle.get("time", 0.0))
		var max_time := maxf(float(particle.get("max_time", 0.01)), 0.01)
		var alpha := clampf(time_left / max_time, 0.0, 1.0)
		var position: Vector2 = particle.get("position", Vector2.ZERO)
		var radius := float(particle.get("radius", 2.0))
		var color: Color = particle.get("color", Color.WHITE)

		draw_circle(position, radius, Color(color.r, color.g, color.b, color.a * alpha))


func _draw() -> void:
	_draw_dash_invulnerability_feedback()
	_draw_low_health_feedback()
	_draw_dodge_feedback()
	_draw_hurt_feedback()
	_draw_player_rings()
	_draw_player_particles()
