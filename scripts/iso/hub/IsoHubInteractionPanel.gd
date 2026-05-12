extends CanvasLayer
class_name IsoHubInteractionPanel

var panel_root: Control = null
var title_label: Label = null
var body_label: Label = null
var footer_label: Label = null

func _ready() -> void:
	layer = 50
	_build_ui()
	visible = false

func show_panel(title: String, body: String, footer: String = "Press E or Esc to close.") -> void:
	if panel_root == null:
		_build_ui()
	title_label.text = title
	body_label.text = body
	footer_label.text = footer
	visible = true

func close_panel() -> void:
	visible = false

func is_open() -> bool:
	return visible

func _build_ui() -> void:
	if panel_root != null:
		return

	panel_root = Control.new()
	panel_root.name = "PanelRoot"
	panel_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_root.position = Vector2(40.0, 390.0)
	panel_root.size = Vector2(560.0, 250.0)
	add_child(panel_root)

	var background: ColorRect = ColorRect.new()
	background.name = "Background"
	background.position = Vector2.ZERO
	background.size = panel_root.size
	background.color = Color(0.035, 0.027, 0.023, 0.94)
	panel_root.add_child(background)

	var border_top: ColorRect = ColorRect.new()
	border_top.name = "BorderTop"
	border_top.position = Vector2.ZERO
	border_top.size = Vector2(panel_root.size.x, 3.0)
	border_top.color = Color("#c59254")
	panel_root.add_child(border_top)

	var border_bottom: ColorRect = ColorRect.new()
	border_bottom.name = "BorderBottom"
	border_bottom.position = Vector2(0.0, panel_root.size.y - 3.0)
	border_bottom.size = Vector2(panel_root.size.x, 3.0)
	border_bottom.color = Color("#c59254")
	panel_root.add_child(border_bottom)

	var border_left: ColorRect = ColorRect.new()
	border_left.name = "BorderLeft"
	border_left.position = Vector2.ZERO
	border_left.size = Vector2(3.0, panel_root.size.y)
	border_left.color = Color("#c59254")
	panel_root.add_child(border_left)

	var border_right: ColorRect = ColorRect.new()
	border_right.name = "BorderRight"
	border_right.position = Vector2(panel_root.size.x - 3.0, 0.0)
	border_right.size = Vector2(3.0, panel_root.size.y)
	border_right.color = Color("#c59254")
	panel_root.add_child(border_right)

	title_label = Label.new()
	title_label.name = "Title"
	title_label.position = Vector2(24.0, 18.0)
	title_label.size = Vector2(512.0, 36.0)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color("#f2e4c8"))
	panel_root.add_child(title_label)

	body_label = Label.new()
	body_label.name = "Body"
	body_label.position = Vector2(24.0, 62.0)
	body_label.size = Vector2(512.0, 132.0)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", Color("#d7c5aa"))
	panel_root.add_child(body_label)

	footer_label = Label.new()
	footer_label.name = "Footer"
	footer_label.position = Vector2(24.0, 208.0)
	footer_label.size = Vector2(512.0, 26.0)
	footer_label.add_theme_font_size_override("font_size", 14)
	footer_label.add_theme_color_override("font_color", Color("#c59254"))
	panel_root.add_child(footer_label)
