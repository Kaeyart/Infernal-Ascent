extends Node2D

signal upgrade_selected(upgrade_data: RunUpgradeData)

@export var interact_radius := 90.0

var upgrade_data: RunUpgradeData = null
var player: Node2D = null
var is_player_near := false
var is_selected := false

func setup(new_upgrade_data: RunUpgradeData) -> void:
	upgrade_data = new_upgrade_data
	queue_redraw()

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	if is_selected:
		return

	player = get_tree().get_first_node_in_group("player") as Node2D
	is_player_near = false

	if player:
		is_player_near = global_position.distance_to(player.global_position) <= interact_radius

		if is_player_near and Input.is_action_just_pressed("interact"):
			is_selected = true
			upgrade_selected.emit(upgrade_data)

	queue_redraw()

func _draw() -> void:
	var card_color := Color("#1d1516")
	var border_color := _get_rarity_color()
	var text_color := Color("#f7e8d4")
	var muted_color := Color("#c4a98f")

	if is_player_near:
		card_color = card_color.lightened(0.14)
		border_color = border_color.lightened(0.20)

	draw_rect(Rect2(Vector2(-105, -72), Vector2(210, 144)), card_color)
	draw_rect(Rect2(Vector2(-105, -72), Vector2(210, 144)), border_color, false, 4.0)
	draw_rect(Rect2(Vector2(-94, -60), Vector2(188, 28)), Color(0, 0, 0, 0.25))

	var title := "Upgrade"
	var rarity := "Common"
	var description := ""

	if upgrade_data != null:
		title = upgrade_data.display_name
		rarity = upgrade_data.rarity
		description = upgrade_data.description

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-90, -41),
		title,
		HORIZONTAL_ALIGNMENT_CENTER,
		180,
		16,
		text_color
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(-90, -16),
		rarity.to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER,
		180,
		12,
		border_color
	)

	var lines := _wrap_text(description, 24)
	for i in range(mini(lines.size(), 3)):
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-86, 13 + i * 17),
			lines[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			172,
			13,
			muted_color
		)

	if is_player_near:
		draw_rect(Rect2(Vector2(-70, 85), Vector2(140, 28)), Color(0, 0, 0, 0.72))
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-66, 104),
			"Press E — Choose",
			HORIZONTAL_ALIGNMENT_CENTER,
			132,
			13,
			text_color
		)

func _get_rarity_color() -> Color:
	if upgrade_data == null:
		return Color("#dfaa46")

	match upgrade_data.rarity:
		"Common":
			return Color("#dfaa46")
		"Uncommon":
			return Color("#9ed8cd")
		"Rare":
			return Color("#b49ce2")
		_:
			return Color("#dfaa46")

func _wrap_text(text: String, max_chars: int) -> Array[String]:
	var words := text.split(" ")
	var lines: Array[String] = []
	var current := ""

	for word in words:
		var candidate := word

		if current != "":
			candidate = current + " " + word

		if candidate.length() > max_chars and current != "":
			lines.append(current)
			current = word
		else:
			current = candidate

	if current != "":
		lines.append(current)

	return lines
