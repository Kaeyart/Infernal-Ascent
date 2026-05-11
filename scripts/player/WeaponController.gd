extends Node

signal attack_requested(kind: String, origin: Vector2, direction: Vector2, radius: float, damage: float)
signal weapon_action_queued(action: Dictionary)
signal weapon_action_performed(action: Dictionary)
signal weapon_changed(weapon: WeaponData)
signal weapon_action_started(kind: String, visual_duration: float)

@export var weapon: WeaponData

var light_cd: float = 0.0
var heavy_cd: float = 0.0
var q_cd: float = 0.0
var ultimate_cd: float = 0.0

var ultimate_charge: float = 0.0

var light_combo_step: int = 0
var light_combo_timer: float = 0.0
var light_combo_reset_time: float = 0.82

var heavy_windup_time: float = 0.36

var light_damage_flat: float = 0.0
var heavy_radius_mult: float = 1.0
var q_damage_mult: float = 1.0
var ultimate_cost_mult: float = 1.0
var ultimate_gain_mult: float = 1.0

var pending_attack: Dictionary = {}
var last_emitted_action: Dictionary = {}
var pending_attack_timer: float = 0.0
var action_lock_timer: float = 0.0


func _ready() -> void:
	if weapon == null:
		push_warning("WeaponController has no WeaponData assigned.")
	else:
		_sync_from_weapon()
		weapon_changed.emit(weapon)

	if RunState.in_run:
		apply_run_modifiers()


func tick(delta: float) -> void:
	light_cd = maxf(0.0, light_cd - delta)
	heavy_cd = maxf(0.0, heavy_cd - delta)
	q_cd = maxf(0.0, q_cd - delta)
	ultimate_cd = maxf(0.0, ultimate_cd - delta)
	action_lock_timer = maxf(0.0, action_lock_timer - delta)

	if light_combo_timer > 0.0:
		light_combo_timer -= delta
	else:
		light_combo_step = 0

	if not pending_attack.is_empty():
		pending_attack_timer -= delta

		if pending_attack_timer <= 0.0:
			_emit_pending_attack()


func set_weapon(new_weapon: WeaponData) -> void:
	weapon = new_weapon

	light_cd = 0.0
	heavy_cd = 0.0
	q_cd = 0.0
	ultimate_cd = 0.0
	ultimate_charge = 0.0

	light_combo_step = 0
	light_combo_timer = 0.0
	pending_attack.clear()
	pending_attack_timer = 0.0
	action_lock_timer = 0.0

	_sync_from_weapon()

	if RunState.in_run:
		apply_run_modifiers()

	weapon_changed.emit(weapon)


func _sync_from_weapon() -> void:
	if weapon == null:
		return

	heavy_windup_time = weapon.heavy_windup_time


func apply_run_modifiers() -> void:
	light_damage_flat = RunState.get_modifier_value("light_damage_flat", 0.0)
	heavy_radius_mult = RunState.get_modifier_value("heavy_radius_mult", 1.0)
	q_damage_mult = RunState.get_modifier_value("q_damage_mult", 1.0)
	ultimate_cost_mult = RunState.get_modifier_value("ultimate_cost_mult", 1.0)
	ultimate_gain_mult = RunState.get_modifier_value("ultimate_gain_mult", 1.0)


func try_light(origin: Vector2, direction: Vector2) -> bool:
	if weapon == null:
		return false

	if light_cd > 0.0 or _has_pending_attack():
		return false

	var step: int = light_combo_step
	var attack_kind := "light_1"
	var radius: float = weapon.light_radius
	var damage: float = weapon.light_damage + light_damage_flat
	var cooldown: float = weapon.light_cooldown
	var startup: float = weapon.light_startup
	var active_time: float = weapon.light_active_time
	var recovery: float = weapon.light_recovery

	if step == 1:
		attack_kind = "light_2"
		radius += 12.0
		damage *= 1.16
		cooldown += 0.035
		startup += 0.01
		recovery += 0.025
	elif step == 2:
		attack_kind = "light_3"
		radius += 26.0
		damage *= 1.48
		cooldown += 0.10
		startup += 0.035
		active_time += 0.035
		recovery += 0.09

	light_cd = cooldown
	light_combo_timer = light_combo_reset_time
	light_combo_step = (light_combo_step + 1) % 3

	_queue_attack(
		attack_kind,
		origin,
		_safe_direction(direction),
		radius,
		damage,
		startup,
		active_time,
		recovery
	)

	return true


func try_begin_heavy() -> bool:
	if weapon == null:
		return false

	if heavy_cd > 0.0 or _has_pending_attack():
		return false

	light_combo_step = 0
	light_combo_timer = 0.0
	heavy_cd = weapon.heavy_cooldown
	action_lock_timer = maxf(action_lock_timer, weapon.heavy_windup_time)
	weapon_action_started.emit("heavy_windup", weapon.heavy_windup_time)

	return true


func release_heavy(origin: Vector2, direction: Vector2) -> void:
	if weapon == null:
		return

	_queue_attack(
		"heavy",
		origin,
		_safe_direction(direction),
		weapon.heavy_radius * heavy_radius_mult,
		weapon.heavy_damage,
		weapon.heavy_startup,
		weapon.heavy_active_time,
		weapon.heavy_recovery
	)


func try_q(origin: Vector2, direction: Vector2) -> bool:
	if weapon == null:
		return false

	if q_cd > 0.0 or _has_pending_attack():
		return false

	light_combo_step = 0
	light_combo_timer = 0.0
	q_cd = weapon.q_cooldown

	var safe_direction := _safe_direction(direction)
	var slash_origin := origin + safe_direction * weapon.q_offset

	_queue_attack(
		"q",
		slash_origin,
		safe_direction,
		weapon.q_radius,
		weapon.q_damage * q_damage_mult,
		weapon.q_startup,
		weapon.q_active_time,
		weapon.q_recovery
	)

	return true


func try_ultimate(origin: Vector2, direction: Vector2) -> bool:
	if weapon == null:
		return false

	var ultimate_cost := weapon.ultimate_cost * ultimate_cost_mult

	if ultimate_charge < ultimate_cost:
		return false

	if ultimate_cd > 0.0 or _has_pending_attack():
		return false

	light_combo_step = 0
	light_combo_timer = 0.0

	var safe_direction := _safe_direction(direction)

	ultimate_charge = 0.0
	ultimate_cd = weapon.ultimate_cooldown

	_queue_attack(
		"ultimate",
		origin,
		safe_direction,
		weapon.ultimate_radius,
		weapon.ultimate_damage,
		weapon.ultimate_startup,
		weapon.ultimate_active_time,
		weapon.ultimate_recovery
	)

	return true


func gain_ultimate(amount: float) -> void:
	ultimate_charge = minf(100.0, ultimate_charge + amount * ultimate_gain_mult)


func get_cooldown_percent(kind: String) -> float:
	if weapon == null:
		return 0.0

	match kind:
		"light":
			return light_cd / maxf(weapon.light_cooldown, 0.001)
		"heavy":
			return heavy_cd / maxf(weapon.heavy_cooldown, 0.001)
		"q":
			return q_cd / maxf(weapon.q_cooldown, 0.001)
		"ultimate":
			return ultimate_cd / maxf(weapon.ultimate_cooldown, 0.001)
		_:
			return 0.0


func get_light_combo_step() -> int:
	return light_combo_step


func get_heavy_windup_time() -> float:
	return heavy_windup_time


func get_ultimate_cost() -> float:
	if weapon == null:
		return 100.0

	return weapon.ultimate_cost * ultimate_cost_mult


func is_action_locked() -> bool:
	return action_lock_timer > 0.0 or _has_pending_attack()


func _queue_attack(
	kind: String,
	origin: Vector2,
	direction: Vector2,
	radius: float,
	damage: float,
	startup: float,
	active_time: float,
	recovery: float
) -> void:
	var safe_startup: float = maxf(0.0, startup)
	var safe_active: float = maxf(0.01, active_time)
	var safe_recovery: float = maxf(0.0, recovery)
	var visual_duration: float = safe_startup + safe_active + safe_recovery
	var safe_direction: Vector2 = _safe_direction(direction)

	pending_attack = _build_action_payload(
		kind,
		origin,
		safe_direction,
		radius,
		damage,
		safe_startup,
		safe_active,
		safe_recovery,
		visual_duration
	)

	pending_attack_timer = safe_startup
	action_lock_timer = maxf(action_lock_timer, visual_duration)
	weapon_action_started.emit(kind, visual_duration)
	weapon_action_queued.emit(pending_attack.duplicate(true))

	if safe_startup <= 0.0:
		_emit_pending_attack()


func _emit_pending_attack() -> void:
	if pending_attack.is_empty():
		return

	last_emitted_action = pending_attack.duplicate(true)

	attack_requested.emit(
		str(pending_attack.get("kind", "light")),
		pending_attack.get("origin", Vector2.ZERO),
		pending_attack.get("direction", Vector2.RIGHT),
		float(pending_attack.get("radius", 48.0)),
		float(pending_attack.get("damage", 1.0))
	)

	weapon_action_performed.emit(last_emitted_action.duplicate(true))
	pending_attack.clear()
	pending_attack_timer = 0.0


func get_last_emitted_action() -> Dictionary:
	return last_emitted_action.duplicate(true)


func get_pending_action() -> Dictionary:
	return pending_attack.duplicate(true)


func _build_action_payload(
	kind: String,
	origin: Vector2,
	direction: Vector2,
	radius: float,
	damage: float,
	startup: float,
	active_time: float,
	recovery: float,
	visual_duration: float
) -> Dictionary:
	var weapon_id: String = "unarmed"
	var weapon_name: String = "Unarmed"
	var weapon_family: String = "unarmed"
	var action_tags: Array[String] = _get_action_tags(kind)
	var display_name: String = kind.capitalize()

	if weapon != null:
		weapon_id = weapon.id
		weapon_name = weapon.display_name
		weapon_family = weapon.weapon_family if _object_has_property(weapon, "weapon_family") else weapon.id

		if weapon.has_method("get_action_display_name"):
			display_name = str(weapon.call("get_action_display_name", kind))

	return {
		"kind": kind,
		"action_id": "%s.%s" % [weapon_id, kind],
		"action_type": _get_action_type(kind),
		"display_name": display_name,
		"weapon_id": weapon_id,
		"weapon_name": weapon_name,
		"weapon_family": weapon_family,
		"tags": action_tags,
		"origin": origin,
		"direction": direction,
		"radius": radius,
		"damage": damage,
		"startup": startup,
		"active_time": active_time,
		"recovery": recovery,
		"visual_duration": visual_duration,
		"combo_step": light_combo_step
	}


func _get_action_type(kind: String) -> String:
	match kind:
		"light", "light_1", "light_2", "light_3":
			return "light"
		"heavy", "heavy_windup":
			return "heavy"
		"q":
			return "skill_q"
		"ultimate":
			return "ultimate"
		_:
			return kind


func _get_action_tags(kind: String) -> Array[String]:
	if weapon != null and weapon.has_method("get_action_tags"):
		var value: Variant = weapon.call("get_action_tags", kind)

		if value is Array:
			var result: Array[String] = []

			for tag in value:
				result.append(str(tag))

			return result

	match kind:
		"light", "light_1", "light_2", "light_3":
			return ["attack", "light", "melee", "slash", "combo"]
		"heavy", "heavy_windup":
			return ["attack", "heavy", "melee", "cleave", "charged"]
		"q":
			return ["attack", "skill", "q", "movement", "dash_slash"]
		"ultimate":
			return ["attack", "ultimate", "area", "judgment"]
		_:
			return ["attack"]


func _object_has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false

	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true

	return false


func _has_pending_attack() -> bool:
	return not pending_attack.is_empty()


func _safe_direction(direction: Vector2) -> Vector2:
	if direction.length() <= 0.01:
		return Vector2.RIGHT

	return direction.normalized()
