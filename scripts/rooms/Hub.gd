extends Node2D

signal enter_run_requested()

var interact_hint := ""
var selected_weapon: WeaponData = null

func _ready() -> void:
	for pedestal in get_tree().get_nodes_in_group("weapon_pedestals"):
		pedestal.weapon_selected.connect(_on_weapon_selected)
	for child in get_children():
		if child.has_signal("weapon_selected"):
			child.weapon_selected.connect(_on_weapon_selected)

	queue_redraw()
func _on_weapon_selected(weapon: WeaponData) -> void:
	selected_weapon = weapon
	GameState.selected_weapon = weapon

	var player := $Player
	var weapon_controller = player.get_node_or_null("WeaponController")

	if weapon_controller:
		weapon_controller.set_weapon(weapon)

	interact_hint = "Equipped: " + weapon.display_name
	queue_redraw()

func _process(_delta: float) -> void:
	var player := $Player
	interact_hint = ""

	var gate := Vector2(640, 170)
	var weapon_hall := Vector2(260, 520)
	var aspect_chamber := Vector2(1020, 520)

	if player.global_position.distance_to(gate) < 95:
		interact_hint = "Press E — Enter Inferno test room"

		if Input.is_action_just_pressed("interact"):
			enter_run_requested.emit()

	elif player.global_position.distance_to(weapon_hall) < 95:
		interact_hint = "Weapon Hall placeholder"

	elif player.global_position.distance_to(aspect_chamber) < 95:
		interact_hint = "Aspect Chamber placeholder"

	queue_redraw()

func _draw() -> void:
	# Big obvious background.
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("#10090b"))

	# Outer room frame.
	draw_rect(Rect2(Vector2(60, 60), Vector2(1160, 600)), Color("#f7e8d4"), false, 4.0)

	# Floor grid.
	for x in range(100, 1220, 80):
		draw_line(Vector2(x, 80), Vector2(x, 660), Color(1, 1, 1, 0.06), 1.0)

	for y in range(100, 660, 80):
		draw_line(Vector2(80, y), Vector2(1200, y), Color(1, 1, 1, 0.06), 1.0)

	# Hell doors.
	draw_circle(Vector2(640, 170), 86, Color("#2b1114"))
	draw_circle(Vector2(640, 170), 54, Color("#d64a2f").darkened(0.35), false, 5.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(575, 176),
		"HELL DOORS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color("#f7e8d4")
	)

	# Weapon hall.
	draw_circle(Vector2(260, 520), 64, Color("#21151a"))
	draw_circle(Vector2(260, 520), 42, Color("#dfaa46").darkened(0.35), false, 4.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(198, 526),
		"WEAPON HALL",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#dfaa46")
	)

	# Aspect chamber.
	draw_circle(Vector2(1020, 520), 64, Color("#21151a"))
	draw_circle(Vector2(1020, 520), 42, Color("#b49ce2").darkened(0.35), false, 4.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(946, 526),
		"ASPECT ROOM",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#b49ce2")
	)

	# Upgrade altar.
	draw_circle(Vector2(220, 190), 54, Color("#2b1810"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(166, 196),
		"UPGRADES",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#f0b24f")
	)

	# Personal archive.
	draw_circle(Vector2(1060, 190), 54, Color("#16131d"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(988, 196),
		"PERSONAL",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#9ed8cd")
	)

	# Respawn platform.
	draw_circle(Vector2(640, 500), 72, Color("#d64a2f").darkened(0.55))
	draw_circle(Vector2(640, 500), 48, Color("#f7e8d4"), false, 3.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(570, 588),
		"RESPAWN PLATFORM",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#c4a98f")
	)

	# Title.
	draw_string(
		ThemeDB.fallback_font,
		Vector2(30, 34),
		"Hub scaffold — visible room layout test",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#f7e8d4")
	)

	if interact_hint != "":
		draw_rect(Rect2(Vector2(420, 620), Vector2(440, 44)), Color(0, 0, 0, 0.70))
		draw_string(
			ThemeDB.fallback_font,
			Vector2(450, 648),
			interact_hint,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color("#f7e8d4")
		)
