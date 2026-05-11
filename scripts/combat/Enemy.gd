extends CharacterBody2D

signal died(position: Vector2)

const CIRCLE0_ENEMY_SPRITE_ROOT := "res://art/actors/enemies/circle0"
const CIRCLE0_SPRITE_DIRECTIONS: Array[String] = ["down", "left", "right", "up"]

@export var max_hp := 30.0
@export var damage := 5.0
@export var speed := 90.0
@export var contact_radius := 28.0
@export var enemy_rank := "normal"

var hp := max_hp
var target: Node2D = null
var hit_flash := 0.0
var dead := false

var enemy_kind: String = ""
var enemy_role: String = ""
var enemy_display_name: String = ""
var sprite: Sprite2D = null
var visual_time: float = 0.0
var idle_frames: Array[Texture2D] = []
var run_frames: Array[Texture2D] = []
var circle0_direction_frames: Dictionary = {}
var circle0_uses_role_sprite: bool = false

var particles: Array[Dictionary] = []
var impact_rings: Array[Dictionary] = []
var attack_release_bursts: Array[Dictionary] = []


var base_sprite_scale: Vector2 = Vector2.ONE
var base_sprite_position: Vector2 = Vector2.ZERO
var hit_reaction_timer: float = 0.0
var hit_reaction_duration: float = 0.18
var hit_reaction_direction: Vector2 = Vector2.RIGHT
var hit_reaction_strength: float = 0.0
var hit_reaction_kind: String = "hit"

var death_timer: float = 0.0
var death_duration: float = 0.42
var death_started: bool = false

var base_damage: float = 5.0
var base_speed: float = 90.0
var base_contact_radius: float = 28.0

var attack_state: String = "ready"
var attack_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

var attack_style: String = "circle"
var current_attack_style: String = "circle"

var attack_range: float = 44.0
var attack_width: float = 24.0
var attack_angle_width: float = 0.75
var attack_lunge_distance: float = 52.0
var attack_windup_time: float = 0.55
var attack_recover_time: float = 0.22

var attack_origin_position: Vector2 = Vector2.ZERO
var attack_target_position: Vector2 = Vector2.ZERO
var attack_direction: Vector2 = Vector2.RIGHT
var scribe_mark_position: Vector2 = Vector2.ZERO

var status_effects: Dictionary = {}
var boss_phase: int = 1

func setup_enemy_stats(
	new_max_hp: float,
	new_damage: float,
	new_speed: float,
	new_contact_radius: float,
	new_rank: String = "normal",
	new_role: String = ""
) -> void:
	max_hp = new_max_hp
	hp = max_hp

	base_damage = new_damage
	base_speed = new_speed
	base_contact_radius = new_contact_radius

	damage = base_damage
	speed = base_speed
	contact_radius = base_contact_radius
	enemy_rank = new_rank
	enemy_role = new_role.strip_edges()
	enemy_display_name = ""

	_choose_enemy_kind()
	_apply_kind_behavior()

	if sprite != null:
		_load_visual_frames()
		_apply_visual_scale()


func _ready() -> void:
	add_to_group("enemies")

	if enemy_kind == "":
		base_damage = damage
		base_speed = speed
		base_contact_radius = contact_radius
		_choose_enemy_kind()
		_apply_kind_behavior()

	hp = max_hp

	_create_sprite()
	_load_visual_frames()
	_apply_visual_scale()

	queue_redraw()


func _physics_process(delta: float) -> void:
	visual_time += delta

	if dead:
		_update_particles(delta)
		_update_impact_rings(delta)
		_update_attack_release_bursts(delta)
		_update_death_animation(delta)
		queue_redraw()
		return

	hit_flash = maxf(0.0, hit_flash - delta)
	attack_cooldown_timer = maxf(0.0, attack_cooldown_timer - delta)

	_update_hit_reaction(delta)
	_update_status_effects(delta)

	if not target:
		target = get_tree().get_first_node_in_group("player") as Node2D

	_update_attack_state(delta)
	_update_movement()
	_update_sprite_frame()
	_update_particles(delta)
	_update_impact_rings(delta)
	_update_attack_release_bursts(delta)

	queue_redraw()


func take_damage(amount: float, source_position: Vector2 = Vector2.ZERO, hit_kind: String = "hit") -> void:
	if dead:
		return

	hp -= amount
	hit_flash = 0.16
	hit_reaction_kind = hit_kind

	var hit_direction := _get_hit_direction(source_position)
	_start_hit_reaction(amount, hit_direction, hit_kind)
	_spawn_hit_particles(hit_kind, hit_direction)
	_spawn_impact_ring(hit_kind, hit_direction)

	if hp <= 0.0:
		_start_death_animation()


func _choose_enemy_kind() -> void:
	if enemy_role.strip_edges() == "":
		var options: Array[String] = []

		match enemy_rank:
			"elite":
				options = ["vestibule_bailiff", "gate_warden", "cinder_scribe"]
			"miniboss":
				options = ["threshold_proctor"]
			"boss":
				options = ["intake_magistrate"]
			_:
				options = ["ash_wretch", "gate_warden", "cinder_scribe", "bell_hound"]

		if options.is_empty():
			enemy_role = "ash_wretch"
		else:
			enemy_role = options[randi() % options.size()]

	enemy_kind = _get_asset_kind_for_role(enemy_role)
	enemy_display_name = _get_display_name_for_role(enemy_role)


func set_enemy_role(new_role: String) -> void:
	enemy_role = new_role.strip_edges()
	enemy_display_name = ""
	_choose_enemy_kind()
	_apply_kind_behavior()

	if sprite != null:
		_load_visual_frames()
		_apply_visual_scale()


func _get_asset_kind_for_role(role: String) -> String:
	match role:
		"ash_wretch":
			return "imp"
		"gate_warden":
			return "masked_orc"
		"cinder_scribe":
			return "skelet"
		"bell_hound":
			return "goblin"
		"vestibule_bailiff", "threshold_proctor", "intake_magistrate":
			return "chort"
		_:
			return "imp"


func _get_sprite_role_key_for_role(role: String) -> String:
	match role:
		"threshold_proctor", "intake_magistrate":
			return "vestibule_bailiff"
		_:
			return role


func _get_display_name_for_role(role: String) -> String:
	match role:
		"ash_wretch":
			return "Ash Wretch"
		"gate_warden":
			return "Gate Warden"
		"cinder_scribe":
			return "Cinder Scribe"
		"bell_hound":
			return "Bell Hound"
		"vestibule_bailiff":
			return "Vestibule Bailiff"
		"threshold_proctor":
			return "Threshold Proctor"
		"intake_magistrate":
			return "Intake Magistrate"
		_:
			return "Ash Wretch"


func _get_role_color() -> Color:
	match enemy_role:
		"ash_wretch":
			return Color("#b8a89a")
		"gate_warden":
			return Color("#d07a52")
		"cinder_scribe":
			return Color("#d7b16f")
		"bell_hound":
			return Color("#c95a3d")
		"vestibule_bailiff":
			return Color("#b49ce2")
		"threshold_proctor":
			return Color("#f0a15f")
		"intake_magistrate":
			return Color("#ff5b37")
		_:
			return Color("#d64a2f")


func _apply_kind_behavior() -> void:
	damage = base_damage
	speed = base_speed
	contact_radius = base_contact_radius

	attack_style = "circle"
	current_attack_style = attack_style
	attack_range = maxf(contact_radius + 12.0, 42.0)
	attack_width = 24.0
	attack_angle_width = 0.75
	attack_lunge_distance = 52.0
	attack_windup_time = 0.55
	attack_recover_time = 0.22
	scribe_mark_position = global_position

	match enemy_role:
		"ash_wretch":
			# Processed soul residue. Fragile pressure enemy.
			enemy_kind = "imp"
			max_hp *= 0.82
			hp = minf(hp, max_hp)
			attack_style = "pounce"
			speed *= 1.08
			damage *= 0.82
			contact_radius *= 0.92
			attack_range = 58.0
			attack_width = 17.0
			attack_lunge_distance = 50.0
			attack_windup_time = 0.34
			attack_recover_time = 0.16

		"gate_warden":
			# Institutional guard. Slow, readable, and punishing.
			enemy_kind = "masked_orc"
			max_hp *= 1.30
			hp = minf(hp, max_hp)
			attack_style = "cone"
			speed *= 0.72
			damage *= 1.32
			contact_radius *= 1.14
			attack_range = 84.0
			attack_angle_width = 0.86
			attack_windup_time = 0.88
			attack_recover_time = 0.42

		"cinder_scribe":
			# Bureaucrat of punishment. Marks the floor before judgment lands.
			enemy_kind = "skelet"
			max_hp *= 0.95
			hp = minf(hp, max_hp)
			attack_style = "scribe_mark"
			speed *= 0.64
			damage *= 1.05
			contact_radius *= 0.92
			attack_range = 240.0
			attack_width = 74.0
			attack_windup_time = 0.92
			attack_recover_time = 0.48

		"bell_hound":
			# Pursuit function. Punishes retreat and indecision.
			enemy_kind = "goblin"
			max_hp *= 0.92
			hp = minf(hp, max_hp)
			attack_style = "pounce"
			speed *= 1.38
			damage *= 0.96
			attack_range = 74.0
			attack_width = 20.0
			attack_lunge_distance = 76.0
			attack_windup_time = 0.30
			attack_recover_time = 0.24

		"vestibule_bailiff":
			# Elite judgment officer. Reads like law enforcement, not random evil.
			enemy_kind = "chort"
			max_hp *= 1.55
			hp = minf(hp, max_hp)
			attack_style = "bailiff_random"
			speed *= 0.86
			damage *= 1.48
			contact_radius *= 1.22
			attack_range = 96.0
			attack_width = 32.0
			attack_angle_width = 0.92
			attack_lunge_distance = 62.0
			attack_windup_time = 0.82
			attack_recover_time = 0.44

		"threshold_proctor":
			# Miniboss officer guarding the first formal threshold.
			enemy_kind = "chort"
			max_hp *= 1.90
			hp = minf(hp, max_hp)
			attack_style = "threshold_proctor_cycle"
			speed *= 0.78
			damage *= 1.62
			contact_radius *= 1.28
			attack_range = 118.0
			attack_width = 36.0
			attack_angle_width = 0.96
			attack_lunge_distance = 70.0
			attack_windup_time = 0.88
			attack_recover_time = 0.48

		"intake_magistrate":
			# Circle 0 boss. A lawful intake authority trying to halt the unauthorized descent.
			enemy_kind = "chort"
			max_hp *= 1.38
			hp = minf(hp, max_hp)
			attack_style = "intake_magistrate_cycle"
			speed *= 0.74
			damage *= 1.18
			contact_radius *= 1.34
			attack_range = 138.0
			attack_width = 42.0
			attack_angle_width = 1.02
			attack_lunge_distance = 78.0
			attack_windup_time = 0.98
			attack_recover_time = 0.54

		_:
			match enemy_kind:
				"imp":
					attack_style = "pounce"
					speed *= 1.16
					damage *= 0.90
					attack_range = 62.0
					attack_width = 18.0
					attack_lunge_distance = 58.0
					attack_windup_time = 0.38
					attack_recover_time = 0.18
				"goblin":
					attack_style = "cone"
					attack_range = 54.0
					attack_angle_width = 0.70
					attack_windup_time = 0.50
					attack_recover_time = 0.22
				"skelet":
					attack_style = "line"
					speed *= 0.82
					damage *= 1.05
					attack_range = 150.0
					attack_width = 22.0
					attack_windup_time = 0.82
					attack_recover_time = 0.34
				"chort":
					attack_style = "circle"
					speed *= 1.04
					damage *= 1.20
					attack_range = 66.0
					attack_windup_time = 0.64
					attack_recover_time = 0.28
				"masked_orc":
					attack_style = "cone"
					speed *= 0.92
					damage *= 1.38
					attack_range = 76.0
					attack_angle_width = 0.85
					attack_windup_time = 0.78
					attack_recover_time = 0.36
				"big_zombie":
					attack_style = "circle"
					speed *= 0.70
					damage *= 1.55
					attack_range = 86.0
					attack_windup_time = 0.96
					attack_recover_time = 0.46
				"ogre":
					attack_style = "circle"
					speed *= 0.66
					damage *= 1.78
					attack_range = 102.0
					attack_windup_time = 1.10
					attack_recover_time = 0.52
				"big_demon":
					attack_style = "boss_random"
					speed *= 0.74
					damage *= 1.90
					attack_range = 112.0
					attack_width = 30.0
					attack_angle_width = 0.90
					attack_windup_time = 1.00
					attack_recover_time = 0.56

	if enemy_rank == "elite" and enemy_role != "vestibule_bailiff":
		max_hp *= 1.20
		damage *= 1.12
		attack_windup_time *= 0.95

	# This function is only used at spawn/setup time; fill the adjusted role HP.
	hp = max_hp
	current_attack_style = attack_style


func _prepare_current_attack_style() -> void:
	current_attack_style = attack_style

	if enemy_role == "intake_magistrate" or attack_style == "intake_magistrate_cycle":
		boss_phase = _get_boss_phase()
		var boss_roll := randi() % 4

		if boss_phase >= 3 and boss_roll == 0:
			current_attack_style = "scribe_mark"
			attack_range = 280.0
			attack_width = 92.0
			attack_windup_time = 0.96
			attack_recover_time = 0.46
		elif boss_roll == 1:
			current_attack_style = "line"
			attack_range = 230.0
			attack_width = 42.0
			attack_windup_time = 1.02
			attack_recover_time = 0.54
		elif boss_roll == 2:
			current_attack_style = "cone"
			attack_range = 148.0
			attack_angle_width = 1.10
			attack_windup_time = 0.92
			attack_recover_time = 0.50
		else:
			current_attack_style = "circle"
			attack_range = 128.0 + float(boss_phase) * 12.0
			attack_windup_time = 1.04
			attack_recover_time = 0.58

		return

	if enemy_role == "threshold_proctor" or attack_style == "threshold_proctor_cycle":
		var proctor_roll := randi() % 3

		if proctor_roll == 0:
			current_attack_style = "cone"
			attack_range = 124.0
			attack_angle_width = 0.98
			attack_windup_time = 0.86
			attack_recover_time = 0.46
		elif proctor_roll == 1:
			current_attack_style = "line"
			attack_range = 188.0
			attack_width = 36.0
			attack_windup_time = 0.96
			attack_recover_time = 0.50
		else:
			current_attack_style = "circle"
			attack_range = 112.0
			attack_windup_time = 0.92
			attack_recover_time = 0.48

		return

	if enemy_role == "vestibule_bailiff" or attack_style == "bailiff_random":
		var roll := randi() % 3

		if roll == 0:
			current_attack_style = "circle"
			attack_range = 94.0
			attack_windup_time = 0.82
			attack_recover_time = 0.44
		elif roll == 1:
			current_attack_style = "cone"
			attack_range = 104.0
			attack_angle_width = 0.92
			attack_windup_time = 0.78
			attack_recover_time = 0.42
		else:
			current_attack_style = "line"
			attack_range = 168.0
			attack_width = 32.0
			attack_windup_time = 0.90
			attack_recover_time = 0.46

		return

	if enemy_kind != "big_demon":
		return

	var big_demon_roll := randi() % 3

	if big_demon_roll == 0:
		current_attack_style = "circle"
		attack_range = 112.0
		attack_windup_time = 1.00
		attack_recover_time = 0.56
	elif big_demon_roll == 1:
		current_attack_style = "cone"
		attack_range = 122.0
		attack_angle_width = 0.95
		attack_windup_time = 0.92
		attack_recover_time = 0.48
	else:
		current_attack_style = "line"
		attack_range = 190.0
		attack_width = 34.0
		attack_windup_time = 1.05
		attack_recover_time = 0.58


func _get_boss_phase() -> int:
	if max_hp <= 0.01:
		return 1

	var hp_ratio: float = clampf(hp / max_hp, 0.0, 1.0)

	if hp_ratio <= 0.34:
		return 3

	if hp_ratio <= 0.67:
		return 2

	return 1


func _update_attack_state(delta: float) -> void:
	if target == null:
		return

	if attack_state == "windup":
		attack_timer -= delta

		if attack_timer <= 0.0:
			_release_attack()

		return

	if attack_state == "recover":
		attack_timer -= delta

		if attack_timer <= 0.0:
			attack_state = "ready"
			attack_cooldown_timer = _get_attack_cooldown()

		return

	if attack_state != "ready":
		return

	if attack_cooldown_timer > 0.0:
		return

	var distance_to_target: float = global_position.distance_to(target.global_position)

	if distance_to_target <= attack_range:
		_start_attack_windup()


func _start_attack_windup() -> void:
	_prepare_current_attack_style()

	attack_state = "windup"
	attack_timer = attack_windup_time

	attack_origin_position = global_position

	if target != null:
		attack_target_position = target.global_position
		attack_direction = attack_target_position - global_position
	else:
		attack_target_position = global_position
		attack_direction = Vector2.RIGHT

	if attack_direction.length() <= 0.01:
		attack_direction = Vector2.RIGHT
	else:
		attack_direction = attack_direction.normalized()

	if current_attack_style == "scribe_mark":
		scribe_mark_position = attack_target_position

	_spawn_windup_warning_particles()

	if enemy_role == "intake_magistrate" or enemy_role == "threshold_proctor":
		_spawn_windup_warning_particles()


func _release_attack() -> void:
	if current_attack_style == "pounce":
		global_position += attack_direction * attack_lunge_distance

	_spawn_attack_release_burst()
	_spawn_attack_particles()

	if _does_current_attack_hit_target():
		if target != null and target.has_method("take_damage"):
			target.take_damage(damage, global_position)

	attack_state = "recover"
	attack_timer = attack_recover_time


func _does_current_attack_hit_target() -> bool:
	if target == null:
		return false

	var to_target: Vector2 = target.global_position - global_position

	match current_attack_style:
		"pounce":
			return target.global_position.distance_to(global_position) <= 42.0

		"cone":
			return _is_target_in_cone(target.global_position, attack_origin_position, attack_direction, attack_range, attack_angle_width)

		"line":
			return _is_target_in_line(target.global_position, attack_origin_position, attack_direction, attack_range, attack_width)

		"circle":
			return target.global_position.distance_to(attack_origin_position) <= attack_range

		"scribe_mark":
			return target.global_position.distance_to(scribe_mark_position) <= attack_width

		_:
			return to_target.length() <= attack_range


func _is_target_in_cone(
	target_position: Vector2,
	origin_position: Vector2,
	direction: Vector2,
	range_value: float,
	angle_width: float
) -> bool:
	var to_target: Vector2 = target_position - origin_position

	if to_target.length() > range_value:
		return false

	if to_target.length() <= 1.0:
		return true

	var safe_direction := direction

	if safe_direction.length() <= 0.01:
		safe_direction = Vector2.RIGHT

	var dot_value: float = safe_direction.normalized().dot(to_target.normalized())
	var threshold: float = cos(angle_width)

	return dot_value >= threshold


func _is_target_in_line(
	target_position: Vector2,
	origin_position: Vector2,
	direction: Vector2,
	range_value: float,
	width_value: float
) -> bool:
	var safe_direction := direction

	if safe_direction.length() <= 0.01:
		safe_direction = Vector2.RIGHT

	safe_direction = safe_direction.normalized()

	var to_target: Vector2 = target_position - origin_position
	var forward_distance: float = to_target.dot(safe_direction)

	if forward_distance < 0.0:
		return false

	if forward_distance > range_value:
		return false

	var closest_point: Vector2 = origin_position + safe_direction * forward_distance
	var side_distance: float = target_position.distance_to(closest_point)

	return side_distance <= width_value


func _update_movement() -> void:
	if target == null:
		velocity = Vector2.ZERO
		return

	if attack_state == "windup":
		velocity = Vector2.ZERO
		return

	if attack_state == "recover":
		velocity = Vector2.ZERO
		return

	var dir: Vector2 = target.global_position - global_position
	var desired_stop_distance: float = attack_range * 0.72

	if enemy_role == "intake_magistrate":
		desired_stop_distance = 118.0
	elif enemy_role == "threshold_proctor":
		desired_stop_distance = 104.0
	elif current_attack_style == "line" or attack_style == "line":
		desired_stop_distance = attack_range * 0.62
	elif current_attack_style == "scribe_mark" or attack_style == "scribe_mark":
		desired_stop_distance = 168.0

	if dir.length() > desired_stop_distance:
		velocity = dir.normalized() * speed
		move_and_slide()
		_update_facing(dir)
	else:
		velocity = Vector2.ZERO


func _create_sprite() -> void:
	sprite = get_node_or_null("Sprite") as Sprite2D

	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)

	sprite.centered = true
	sprite.position = Vector2(0, -8)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 5
	sprite.z_as_relative = true
	sprite.visible = true


func _load_visual_frames() -> void:
	idle_frames.clear()
	run_frames.clear()
	circle0_direction_frames.clear()
	circle0_uses_role_sprite = false

	if _load_circle0_role_frames(enemy_role):
		circle0_uses_role_sprite = true
		return

	_load_frames_for_kind(enemy_kind)

	if idle_frames.is_empty() and run_frames.is_empty():
		push_warning("Enemy kind missing textures, falling back: %s" % enemy_kind)

		match enemy_rank:
			"elite":
				_load_frames_for_kind("chort")
			"miniboss":
				_load_frames_for_kind("big_zombie")
			"boss":
				_load_frames_for_kind("big_demon")
			_:
				_load_frames_for_kind("imp")


func _load_circle0_role_frames(role: String) -> bool:
	var role_key: String = _get_sprite_role_key_for_role(role.strip_edges())

	if role_key == "":
		return false

	var loaded_frames: Dictionary = {}

	for direction in CIRCLE0_SPRITE_DIRECTIONS:
		var direction_frames: Array[Texture2D] = []

		for frame_index in range(1, 5):
			var path: String = "%s/%s/%s_%s_%02d.png" % [CIRCLE0_ENEMY_SPRITE_ROOT, role_key, role_key, direction, frame_index]

			if not ResourceLoader.exists(path):
				return false

			var texture: Texture2D = load(path) as Texture2D

			if texture == null:
				return false

			direction_frames.append(texture)

		loaded_frames[direction] = direction_frames

	circle0_direction_frames = loaded_frames
	return circle0_direction_frames.size() == CIRCLE0_SPRITE_DIRECTIONS.size()


func _load_frames_for_kind(kind: String) -> void:
	var base_path: String = _get_kind_asset_base_path(kind)
	var prefix: String = _get_kind_asset_prefix(kind)

	if base_path == "" or prefix == "":
		return

	if idle_frames.is_empty():
		for i in range(4):
			_try_append_texture(
				idle_frames,
				"%s/%s_idle_anim_f%d.png" % [base_path, prefix, i]
			)

	if run_frames.is_empty():
		for i in range(4):
			_try_append_texture(
				run_frames,
				"%s/%s_run_anim_f%d.png" % [base_path, prefix, i]
			)


func _try_append_texture(target_array: Array[Texture2D], path: String) -> void:
	if not ResourceLoader.exists(path):
		return

	var texture := load(path) as Texture2D

	if texture != null:
		target_array.append(texture)


func _get_kind_asset_base_path(kind: String) -> String:
	match kind:
		"imp":
			return "res://art/enemies/imp"
		"goblin":
			return "res://art/enemies/goblin"
		"skelet":
			return "res://art/enemies/skelet"
		"chort":
			return "res://art/enemies/chort"
		"masked_orc":
			return "res://art/enemies/masked_orc"
		"big_zombie":
			return "res://art/enemies/big_zombie"
		"ogre":
			return "res://art/enemies/ogre"
		"big_demon":
			return "res://art/bosses/big_demon"
		_:
			return ""


func _get_kind_asset_prefix(kind: String) -> String:
	return kind


func _apply_visual_scale() -> void:
	if sprite == null:
		return

	if circle0_uses_role_sprite:
		match enemy_role:
			"ash_wretch":
				sprite.scale = Vector2(0.30, 0.30)
				sprite.position = Vector2(0, -8)

			"bell_hound":
				sprite.scale = Vector2(0.29, 0.29)
				sprite.position = Vector2(0, -9)

			"cinder_scribe":
				sprite.scale = Vector2(0.29, 0.29)
				sprite.position = Vector2(0, -12)

			"gate_warden":
				sprite.scale = Vector2(0.30, 0.30)
				sprite.position = Vector2(0, -11)

			"vestibule_bailiff":
				sprite.scale = Vector2(0.32, 0.32)
				sprite.position = Vector2(0, -14)

			"threshold_proctor":
				sprite.scale = Vector2(0.36, 0.36)
				sprite.position = Vector2(0, -16)

			"intake_magistrate":
				sprite.scale = Vector2(0.40, 0.40)
				sprite.position = Vector2(0, -18)

			_:
				sprite.scale = Vector2(0.30, 0.30)
				sprite.position = Vector2(0, -10)

		base_sprite_scale = sprite.scale
		base_sprite_position = sprite.position
		return

	match enemy_kind:
		"imp":
			sprite.scale = Vector2(2.7, 2.7)
			sprite.position = Vector2(0, -8)

		"goblin":
			sprite.scale = Vector2(2.8, 2.8)
			sprite.position = Vector2(0, -8)

		"skelet":
			sprite.scale = Vector2(2.9, 2.9)
			sprite.position = Vector2(0, -9)

		"chort":
			sprite.scale = Vector2(3.0, 3.0)
			sprite.position = Vector2(0, -10)

		"masked_orc":
			sprite.scale = Vector2(3.0, 3.0)
			sprite.position = Vector2(0, -10)

		"big_zombie":
			sprite.scale = Vector2(3.3, 3.3)
			sprite.position = Vector2(0, -12)

		"ogre":
			sprite.scale = Vector2(3.5, 3.5)
			sprite.position = Vector2(0, -14)

		"big_demon":
			sprite.scale = Vector2(4.1, 4.1)
			sprite.position = Vector2(0, -18)

		_:
			sprite.scale = Vector2(2.7, 2.7)
			sprite.position = Vector2(0, -8)

	base_sprite_scale = sprite.scale
	base_sprite_position = sprite.position


func _update_sprite_frame() -> void:
	if sprite == null:
		return

	var selected_frames: Array[Texture2D] = _get_current_animation_frames()

	if selected_frames.is_empty():
		sprite.texture = null
		return

	var frame_index: int = 0

	if circle0_uses_role_sprite:
		# The generated Circle 0 sheets are expressive, but not perfectly hand-animated.
		# Keep them stable: idle uses frame 1, movement animates slowly, windup/recover animates even slower.
		var circle0_fps: float = 0.0

		if velocity.length() > 4.0:
			circle0_fps = 4.0

		if attack_state == "windup" or attack_state == "recover":
			circle0_fps = 2.5

		if selected_frames.size() > 1 and circle0_fps > 0.0:
			frame_index = int(visual_time * circle0_fps) % selected_frames.size()
	else:
		var fps: float = 7.0

		if velocity.length() > 4.0:
			fps = 9.0

		if attack_state == "windup":
			fps = 5.0

		if enemy_rank == "boss":
			fps *= 0.82

		frame_index = int(visual_time * fps) % selected_frames.size()

	sprite.texture = selected_frames[frame_index]
	sprite.modulate = _get_sprite_modulate()
	_apply_sprite_reaction_transform()


func _get_hit_direction(source_position: Vector2) -> Vector2:
	var direction := Vector2.RIGHT

	if source_position != Vector2.ZERO:
		direction = global_position - source_position
	elif target != null:
		direction = global_position - target.global_position

	if direction.length() <= 0.01:
		if sprite != null and sprite.flip_h:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT

	return direction.normalized()


func _start_hit_reaction(amount: float, hit_direction: Vector2, hit_kind: String) -> void:
	hit_reaction_timer = hit_reaction_duration
	hit_reaction_direction = hit_direction

	var strength := 7.0

	match hit_kind:
		"light", "light_1":
			strength = 6.0
		"light_2":
			strength = 7.0
		"light_3":
			strength = 9.0
		"heavy":
			strength = 12.0
		"q":
			strength = 10.0
		"ultimate":
			strength = 16.0
		_:
			strength = 7.0

	if enemy_rank == "elite":
		strength *= 1.08
	elif enemy_rank == "miniboss":
		strength *= 1.18
	elif enemy_rank == "boss":
		strength *= 1.30

	strength += clampf(amount * 0.05, 0.0, 6.0)
	hit_reaction_strength = strength


func _update_hit_reaction(delta: float) -> void:
	if hit_reaction_timer <= 0.0:
		return

	hit_reaction_timer = maxf(0.0, hit_reaction_timer - delta)


func _apply_sprite_reaction_transform() -> void:
	if sprite == null:
		return

	if death_started:
		return

	var pos := base_sprite_position
	var scale_value := base_sprite_scale

	if attack_state == "windup":
		var windup_progress: float = 1.0 - clampf(attack_timer / maxf(attack_windup_time, 0.01), 0.0, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(visual_time * 24.0)
		scale_value *= Vector2(1.0 + 0.05 * windup_progress, 1.0 - 0.035 * windup_progress)
		pos += -attack_direction * (2.0 + windup_progress * 5.0)
		pos.y += pulse * 1.4

	if hit_reaction_timer > 0.0:
		var t: float = clampf(hit_reaction_timer / hit_reaction_duration, 0.0, 1.0)
		var pop: float = sin(t * PI)
		var shake: float = sin(visual_time * 70.0) * 1.7 * t

		pos += hit_reaction_direction * hit_reaction_strength * t
		pos += Vector2(shake, -pop * 2.0)

		scale_value *= Vector2(1.0 + 0.12 * pop, 1.0 - 0.10 * pop)

	sprite.position = pos
	sprite.scale = scale_value


func _get_current_animation_frames() -> Array[Texture2D]:
	if circle0_uses_role_sprite:
		var direction: String = _get_circle0_sprite_direction()
		var direction_frames: Array[Texture2D] = _get_circle0_direction_frames(direction)

		if not direction_frames.is_empty():
			return direction_frames

	if attack_state == "windup":
		if not idle_frames.is_empty():
			return idle_frames

	if velocity.length() > 4.0 and not run_frames.is_empty():
		return run_frames

	if not idle_frames.is_empty():
		return idle_frames

	return run_frames


func _get_circle0_direction_frames(direction: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []

	if not circle0_direction_frames.has(direction):
		return result

	var raw_frames: Variant = circle0_direction_frames[direction]

	if not raw_frames is Array:
		return result

	for item in raw_frames:
		if item is Texture2D:
			result.append(item as Texture2D)

	return result


func _get_circle0_sprite_direction() -> String:
	var facing_vector: Vector2 = Vector2.ZERO

	if attack_state == "windup" or attack_state == "recover":
		facing_vector = attack_direction
	elif velocity.length() > 4.0:
		facing_vector = velocity
	elif target != null:
		facing_vector = target.global_position - global_position

	if facing_vector.length() <= 0.01:
		return "down"

	if absf(facing_vector.x) > absf(facing_vector.y):
		if facing_vector.x >= 0.0:
			return "right"

		return "left"

	if facing_vector.y >= 0.0:
		return "down"

	return "up"


func _update_facing(dir: Vector2) -> void:
	if sprite == null:
		return

	if circle0_uses_role_sprite:
		sprite.flip_h = false
		return

	if absf(dir.x) < 1.0:
		return

	sprite.flip_h = dir.x < 0.0


	if absf(dir.x) < 1.0:
		return

	sprite.flip_h = dir.x < 0.0


func _get_sprite_modulate() -> Color:
	if death_started:
		var death_progress: float = 1.0 - clampf(death_timer / death_duration, 0.0, 1.0)
		return Color(1.0, 0.55 + death_progress * 0.25, 0.45, 1.0 - death_progress * 0.75)

	if hit_flash > 0.0:
		return Color.WHITE

	if attack_state == "windup":
		var pulse: float = 0.5 + 0.5 * sin(visual_time * 22.0)
		var role_color: Color = _get_role_color()
		return Color(
			minf(1.35, role_color.r + 0.30 + pulse * 0.18),
			minf(1.15, role_color.g + 0.14 + pulse * 0.08),
			minf(1.10, role_color.b + 0.08),
			1.0
		)

	match enemy_role:
		"ash_wretch":
			return Color(1.02, 0.93, 0.84, 1.0)
		"gate_warden":
			return Color(1.15, 0.78, 0.58, 1.0)
		"cinder_scribe":
			return Color(1.18, 1.02, 0.72, 1.0)
		"bell_hound":
			return Color(1.12, 0.62, 0.46, 1.0)
		"vestibule_bailiff":
			return Color(1.10, 0.86, 1.24, 1.0)
		_:
			match enemy_kind:
				"imp":
					return Color(0.96, 0.88, 0.82, 1.0)
				"goblin":
					return Color(0.86, 1.05, 0.78, 1.0)
				"skelet":
					return Color(1.10, 1.04, 0.92, 1.0)
				"chort":
					return Color(1.10, 0.88, 1.20, 1.0)
				"masked_orc":
					return Color(0.95, 1.10, 0.92, 1.0)
				"big_zombie":
					return Color(1.16, 0.88, 0.72, 1.0)
				"ogre":
					return Color(1.20, 0.92, 0.70, 1.0)
				"big_demon":
					return Color(1.24, 0.62, 0.52, 1.0)
				_:
					return Color.WHITE


func _get_attack_cooldown() -> float:
	match enemy_role:
		"ash_wretch":
			return 0.58
		"gate_warden":
			return 1.18
		"cinder_scribe":
			return 1.24
		"bell_hound":
			return 0.66
		"vestibule_bailiff":
			return 1.04
		"threshold_proctor":
			return 1.02
		"intake_magistrate":
			return 0.92 if _get_boss_phase() >= 3 else 1.12
		_:
			match enemy_kind:
				"imp":
					return 0.70
				"goblin":
					return 0.82
				"skelet":
					return 1.00
				"chort":
					return 0.92
				"masked_orc":
					return 1.06
				"big_zombie":
					return 1.22
				"ogre":
					return 1.34
				"big_demon":
					return 1.38
				_:
					return 0.85


func _get_hp_color() -> Color:
	if enemy_role != "":
		return _get_role_color()

	match enemy_rank:
		"elite":
			return Color("#b49ce2")
		"miniboss":
			return Color("#ff9f4a")
		"boss":
			return Color("#ff2b1f")
		_:
			return Color("#d64a2f")


func _get_bar_y() -> float:
	match enemy_role:
		"intake_magistrate":
			return -78.0
		"threshold_proctor":
			return -62.0

	match enemy_kind:
		"big_demon":
			return -84.0
		"ogre":
			return -62.0
		"big_zombie":
			return -58.0
		"chort", "masked_orc":
			return -48.0
		"skelet":
			return -44.0
		_:
			return -40.0


func _get_bar_width() -> float:
	match enemy_role:
		"intake_magistrate":
			return 110.0
		"threshold_proctor":
			return 82.0

	match enemy_kind:
		"big_demon":
			return 96.0
		"ogre":
			return 70.0
		"big_zombie":
			return 66.0
		"chort", "masked_orc":
			return 56.0
		_:
			return 46.0


func _draw() -> void:
	_draw_shadow()
	_draw_attack_prediction()
	_draw_attack_release_bursts()
	_draw_impact_rings()
	_draw_particles()
	_draw_hp_bar()
	_draw_status_indicators()
	_draw_rank_label()

	if death_started:
		_draw_death_overlay()

	if sprite == null:
		_draw_fallback_body()
		return

	if sprite.texture == null:
		_draw_fallback_body()
		return


func _draw_shadow() -> void:
	var shadow_width: float = 44.0
	var shadow_height: float = 12.0

	if circle0_uses_role_sprite:
		match enemy_role:
			"ash_wretch":
				shadow_width = 44.0
				shadow_height = 12.0
			"bell_hound":
				shadow_width = 58.0
				shadow_height = 14.0
			"cinder_scribe":
				shadow_width = 46.0
				shadow_height = 13.0
			"gate_warden":
				shadow_width = 58.0
				shadow_height = 15.0
			"vestibule_bailiff":
				shadow_width = 66.0
				shadow_height = 17.0
			"threshold_proctor":
				shadow_width = 74.0
				shadow_height = 19.0
			"intake_magistrate":
				shadow_width = 88.0
				shadow_height = 22.0
			_:
				shadow_width = 48.0
				shadow_height = 13.0
	else:
		match enemy_kind:
			"big_demon":
				shadow_width = 96.0
				shadow_height = 24.0
			"ogre":
				shadow_width = 72.0
				shadow_height = 18.0
			"big_zombie":
				shadow_width = 66.0
				shadow_height = 16.0
			"chort", "masked_orc":
				shadow_width = 54.0
				shadow_height = 14.0

	var points := PackedVector2Array()
	var center := Vector2(0, 14)
	var steps := 28

	for i in range(steps):
		var angle := TAU * float(i) / float(steps)
		points.append(
			center + Vector2(
				cos(angle) * shadow_width * 0.5,
				sin(angle) * shadow_height * 0.5
			)
		)

	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.30))


func _draw_attack_prediction() -> void:
	if attack_state != "windup":
		return

	var safe_windup_time: float = maxf(attack_windup_time, 0.01)
	var progress: float = 1.0 - clampf(attack_timer / safe_windup_time, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(visual_time * 26.0)

	_draw_windup_body_warning(progress, pulse)

	match current_attack_style:
		"pounce":
			_draw_pounce_prediction(progress, pulse)
		"cone":
			_draw_cone_prediction(progress, pulse)
		"line":
			_draw_line_prediction(progress, pulse)
		"circle":
			_draw_circle_prediction(progress, pulse)
		"scribe_mark":
			_draw_scribe_mark_prediction(progress, pulse)
		_:
			_draw_circle_prediction(progress, pulse)


func _draw_windup_body_warning(progress: float, pulse: float) -> void:
	var rank_mult := 1.0

	if enemy_rank == "elite":
		rank_mult = 1.12
	elif enemy_rank == "miniboss":
		rank_mult = 1.28
	elif enemy_rank == "boss":
		rank_mult = 1.55

	var radius := (24.0 + progress * 12.0 + pulse * 4.0) * rank_mult
	var alpha := 0.16 + progress * 0.22 + pulse * 0.08
	var warning_color := Color(1.0, 0.13, 0.06, alpha)
	var hot_color := Color(1.0, 0.78, 0.32, 0.46 + progress * 0.28)

	draw_circle(Vector2(0, -10), radius * 0.70, Color(1.0, 0.08, 0.04, 0.08 + progress * 0.14))
	draw_arc(Vector2(0, -10), radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, hot_color, 3.0)
	draw_arc(Vector2(0, -10), radius + 5.0, 0.0, TAU, 48, warning_color, 1.5)

	for i in range(4):
		var angle := attack_direction.angle() + float(i) * TAU * 0.25 + visual_time * 2.4
		var inner := Vector2(0, -10) + Vector2.RIGHT.rotated(angle) * (radius - 7.0)
		var outer := Vector2(0, -10) + Vector2.RIGHT.rotated(angle) * (radius + 5.0)
		draw_line(inner, outer, Color(1.0, 0.70, 0.26, 0.36 + progress * 0.28), 2.0)


func _draw_circle_prediction(progress: float, pulse: float) -> void:
	var danger_alpha: float = 0.13 + progress * 0.28
	var ring_alpha: float = 0.58 + progress * 0.32 + pulse * 0.10
	var ready_radius: float = lerpf(attack_range * 0.35, attack_range, progress)

	draw_circle(Vector2.ZERO, attack_range, Color(1.0, 0.08, 0.035, danger_alpha))
	draw_circle(Vector2.ZERO, ready_radius, Color(1.0, 0.26, 0.08, 0.06 + progress * 0.13))
	draw_arc(Vector2.ZERO, attack_range, -PI * 0.5, (-PI * 0.5) + TAU * progress, 72, Color(1.0, 0.86, 0.36, ring_alpha), 4.5)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 72, Color(1.0, 0.12, 0.06, 0.50 + pulse * 0.12), 2.0)
	draw_arc(Vector2.ZERO, ready_radius, 0.0, TAU, 48, Color(1.0, 0.44, 0.16, 0.28 + progress * 0.16), 2.0)

	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var p1 := Vector2.RIGHT.rotated(angle) * (attack_range - 8.0)
		var p2 := Vector2.RIGHT.rotated(angle) * (attack_range + 7.0)
		draw_line(p1, p2, Color(1.0, 0.72, 0.25, 0.38 + progress * 0.24), 2.0)


func _draw_cone_prediction(progress: float, pulse: float) -> void:
	var local_dir: Vector2 = attack_direction

	if local_dir.length() <= 0.01:
		local_dir = Vector2.RIGHT

	var start_angle: float = local_dir.angle() - attack_angle_width
	var end_angle: float = local_dir.angle() + attack_angle_width
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)

	var steps := 28
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(Vector2.RIGHT.rotated(angle) * attack_range)

	draw_colored_polygon(points, Color(1.0, 0.08, 0.035, 0.12 + progress * 0.25))
	draw_arc(Vector2.ZERO, attack_range, start_angle, end_angle, 42, Color(1.0, 0.72, 0.25, 0.52 + progress * 0.32), 4.0)
	draw_arc(Vector2.ZERO, attack_range * (0.58 + progress * 0.42), start_angle, end_angle, 34, Color(1.0, 0.20, 0.07, 0.34 + pulse * 0.10), 2.5)
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(start_angle) * attack_range, Color(1.0, 0.18, 0.08, 0.58), 2.5)
	draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(end_angle) * attack_range, Color(1.0, 0.18, 0.08, 0.58), 2.5)
	draw_line(Vector2.ZERO, local_dir.normalized() * attack_range, Color(1.0, 0.86, 0.42, 0.36 + progress * 0.24), 2.0)

	for i in range(3):
		var lane_t := -0.5 + float(i) * 0.5
		var lane_angle := local_dir.angle() + lane_t * attack_angle_width
		var lane_end := Vector2.RIGHT.rotated(lane_angle) * attack_range * (0.70 + 0.30 * progress)
		draw_line(Vector2.ZERO, lane_end, Color(1.0, 0.38, 0.14, 0.18 + pulse * 0.12), 1.5)


func _draw_line_prediction(progress: float, pulse: float) -> void:
	var safe_dir := attack_direction

	if safe_dir.length() <= 0.01:
		safe_dir = Vector2.RIGHT

	safe_dir = safe_dir.normalized()

	var end_point: Vector2 = safe_dir * attack_range
	var side := safe_dir.orthogonal().normalized()
	var half_width := attack_width * 0.5
	var beam_points := PackedVector2Array([
		side * half_width,
		end_point + side * half_width,
		end_point - side * half_width,
		-side * half_width
	])

	draw_colored_polygon(beam_points, Color(1.0, 0.07, 0.035, 0.14 + progress * 0.26))
	draw_line(side * half_width, end_point + side * half_width, Color(1.0, 0.76, 0.30, 0.48 + progress * 0.32), 2.5)
	draw_line(-side * half_width, end_point - side * half_width, Color(1.0, 0.76, 0.30, 0.48 + progress * 0.32), 2.5)
	draw_line(Vector2.ZERO, end_point, Color(1.0, 0.18, 0.08, 0.38 + pulse * 0.16), maxf(3.0, attack_width * 0.26))
	draw_circle(end_point, attack_width * 0.58, Color(1.0, 0.11, 0.05, 0.24 + progress * 0.25))
	draw_arc(end_point, attack_width * 0.68, 0.0, TAU, 32, Color(1.0, 0.78, 0.32, 0.46 + progress * 0.22), 2.0)

	for i in range(4):
		var lane_progress := fmod(progress + float(i) * 0.25, 1.0)
		var mark_center := safe_dir * attack_range * lane_progress
		draw_line(mark_center - side * (half_width + 5.0), mark_center + side * (half_width + 5.0), Color(1.0, 0.72, 0.28, 0.26 + pulse * 0.12), 1.5)


func _draw_pounce_prediction(progress: float, pulse: float) -> void:
	var safe_dir := attack_direction

	if safe_dir.length() <= 0.01:
		safe_dir = Vector2.RIGHT

	safe_dir = safe_dir.normalized()

	var end_point: Vector2 = safe_dir * attack_lunge_distance
	var line_color := Color(1.0, 0.12, 0.05, 0.18 + progress * 0.28)
	var edge_color := Color(1.0, 0.82, 0.36, 0.52 + progress * 0.34 + pulse * 0.08)
	var side := safe_dir.orthogonal().normalized()
	var half_width := attack_width * 0.55
	var body_points := PackedVector2Array([
		side * half_width,
		end_point + side * half_width * 0.75,
		end_point - side * half_width * 0.75,
		-side * half_width
	])

	draw_colored_polygon(body_points, line_color)
	draw_line(Vector2.ZERO, end_point, edge_color, 3.5)
	draw_line(side * half_width, end_point + side * half_width * 0.75, Color(1.0, 0.24, 0.10, 0.42), 2.0)
	draw_line(-side * half_width, end_point - side * half_width * 0.75, Color(1.0, 0.24, 0.10, 0.42), 2.0)
	draw_circle(end_point, 38.0, Color(1.0, 0.10, 0.04, 0.13 + progress * 0.25))
	draw_arc(end_point, 38.0, 0.0, TAU, 44, Color(1.0, 0.20, 0.08, 0.50 + progress * 0.22), 2.5)
	draw_arc(end_point, 25.0 + progress * 13.0, 0.0, TAU, 32, edge_color, 2.0)

	for i in range(3):
		var offset := (float(i) - 1.0) * 10.0
		var claw_center := end_point + side * offset
		draw_line(claw_center - safe_dir * 8.0, claw_center + safe_dir * 12.0, Color(1.0, 0.75, 0.28, 0.36 + progress * 0.30), 2.0)


func _draw_scribe_mark_prediction(progress: float, pulse: float) -> void:
	var local_center: Vector2 = scribe_mark_position - global_position
	var radius: float = attack_width
	var ready_radius: float = lerpf(radius * 0.38, radius, progress)
	var color: Color = _get_role_color()

	draw_circle(local_center, radius, Color(color.r, color.g * 0.8, color.b * 0.55, 0.12 + progress * 0.22))
	draw_circle(local_center, ready_radius, Color(1.0, 0.32, 0.08, 0.06 + progress * 0.14))
	draw_arc(local_center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 72, Color(1.0, 0.82, 0.34, 0.55 + progress * 0.32), 4.0)
	draw_arc(local_center, radius + 6.0 + pulse * 4.0, 0.0, TAU, 72, Color(1.0, 0.20, 0.07, 0.35 + pulse * 0.12), 1.8)

	for i in range(6):
		var angle := TAU * float(i) / 6.0 + visual_time * 0.8
		var p1 := local_center + Vector2.RIGHT.rotated(angle) * (radius * 0.45)
		var p2 := local_center + Vector2.RIGHT.rotated(angle) * (radius * 0.92)
		draw_line(p1, p2, Color(1.0, 0.74, 0.24, 0.18 + progress * 0.22), 1.5)

	draw_line(local_center + Vector2(-radius * 0.52, 0), local_center + Vector2(radius * 0.52, 0), Color(1.0, 0.58, 0.18, 0.18 + progress * 0.20), 1.4)
	draw_line(local_center + Vector2(0, -radius * 0.52), local_center + Vector2(0, radius * 0.52), Color(1.0, 0.58, 0.18, 0.18 + progress * 0.20), 1.4)


func _draw_hp_bar() -> void:
	var hp_pct := clampf(hp / max_hp, 0.0, 1.0)
	var bar_width := _get_bar_width()
	var bar_y := _get_bar_y()

	draw_rect(
		Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width, 6)),
		Color(0, 0, 0, 0.68)
	)

	draw_rect(
		Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width * hp_pct, 6)),
		_get_hp_color()
	)

	draw_rect(
		Rect2(Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width, 6)),
		Color(1, 1, 1, 0.18),
		false,
		1.0
	)


func _draw_rank_label() -> void:
	if enemy_role == "" and enemy_rank == "normal":
		return

	var display_text: String = enemy_display_name

	if display_text == "":
		display_text = _get_display_name_for_role(enemy_role)

	if enemy_rank != "normal" and not display_text.to_lower().contains(enemy_rank):
		display_text = "%s · %s" % [enemy_rank.to_upper(), display_text]

	var y: float = _get_bar_y() - 14.0
	var width: float = maxf(76.0, float(display_text.length()) * 6.0 + 16.0)
	var rect: Rect2 = Rect2(Vector2(-width * 0.5, y - 11.0), Vector2(width, 15.0))
	var color: Color = _get_hp_color()

	draw_rect(rect, Color(0, 0, 0, 0.58))
	draw_rect(rect, Color(color.r, color.g, color.b, 0.56), false, 1.0)
	draw_string(
		ThemeDB.fallback_font,
		rect.position + Vector2(0, 11.0),
		display_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x,
		8,
		Color("#f7e8d4")
	)


func _start_death_animation() -> void:
	if death_started:
		return

	dead = true
	death_started = true
	death_timer = death_duration
	velocity = Vector2.ZERO
	attack_state = "dead"

	_disable_collision_shapes()
	_spawn_death_particles()
	_award_death_rewards()

	if sprite != null:
		sprite.modulate = Color(1.0, 0.55, 0.45, 1.0)

	died.emit(global_position)


func _disable_collision_shapes() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			var shape := child as CollisionShape2D
			shape.disabled = true
		elif child is CollisionPolygon2D:
			var polygon := child as CollisionPolygon2D
			polygon.disabled = true


func _update_death_animation(delta: float) -> void:
	death_timer -= delta

	var progress: float = 1.0 - clampf(death_timer / death_duration, 0.0, 1.0)

	if sprite != null:
		sprite.scale = sprite.scale.lerp(sprite.scale * Vector2(1.04, 0.92), delta * 8.0)
		sprite.position.y -= delta * 12.0
		sprite.modulate = Color(1.0, 0.62, 0.48, maxf(0.0, 1.0 - progress))

	if death_timer <= 0.0:
		queue_free()


func _spawn_hit_particles(hit_kind: String = "hit", hit_direction: Vector2 = Vector2.RIGHT) -> void:
	var count: int = 7
	var particle_color := _get_hit_effect_color(hit_kind)

	if hit_kind == "heavy" or hit_kind == "ultimate":
		count += 5
	elif hit_kind == "q":
		count += 3

	if enemy_rank == "elite":
		count += 2
	elif enemy_rank == "miniboss":
		count += 4
	elif enemy_rank == "boss":
		count += 8

	for i in range(count):
		var angle: float = hit_direction.angle() + randf_range(-1.25, 1.25)
		var speed_value: float = randf_range(46.0, 135.0)

		if i % 4 == 0:
			angle = randf_range(0.0, TAU)
			speed_value = randf_range(28.0, 86.0)

		particles.append({
			"pos": Vector2(randf_range(-8.0, 8.0), randf_range(-24.0, -4.0)),
			"vel": Vector2(cos(angle), sin(angle)) * speed_value,
			"life": randf_range(0.22, 0.48),
			"max_life": 0.48,
			"size": randf_range(2.0, 5.0),
			"color": particle_color
		})

	for i in range(3):
		var spark_angle: float = hit_direction.angle() + randf_range(-0.42, 0.42)
		particles.append({
			"pos": Vector2(randf_range(-4.0, 4.0), randf_range(-20.0, -8.0)),
			"vel": Vector2(cos(spark_angle), sin(spark_angle)) * randf_range(115.0, 190.0),
			"life": randf_range(0.10, 0.18),
			"max_life": 0.18,
			"size": randf_range(1.5, 2.8),
			"color": Color("#fff0b8")
		})


func _spawn_impact_ring(hit_kind: String = "hit", hit_direction: Vector2 = Vector2.RIGHT) -> void:
	var radius := 28.0
	var width := 3.0
	var color := _get_hit_effect_color(hit_kind)
	var life := 0.20

	match hit_kind:
		"light", "light_1":
			radius = 24.0
			width = 2.4
		"light_2":
			radius = 28.0
			width = 2.8
		"light_3":
			radius = 34.0
			width = 3.4
		"heavy":
			radius = 42.0
			width = 4.5
			life = 0.24
		"q":
			radius = 38.0
			width = 3.8
			life = 0.24
		"ultimate":
			radius = 58.0
			width = 5.2
			life = 0.32
		_:
			radius = 28.0

	if enemy_rank == "miniboss":
		radius *= 1.22
	elif enemy_rank == "boss":
		radius *= 1.48

	impact_rings.append({
		"pos": Vector2(0.0, -14.0),
		"dir": hit_direction,
		"life": life,
		"max_life": life,
		"radius": radius,
		"width": width,
		"color": color,
		"kind": hit_kind
	})


func _update_impact_rings(delta: float) -> void:
	var kept_rings: Array[Dictionary] = []

	for ring in impact_rings:
		var life: float = float(ring.get("life", 0.0)) - delta

		if life <= 0.0:
			continue

		ring["life"] = life
		kept_rings.append(ring)

	impact_rings = kept_rings


func _draw_impact_rings() -> void:
	for ring in impact_rings:
		var life: float = float(ring.get("life", 0.0))
		var max_life: float = maxf(float(ring.get("max_life", 0.2)), 0.01)
		var t: float = clampf(1.0 - life / max_life, 0.0, 1.0)
		var alpha: float = 1.0 - t
		var pos: Vector2 = ring.get("pos", Vector2.ZERO)
		var direction: Vector2 = ring.get("dir", Vector2.RIGHT)
		var radius: float = float(ring.get("radius", 28.0)) * (0.55 + t * 0.85)
		var width: float = float(ring.get("width", 3.0)) * alpha
		var color: Color = ring.get("color", Color("#ffd36a"))
		var kind: String = str(ring.get("kind", "hit"))

		color.a = 0.75 * alpha

		if kind == "ultimate":
			draw_circle(pos, radius * 0.62, Color(color.r, color.g, color.b, 0.08 * alpha))
			draw_arc(pos, radius, 0.0, TAU, 48, color, maxf(1.0, width))
		else:
			var angle := direction.angle()
			draw_arc(pos, radius, angle - 1.05, angle + 1.05, 24, color, maxf(1.0, width))
			draw_line(pos - direction * 10.0, pos + direction * radius * 0.55, Color(color.r, color.g, color.b, 0.40 * alpha), maxf(1.0, width * 0.55))


func _get_hit_effect_color(hit_kind: String) -> Color:
	match hit_kind:
		"light", "light_1":
			return Color("#f7e8d4")
		"light_2":
			return Color("#ffe2a8")
		"light_3":
			return Color("#dfaa46")
		"heavy":
			return Color("#ff684a")
		"q":
			return Color("#9ed8cd")
		"ultimate":
			return Color("#ffd36a")
		_:
			return Color("#ffd36a")


func _spawn_attack_particles() -> void:
	var count: int = 6

	if current_attack_style == "circle":
		count = 10
	elif current_attack_style == "line":
		count = 8
	elif current_attack_style == "cone":
		count = 9
	elif current_attack_style == "pounce":
		count = 7

	for i in range(count):
		var spread: float = randf_range(-0.85, 0.85)
		var dir: Vector2 = attack_direction.rotated(spread).normalized()
		var speed_value: float = randf_range(45.0, 130.0)

		particles.append({
			"pos": Vector2.ZERO,
			"vel": dir * speed_value,
			"life": randf_range(0.16, 0.30),
			"max_life": 0.30,
			"size": randf_range(2.0, 5.0),
			"color": _get_role_color()
		})

func _spawn_windup_warning_particles() -> void:
	var count := 4

	if enemy_rank == "elite":
		count = 5
	elif enemy_rank == "miniboss":
		count = 7
	elif enemy_rank == "boss":
		count = 10

	for i in range(count):
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(18.0, 34.0)
		particles.append({
			"pos": Vector2.RIGHT.rotated(angle) * distance + Vector2(0, -10),
			"vel": -Vector2.RIGHT.rotated(angle) * randf_range(18.0, 46.0),
			"life": randf_range(0.26, 0.44),
			"max_life": 0.44,
			"size": randf_range(2.0, 4.0),
			"color": _get_role_color()
		})


func _spawn_attack_release_burst() -> void:
	var life := 0.22
	var radius := attack_range
	var width := 4.0

	match current_attack_style:
		"pounce":
			radius = 42.0
			width = 4.0
			life = 0.20
		"cone":
			radius = attack_range
			width = 4.5
			life = 0.24
		"line":
			radius = attack_range
			width = 5.0
			life = 0.24
		"circle":
			radius = attack_range
			width = 5.0
			life = 0.26

	if enemy_rank == "elite":
		radius *= 1.06
	elif enemy_rank == "miniboss":
		radius *= 1.12
	elif enemy_rank == "boss":
		radius *= 1.18
		life += 0.08

	attack_release_bursts.append({
		"style": current_attack_style,
		"dir": attack_direction,
		"life": life,
		"max_life": life,
		"radius": radius,
		"width": width
	})


func _update_attack_release_bursts(delta: float) -> void:
	var kept_bursts: Array[Dictionary] = []

	for burst in attack_release_bursts:
		var life: float = float(burst.get("life", 0.0)) - delta

		if life <= 0.0:
			continue

		burst["life"] = life
		kept_bursts.append(burst)

	attack_release_bursts = kept_bursts


func _draw_attack_release_bursts() -> void:
	for burst in attack_release_bursts:
		var life: float = float(burst.get("life", 0.0))
		var max_life: float = maxf(float(burst.get("max_life", 0.22)), 0.01)
		var progress: float = clampf(1.0 - life / max_life, 0.0, 1.0)
		var alpha: float = 1.0 - progress
		var style := str(burst.get("style", "circle"))
		var radius: float = float(burst.get("radius", attack_range))
		var width: float = float(burst.get("width", 4.0)) * alpha
		var dir: Vector2 = burst.get("dir", Vector2.RIGHT)

		if dir.length() <= 0.01:
			dir = Vector2.RIGHT

		dir = dir.normalized()

		match style:
			"pounce":
				var impact_radius := 28.0 + progress * 32.0
				draw_circle(Vector2.ZERO, impact_radius, Color(1.0, 0.16, 0.06, 0.16 * alpha))
				draw_arc(Vector2.ZERO, impact_radius, 0.0, TAU, 42, Color(1.0, 0.78, 0.32, 0.72 * alpha), maxf(1.0, width))
			"line":
				var end_point := dir * radius
				draw_line(Vector2.ZERO, end_point, Color(1.0, 0.78, 0.30, 0.62 * alpha), maxf(1.0, width))
				draw_line(Vector2.ZERO, end_point, Color(1.0, 0.12, 0.04, 0.20 * alpha), maxf(4.0, width * 2.2))
			"cone":
				var start_angle := dir.angle() - attack_angle_width
				var end_angle := dir.angle() + attack_angle_width
				draw_arc(Vector2.ZERO, radius * (0.86 + progress * 0.16), start_angle, end_angle, 42, Color(1.0, 0.78, 0.32, 0.66 * alpha), maxf(1.0, width))
				draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(start_angle) * radius, Color(1.0, 0.22, 0.07, 0.38 * alpha), maxf(1.0, width * 0.6))
				draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(end_angle) * radius, Color(1.0, 0.22, 0.07, 0.38 * alpha), maxf(1.0, width * 0.6))
			_:
				var ring_radius := radius * (0.82 + progress * 0.24)
				draw_circle(Vector2.ZERO, ring_radius, Color(1.0, 0.12, 0.05, 0.08 * alpha))
				draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 72, Color(1.0, 0.78, 0.32, 0.68 * alpha), maxf(1.0, width))

func apply_status(status_id: String, stacks: int = 1, duration: float = 4.0) -> void:
	if dead:
		return

	var safe_status_id := status_id.strip_edges()

	if safe_status_id == "":
		return

	var effect: Dictionary = {}

	if status_effects.has(safe_status_id):
		effect = status_effects[safe_status_id]

	var previous_stacks: int = int(effect.get("stacks", 0))
	var new_stacks: int = mini(_get_status_max_stacks(safe_status_id), previous_stacks + maxi(1, stacks))

	effect["stacks"] = new_stacks
	effect["duration"] = maxf(float(effect.get("duration", 0.0)), duration)
	effect["tick_timer"] = float(effect.get("tick_timer", _get_status_tick_interval(safe_status_id)))

	status_effects[safe_status_id] = effect

	if safe_status_id == "judgment":
		_spawn_status_apply_particles(Color("#ffd36a"))
	elif safe_status_id == "bleed":
		_spawn_status_apply_particles(Color("#ff2b1f"))
	elif safe_status_id == "poison":
		_spawn_status_apply_particles(Color("#7fdc54"))

func consume_status(status_id: String) -> int:
	if not status_effects.has(status_id):
		return 0

	var effect: Dictionary = status_effects[status_id]
	var stacks: int = int(effect.get("stacks", 0))

	status_effects.erase(status_id)

	if stacks > 0:
		if status_id == "bleed":
			_spawn_status_apply_particles(Color("#ff2b1f"))
		elif status_id == "poison":
			_spawn_status_apply_particles(Color("#7fdc54"))
		elif status_id == "judgment":
			_spawn_status_apply_particles(Color("#ffd36a"))

	return stacks


func get_status_duration(status_id: String) -> float:
	if not status_effects.has(status_id):
		return 0.0

	var effect: Dictionary = status_effects[status_id]
	return float(effect.get("duration", 0.0))

func has_status(status_id: String) -> bool:
	if not status_effects.has(status_id):
		return false

	var effect: Dictionary = status_effects[status_id]

	return float(effect.get("duration", 0.0)) > 0.0


func get_status_stacks(status_id: String) -> int:
	if not status_effects.has(status_id):
		return 0

	var effect: Dictionary = status_effects[status_id]
	return int(effect.get("stacks", 0))

func _get_status_duration_ratio(status_id: String) -> float:
	if not status_effects.has(status_id):
		return 0.0

	var effect: Dictionary = status_effects[status_id]
	var duration: float = float(effect.get("duration", 0.0))

	var max_duration: float = 1.0

	match status_id:
		"bleed":
			max_duration = 4.0
		"poison":
			max_duration = 8.0
		"judgment":
			max_duration = 8.0
		_:
			max_duration = maxf(1.0, duration)

	return clampf(duration / max_duration, 0.0, 1.0)

func _draw_status_icon(status_id: String, pos: Vector2) -> void:
	var outline_color := _get_status_color(status_id)

	draw_circle(pos, 10.0, Color(0.0, 0.0, 0.0, 0.74))
	draw_arc(pos, 10.0, 0.0, TAU, 28, outline_color, 1.5)

	match status_id:
		"bleed":
			_draw_bleed_status_icon(pos)
			_draw_status_stack_pips(pos + Vector2(0, 13), get_status_stacks("bleed"), outline_color)

		"poison":
			_draw_poison_status_icon(pos)
			_draw_status_stack_pips(pos + Vector2(0, 13), get_status_stacks("poison"), outline_color)

		"judgment":
			_draw_judgment_status_icon(pos)

		_:
			draw_circle(pos, 3.0, Color.WHITE)


func _draw_bleed_status_icon(pos: Vector2) -> void:
	var color := Color("#ff2b1f")

	draw_circle(pos + Vector2(0, -2.5), 3.5, color)

	var points := PackedVector2Array([
		pos + Vector2(-3.2, 0.0),
		pos + Vector2(3.2, 0.0),
		pos + Vector2(0.0, 6.2)
	])

	var colors := PackedColorArray([color, color, color])
	draw_polygon(points, colors)

	draw_circle(pos + Vector2(-1.2, -3.5), 1.0, Color(1.0, 0.75, 0.75, 0.45))


func _draw_poison_status_icon(pos: Vector2) -> void:
	var color := Color("#6eea4b")
	var bright := Color("#d7ffd0")

	draw_circle(pos + Vector2(-3.7, -1.2), 2.1, color)
	draw_circle(pos + Vector2(3.7, -1.2), 2.1, color)
	draw_circle(pos + Vector2(0.0, 3.1), 2.5, color)

	draw_arc(pos + Vector2(-3.7, -1.2), 3.2, 0.0, TAU, 12, bright, 0.8)
	draw_arc(pos + Vector2(3.7, -1.2), 3.2, 0.0, TAU, 12, bright, 0.8)
	draw_arc(pos + Vector2(0.0, 3.1), 3.5, 0.0, TAU, 12, bright, 0.8)

	draw_line(pos + Vector2(-5.2, -5.4), pos + Vector2(5.2, 5.4), bright, 1.1)
	draw_line(pos + Vector2(5.2, -5.4), pos + Vector2(-5.2, 5.4), bright, 1.1)


func _draw_judgment_status_icon(pos: Vector2) -> void:
	var color := Color("#ffd36a")

	draw_arc(pos, 5.8, 0.0, TAU, 28, color, 1.3)

	draw_line(pos + Vector2(0, -5.5), pos + Vector2(0, 4.2), color, 1.3)
	draw_line(pos + Vector2(-5.0, -2.0), pos + Vector2(5.0, -2.0), color, 1.3)

	draw_line(pos + Vector2(-3.0, -2.0), pos + Vector2(-5.0, 2.0), color, 1.0)
	draw_line(pos + Vector2(3.0, -2.0), pos + Vector2(5.0, 2.0), color, 1.0)

	draw_arc(pos + Vector2(-5.0, 2.4), 2.1, 0.0, PI, 10, color, 1.0)
	draw_arc(pos + Vector2(5.0, 2.4), 2.1, 0.0, PI, 10, color, 1.0)


func _draw_status_stack_badge(pos: Vector2, stacks: int, color: Color) -> void:
	var rect := Rect2(pos + Vector2(-5.5, -5.5), Vector2(11.0, 11.0))

	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.85))
	draw_rect(rect, color, false, 1.0)

	draw_string(
		ThemeDB.fallback_font,
		pos + Vector2(-3.0, 3.5),
		str(stacks),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		8,
		Color("#fff6e8")
	)

func _update_status_effects(delta: float) -> void:
	if status_effects.is_empty():
		return

	var keys := status_effects.keys()

	for status_id_value in keys:
		var status_id := str(status_id_value)

		if not status_effects.has(status_id):
			continue

		var effect: Dictionary = status_effects[status_id]
		var duration: float = float(effect.get("duration", 0.0)) - delta

		effect["duration"] = duration

		if status_id == "bleed" or status_id == "poison":
			var tick_timer: float = float(effect.get("tick_timer", _get_status_tick_interval(status_id))) - delta

			if tick_timer <= 0.0:
				tick_timer += _get_status_tick_interval(status_id)
				_apply_status_tick_damage(status_id, int(effect.get("stacks", 1)))

			effect["tick_timer"] = tick_timer

		if duration <= 0.0:
			status_effects.erase(status_id)
		else:
			status_effects[status_id] = effect


func _apply_status_tick_damage(status_id: String, stacks: int) -> void:
	if dead:
		return

	var damage_amount: float = _get_status_tick_damage(status_id, stacks)

	if damage_amount <= 0.0:
		return

	hp -= damage_amount
	hp = maxf(0.0, hp)

	hit_flash = maxf(hit_flash, 0.06)

	if status_id == "bleed":
		_spawn_status_tick_particles(Color("#ff2b1f"))
	elif status_id == "poison":
		_spawn_status_tick_particles(Color("#7fdc54"))

	if hp <= 0.0:
		_start_death_animation()


func _get_status_tick_interval(status_id: String) -> float:
	match status_id:
		"bleed":
			return 0.60
		"poison":
			return 0.85
		_:
			return 1.0


func _get_status_tick_damage(status_id: String, stacks: int) -> float:
	match status_id:
		"bleed":
			return 0.95 * float(stacks)
		"poison":
			return 0.65 * float(stacks)
		_:
			return 0.0


func _get_status_max_stacks(status_id: String) -> int:
	match status_id:
		"bleed":
			return 8
		"poison":
			return 8
		"judgment":
			return 1
		_:
			return 5


func _spawn_status_apply_particles(color: Color) -> void:
	for i in range(8):
		var angle: float = randf_range(0.0, TAU)
		var speed_value: float = randf_range(24.0, 80.0)

		particles.append({
			"pos": Vector2(randf_range(-8.0, 8.0), randf_range(-28.0, -6.0)),
			"vel": Vector2(cos(angle), sin(angle)) * speed_value,
			"life": randf_range(0.18, 0.34),
			"max_life": 0.34,
			"size": randf_range(2.0, 4.0),
			"color": color
		})

func _spawn_death_particles() -> void:
	for i in range(28):
		var angle: float = randf_range(0.0, TAU)
		var speed_value: float = randf_range(38.0, 150.0)

		particles.append({
			"pos": Vector2(randf_range(-10.0, 10.0), randf_range(-28.0, 8.0)),
			"vel": Vector2(cos(angle), sin(angle)) * speed_value,
			"life": randf_range(0.28, 0.72),
			"max_life": 0.72,
			"size": randf_range(2.0, 6.0),
			"color": Color("#ff684a")
		})

	for i in range(12):
		var angle2: float = randf_range(0.0, TAU)
		var speed2: float = randf_range(18.0, 82.0)

		particles.append({
			"pos": Vector2(randf_range(-8.0, 8.0), randf_range(-26.0, 6.0)),
			"vel": Vector2(cos(angle2), sin(angle2)) * speed2,
			"life": randf_range(0.35, 0.90),
			"max_life": 0.90,
			"size": randf_range(3.0, 8.0),
			"color": Color("#2a0f0c")
		})

func _spawn_status_tick_particles(color: Color) -> void:
	for i in range(3):
		var angle: float = randf_range(-PI * 0.85, -PI * 0.15)
		var speed_value: float = randf_range(18.0, 54.0)

		particles.append({
			"pos": Vector2(randf_range(-10.0, 10.0), randf_range(-24.0, -6.0)),
			"vel": Vector2(cos(angle), sin(angle)) * speed_value,
			"life": randf_range(0.14, 0.26),
			"max_life": 0.26,
			"size": randf_range(1.5, 3.0),
			"color": color
		})


func _draw_status_indicators() -> void:
	if status_effects.is_empty():
		return

	_draw_status_world_effects()
	_draw_status_badge_row()


func _draw_status_stack_pips(pos: Vector2, stacks: int, color: Color) -> void:
	var safe_stacks: int = clampi(stacks, 1, 8)
	var spacing: float = 3.2
	var total_width: float = float(safe_stacks - 1) * spacing
	var start_x: float = -total_width * 0.5

	for i in range(safe_stacks):
		var pip_pos := pos + Vector2(start_x + float(i) * spacing, 0.0)

		draw_circle(
			pip_pos + Vector2(0.6, 0.8),
			1.35,
			Color(0.0, 0.0, 0.0, 0.75)
		)

		draw_circle(
			pip_pos,
			1.25,
			color
		)
func _draw_status_badge_row() -> void:
	var active_statuses: Array[String] = _get_active_status_ids()

	if active_statuses.is_empty():
		return

	var icon_spacing: float = 28.0
	var total_width: float = float(active_statuses.size() - 1) * icon_spacing
	var start_x: float = -total_width * 0.5
	var y: float = _get_bar_y() - 24.0

	for i in range(active_statuses.size()):
		var status_id: String = active_statuses[i]
		var icon_pos := Vector2(start_x + float(i) * icon_spacing, y)
		_draw_status_icon(status_id, icon_pos)


func _draw_status_world_effects() -> void:
	if has_status("judgment"):
		_draw_judgment_world_effect()

	if has_status("bleed"):
		_draw_bleed_world_effect()

	if has_status("poison"):
		_draw_poison_world_effect()


func _draw_bleed_world_effect() -> void:
	var stacks: int = get_status_stacks("bleed")
	var count: int = mini(6, maxi(2, stacks))
	var alpha: float = 0.65 + 0.25 * absf(sin(visual_time * 8.0))

	for i in range(count):
		var angle: float = TAU * float(i) / float(count) + visual_time * 0.75
		var orbit := Vector2.RIGHT.rotated(angle) * Vector2(22.0, 10.0)
		var drop_pos := Vector2(0, -15) + orbit

		draw_circle(drop_pos, 2.2, Color(1.0, 0.05, 0.03, alpha))
		draw_line(
			drop_pos + Vector2(0, 2),
			drop_pos + Vector2(0, 6),
			Color(1.0, 0.05, 0.03, alpha * 0.75),
			1.0
		)


func _draw_poison_world_effect() -> void:
	var stacks: int = get_status_stacks("poison")
	var count: int = mini(6, maxi(2, stacks))
	var alpha: float = 0.55 + 0.22 * absf(sin(visual_time * 5.0))

	for i in range(count):
		var angle: float = TAU * float(i) / float(count) - visual_time * 0.55
		var bubble_radius: float = 20.0 + sin(visual_time * 2.7 + float(i)) * 4.0
		var bubble_pos := Vector2(0, -17) + Vector2.RIGHT.rotated(angle) * bubble_radius

		draw_circle(bubble_pos, 2.4, Color(0.34, 1.0, 0.22, alpha * 0.45))
		draw_arc(
			bubble_pos,
			3.5,
			0.0,
			TAU,
			12,
			Color(0.50, 1.0, 0.32, alpha),
			1.0
		)


func _draw_judgment_world_effect() -> void:
	var pulse: float = 0.55 + 0.35 * absf(sin(visual_time * 5.5))
	var center := Vector2(0, -14)

	draw_arc(center, 32.0, 0.0, TAU, 48, Color(1.0, 0.78, 0.18, pulse), 2.0)
	draw_arc(center, 22.0, -PI * 0.25, PI * 1.25, 32, Color(1.0, 0.88, 0.35, 0.55), 2.0)

	var left := center + Vector2(-12, -10)
	var right := center + Vector2(12, -10)
	var bottom := center + Vector2(0, 13)

	draw_line(left, bottom, Color(1.0, 0.78, 0.18, pulse), 1.2)
	draw_line(right, bottom, Color(1.0, 0.78, 0.18, pulse), 1.2)
	draw_line(left, right, Color(1.0, 0.78, 0.18, pulse), 1.2)


func _get_active_status_ids() -> Array[String]:
	var result: Array[String] = []

	if has_status("judgment"):
		result.append("judgment")

	if has_status("bleed"):
		result.append("bleed")

	if has_status("poison"):
		result.append("poison")

	return result


func _get_status_color(status_id: String) -> Color:
	match status_id:
		"bleed":
			return Color("#ff2b1f")
		"poison":
			return Color("#7fdc54")
		"judgment":
			return Color("#ffd36a")
		_:
			return Color("#f7e8d4")


func _award_death_rewards() -> void:
	var soul_reward: int = _get_broken_soul_reward()

	if has_node("/root/GameState"):
		var game_state := get_node("/root/GameState")

		if game_state != null:
			if game_state.has_method("add_broken_souls"):
				game_state.call("add_broken_souls", soul_reward)

			if game_state.has_method("record_enemy_kill"):
				game_state.call("record_enemy_kill", enemy_role if enemy_role != "" else enemy_kind, enemy_rank)


func _get_broken_soul_reward() -> int:
	match enemy_rank:
		"elite":
			return randi_range(7, 12)
		"miniboss":
			return randi_range(18, 28)
		"boss":
			return randi_range(45, 70)
		_:
			match enemy_role:
				"ash_wretch":
					return randi_range(1, 3)
				"bell_hound":
					return randi_range(2, 4)
				"gate_warden":
					return randi_range(3, 5)
				"cinder_scribe":
					return randi_range(3, 6)
				"vestibule_bailiff":
					return randi_range(7, 12)
				_:
					match enemy_kind:
						"imp":
							return randi_range(1, 3)
						"goblin":
							return randi_range(2, 4)
						"skelet":
							return randi_range(2, 5)
						_:
							return randi_range(1, 4)


func _update_particles(delta: float) -> void:
	var kept_particles: Array[Dictionary] = []

	for particle in particles:
		var life: float = float(particle["life"]) - delta

		if life <= 0.0:
			continue

		var pos: Vector2 = particle["pos"]
		var vel: Vector2 = particle["vel"]

		vel *= 0.88
		pos += vel * delta

		particle["life"] = life
		particle["pos"] = pos
		particle["vel"] = vel

		kept_particles.append(particle)

	particles = kept_particles


func _draw_particles() -> void:
	for particle in particles:
		var life: float = float(particle["life"])
		var max_life: float = float(particle["max_life"])
		var alpha: float = clampf(life / max_life, 0.0, 1.0)
		var pos: Vector2 = particle["pos"]
		var size: float = float(particle["size"])
		var color: Color = particle["color"]

		color.a *= alpha

		draw_circle(pos, size * alpha, color)


func _draw_death_overlay() -> void:
	var progress: float = 1.0 - clampf(death_timer / death_duration, 0.0, 1.0)
	var radius: float = lerpf(18.0, 54.0, progress)
	var alpha: float = 0.32 * (1.0 - progress)

	if enemy_rank == "boss":
		radius = lerpf(38.0, 110.0, progress)
		alpha = 0.42 * (1.0 - progress)

	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.18, 0.08, alpha))
	draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 48, Color(1.0, 0.68, 0.24, alpha), 3.0)

func _draw_fallback_body() -> void:
	var body_color := Color("#6b5a79")
	var body_radius := 18.0

	match enemy_rank:
		"elite":
			body_color = Color("#8f5fd1")
			body_radius = 21.0
		"miniboss":
			body_color = Color("#b46a4a")
			body_radius = 24.0
		"boss":
			body_color = Color("#b51f1f")
			body_radius = 32.0

	if hit_flash > 0.4:
		body_color = Color.WHITE

	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_circle(Vector2(-6, -3), 3.0, Color("#10080b"))
	draw_circle(Vector2(6, -3), 3.0, Color("#10080b"))
