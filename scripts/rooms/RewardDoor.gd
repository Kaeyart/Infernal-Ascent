extends Node2D

signal door_entered(reward_type: String)

@export var reward_type: String = "upgrade"
@export var interact_radius: float = 72.0

var player: Node2D = null
var is_player_near: bool = false
var unlocked: bool = false

func set_unlocked(value: bool) -> void:
	unlocked = value
	visible = value
	set_process(value)
	queue_redraw()

func _ready() -> void:
	set_unlocked(unlocked)

func _process(_delta: float) -> void:
	if not unlocked:
		return

	player = get_tree().get_first_node_in_group("player") as Node2D
	is_player_near = false

	if player:
		is_player_near = global_position.distance_to(player.global_position) <= interact_radius

		if is_player_near and Input.is_action_just_pressed("interact"):
			door_entered.emit(reward_type)

	queue_redraw()

func _draw() -> void:
	if not unlocked:
		return

	var base_color := Color("#21151a")
	var ring_color := Color("#dfaa46")

	match reward_type:
		"upgrade":
			ring_color = Color("#dfaa46")
		"forge":
			ring_color = Color("#d64a2f")
		"shop":
			ring_color = Color("#9ed8cd")
		"shrine":
			ring_color = Color("#b49ce2")
		"fountain":
			ring_color = Color("#76d99b")

	if is_player_near:
		base_color = base_color.lightened(0.20)
		ring_color = ring_color.lightened(0.20)

	draw_rect(Rect2(Vector2(-54, -80), Vector2(108, 126)), base_color)
	draw_rect(Rect2(Vector2(-54, -80), Vector2(108, 126)), ring_color, false, 4.0)
	draw_arc(Vector2(0, -20), 34, 0.0, TAU, 64, ring_color, 3.0)

	var label := reward_type.to_upper()

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-48, 68),
		label,
		HORIZONTAL_ALIGNMENT_CENTER,
		96,
		14,
		ring_color
	)

	if is_player_near:
		draw_rect(Rect2(Vector2(-112, -122), Vector2(224, 32)), Color(0, 0, 0, 0.72))
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-100, -100),
			"Press E — Enter",
			HORIZONTAL_ALIGNMENT_CENTER,
			200,
			15,
			Color("#f7e8d4")
		)
