extends Node2D

@export var npc_id: String = "npc"
@export var speaker_name: String = "Unknown"
@export var role_subtitle: String = "Wandering Soul"
@export var interaction_action: String = "Speak"
@export var interaction_radius: float = 74.0
@export var body_color: Color = Color("#6b5a79")
@export var accent_color: Color = Color("#dfaa46")
@export var dialogue_lines: Array[String] = [
	"..."
]

var player: Node2D = null
var is_player_near: bool = false
var interact_cooldown: float = 0.0
var bob_time: float = 0.0
var talk_count: int = 0


func _ready() -> void:
	_apply_default_identity_if_needed()
	add_to_group("hub_npc")
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	bob_time += delta
	interact_cooldown = maxf(0.0, interact_cooldown - delta)

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	_update_player_near_state()

	if is_player_near and interact_cooldown <= 0.0 and _is_interact_pressed():
		interact_cooldown = 0.35
		_open_interaction()

	queue_redraw()


func _update_player_near_state() -> void:
	is_player_near = false

	if player == null:
		return

	var distance: float = global_position.distance_to(player.global_position)
	is_player_near = distance <= interaction_radius


func _is_interact_pressed() -> bool:
	if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
		return true

	return Input.is_physical_key_pressed(KEY_E)


func _open_interaction() -> void:
	if _is_any_interface_active():
		return

	match npc_id:
		"silent_smith":
			_open_smith_menu()
		"codex_keeper":
			_open_codex_menu()
		_:
			_open_dialogue()


func _open_smith_menu() -> void:
	var menus: Array[Node] = get_tree().get_nodes_in_group("smith_menu")

	if menus.is_empty():
		push_warning("No SmithMenu found. Add scenes/ui/SmithMenu.tscn to Hub.tscn.")
		_open_dialogue()
		return

	var menu: Node = menus[0]

	if menu != null and menu.has_method("open_menu"):
		menu.call("open_menu", self)


func _open_codex_menu() -> void:
	var menus: Array[Node] = get_tree().get_nodes_in_group("codex_menu")

	if menus.is_empty():
		push_warning("No CodexMenu found. Add scenes/ui/CodexMenu.tscn to Hub.tscn.")
		_open_dialogue()
		return

	var menu: Node = menus[0]

	if menu != null and menu.has_method("open_menu"):
		menu.call("open_menu", self)


func _open_dialogue() -> void:
	var dialogue_boxes: Array[Node] = get_tree().get_nodes_in_group("dialogue_box")

	if dialogue_boxes.is_empty():
		push_warning("No DialogueBox found. Add scenes/ui/DialogueBox.tscn to Hub.tscn.")
		return

	var dialogue_box: Node = dialogue_boxes[0]

	if dialogue_box != null and dialogue_box.has_method("is_dialogue_active"):
		if bool(dialogue_box.call("is_dialogue_active")):
			return

	var lines_to_use: Array[String] = _get_dialogue_for_current_talk_count()

	if dialogue_box != null and dialogue_box.has_method("start_dialogue"):
		dialogue_box.call("start_dialogue", speaker_name, lines_to_use, self)

	talk_count += 1


func _is_any_interface_active() -> bool:
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


func _get_dialogue_for_current_talk_count() -> Array[String]:
	if not dialogue_lines.is_empty() and dialogue_lines[0] != "...":
		return dialogue_lines

	match npc_id:
		"virgil_echo":
			return _get_virgil_dialogue()
		_:
			return _get_generic_dialogue()


func _get_virgil_dialogue() -> Array[String]:
	match talk_count:
		0:
			return [
				"You return to the slab with your shape intact. That is more than most are allowed.",
				"The doors below do not lead to one Hell, but to circles. Each one teaches with a different instrument.",
				"When you descend, read the room before you read the enemy. The floor, the walls, the heat — all of it is a warning.",
				"Speak to the Keeper if you want records. Speak to the Smith if you want the blade to remember your failures.",
				"Then go below. Hell does not respect hesitation."
			]
		1:
			return [
				"You are beginning to notice the difference between danger and noise.",
				"Good. The first lesson of survival is not bravery. It is discrimination."
			]
		2:
			return [
				"Every return makes the hub less merciful.",
				"That is not cruelty. That is memory."
			]
		3:
			return [
				"The gate is ready when you are.",
				"Do not ask the dead to do the walking for you."
			]
		_:
			return [
				"Descend."
			]


func _get_generic_dialogue() -> Array[String]:
	match npc_id:
		"codex_keeper":
			return [
				"Records do not absolve. They preserve.",
				"Bring me names, shapes, wounds, and repeated deaths. The Codex will arrange them."
			]
		"silent_smith":
			return [
				"The blade has learned your hand.",
				"Now teach it what you refuse to lose."
			]
		_:
			return [
				"Not every soul remembers its name.",
				"Perhaps that is mercy."
			]


func _apply_default_identity_if_needed() -> void:
	var normalized_name: String = name.to_lower()

	if npc_id == "npc" or npc_id.strip_edges() == "":
		if normalized_name.contains("virgil"):
			npc_id = "virgil_echo"
		elif normalized_name.contains("codex"):
			npc_id = "codex_keeper"
		elif normalized_name.contains("smith"):
			npc_id = "silent_smith"

	match npc_id:
		"virgil_echo":
			speaker_name = "Virgil's Echo"
			role_subtitle = "Guide of the Return Slab"
			interaction_action = "Speak"
			body_color = Color("#43516a")
			accent_color = Color("#dfaa46")

		"codex_keeper":
			speaker_name = "Codex Keeper"
			role_subtitle = "Keeper of Descent Records"
			interaction_action = "Open Codex"
			body_color = Color("#4a355f")
			accent_color = Color("#b49ce2")

		"silent_smith":
			speaker_name = "Silent Smith"
			role_subtitle = "Temperer of Relics"
			interaction_action = "Temper Weapon"
			body_color = Color("#3a3130")
			accent_color = Color("#ff684a")

		_:
			if speaker_name == "Unknown":
				speaker_name = "Unknown Soul"
			if role_subtitle.strip_edges() == "":
				role_subtitle = "Wandering Soul"
			if interaction_action.strip_edges() == "":
				interaction_action = "Speak"


func _draw() -> void:
	_draw_shadow()
	_draw_presence_aura()
	_draw_npc_body()
	_draw_label()

	if is_player_near:
		_draw_prompt()


func _draw_shadow() -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var center: Vector2 = Vector2(0, 22)
	var width: float = 54.0
	var height: float = 13.0
	var steps: int = 24

	for i in range(steps):
		var angle: float = TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(angle) * width * 0.5, sin(angle) * height * 0.5))

	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.36))


func _draw_presence_aura() -> void:
	var pulse: float = 0.55 + 0.22 * absf(sin(bob_time * 1.7))
	var alpha: float = 0.11

	if is_player_near:
		alpha = 0.22

	draw_arc(Vector2(0, 2), 39.0 + pulse * 4.0, 0.0, TAU, 58, Color(accent_color.r, accent_color.g, accent_color.b, alpha), 2.0)
	draw_arc(Vector2(0, 2), 26.0, 0.0, TAU, 42, Color(accent_color.r, accent_color.g, accent_color.b, alpha * 0.62), 1.2)


func _draw_npc_body() -> void:
	var bob: float = sin(bob_time * 2.1) * 1.8
	var base: Vector2 = Vector2(0, bob)

	match npc_id:
		"virgil_echo":
			_draw_virgil_body(base)
		"codex_keeper":
			_draw_codex_body(base)
		"silent_smith":
			_draw_smith_body(base)
		_:
			_draw_generic_body(base)


func _draw_virgil_body(base: Vector2) -> void:
	draw_circle(base + Vector2(0, -20), 17.0, body_color)
	draw_circle(base + Vector2(0, -24), 11.0, body_color.lerp(Color.WHITE, 0.12))
	draw_rect(Rect2(base + Vector2(-14, -18), Vector2(28, 35)), body_color.darkened(0.24))
	draw_line(base + Vector2(-12, -5), base + Vector2(12, -5), accent_color, 3.0)
	draw_line(base + Vector2(0, -17), base + Vector2(0, 11), accent_color.darkened(0.18), 2.0)
	draw_arc(base + Vector2(0, -21), 20.0, PI * 1.12, PI * 1.88, 24, accent_color, 2.0)
	draw_circle(base + Vector2(-5, -24), 2.0, accent_color)
	draw_circle(base + Vector2(5, -24), 2.0, accent_color)


func _draw_codex_body(base: Vector2) -> void:
	draw_circle(base + Vector2(0, -20), 17.0, body_color)
	draw_rect(Rect2(base + Vector2(-15, -18), Vector2(30, 36)), body_color.darkened(0.18))
	draw_rect(Rect2(base + Vector2(-9, -10), Vector2(18, 22)), Color("#2a1c34"))
	draw_rect(Rect2(base + Vector2(-9, -10), Vector2(18, 22)), accent_color, false, 1.0)
	draw_line(base + Vector2(0, -7), base + Vector2(0, 8), accent_color.lightened(0.16), 1.5)
	draw_line(base + Vector2(-5, -1), base + Vector2(5, -1), accent_color.lightened(0.16), 1.5)
	draw_circle(base + Vector2(-5, -24), 2.0, accent_color)
	draw_circle(base + Vector2(5, -24), 2.0, accent_color)


func _draw_smith_body(base: Vector2) -> void:
	draw_circle(base + Vector2(0, -20), 17.0, body_color)
	draw_rect(Rect2(base + Vector2(-16, -18), Vector2(32, 37)), body_color.darkened(0.18))
	draw_rect(Rect2(base + Vector2(-11, -6), Vector2(22, 24)), Color("#1a0b08"))
	draw_line(base + Vector2(-14, 2), base + Vector2(14, 2), accent_color, 3.0)
	draw_line(base + Vector2(0, -15), base + Vector2(0, 13), accent_color.darkened(0.16), 2.0)
	draw_circle(base + Vector2(-5, -24), 2.0, accent_color)
	draw_circle(base + Vector2(5, -24), 2.0, accent_color)
	draw_arc(base + Vector2(0, 4), 24.0, PI * 0.08, PI * 0.92, 28, Color(1.0, 0.34, 0.18, 0.45), 2.0)


func _draw_generic_body(base: Vector2) -> void:
	draw_circle(base + Vector2(0, -20), 17.0, body_color)
	draw_rect(Rect2(base + Vector2(-14, -18), Vector2(28, 34)), body_color.darkened(0.22))
	draw_line(base + Vector2(-11, -4), base + Vector2(11, -4), accent_color, 3.0)
	draw_line(base + Vector2(0, -16), base + Vector2(0, 10), accent_color.darkened(0.2), 2.0)
	draw_circle(base + Vector2(-5, -24), 2.0, accent_color)
	draw_circle(base + Vector2(5, -24), 2.0, accent_color)


func _draw_label() -> void:
	var text_width: float = 178.0
	var label_rect: Rect2 = Rect2(Vector2(-text_width * 0.5, 42), Vector2(text_width, 34))

	draw_rect(label_rect, Color(0, 0, 0, 0.38))
	draw_rect(label_rect, Color(accent_color.r, accent_color.g, accent_color.b, 0.25), false, 1.0)

	draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(0, 14), speaker_name, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 13, Color("#f7e8d4"))
	draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(0, 28), role_subtitle, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 10, Color("#c4a98f"))


func _draw_prompt() -> void:
	var prompt: String = "[E] %s — %s" % [interaction_action, speaker_name]
	var rect_width: float = clampf(float(prompt.length()) * 7.2 + 24.0, 176.0, 284.0)
	var prompt_rect: Rect2 = Rect2(Vector2(-rect_width * 0.5, -88), Vector2(rect_width, 34))

	draw_rect(prompt_rect, Color(0.018, 0.010, 0.008, 0.88))
	draw_rect(prompt_rect, Color(accent_color.r, accent_color.g, accent_color.b, 0.12))
	draw_rect(prompt_rect, accent_color, false, 1.5)
	draw_rect(prompt_rect.grow(-5), Color(1, 1, 1, 0.06), false, 1.0)
	draw_string(ThemeDB.fallback_font, prompt_rect.position + Vector2(0, 22), prompt, HORIZONTAL_ALIGNMENT_CENTER, prompt_rect.size.x, 13, Color("#f7e8d4"))
