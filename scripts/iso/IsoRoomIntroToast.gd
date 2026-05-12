extends Control

class_name IsoRoomIntroToast

@export var toast_duration: float = 2.2
@export var fade_duration: float = 0.35

var _title_label: Label = null
var _subtitle_label: Label = null
var _backing: ColorRect = null
var _remaining: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchors_preset = Control.PRESET_FULL_RECT
	_build_ui()
	visible = false

func show_intro(title: String, subtitle: String = "") -> void:
	if _title_label == null:
		_build_ui()
	_title_label.text = title
	_subtitle_label.text = subtitle
	_remaining = toast_duration
	visible = true
	modulate.a = 1.0

func _process(delta: float) -> void:
	if not visible:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		visible = false
		return
	if _remaining < fade_duration:
		modulate.a = clampf(_remaining / fade_duration, 0.0, 1.0)
	else:
		modulate.a = 1.0

func _build_ui() -> void:
	if _backing != null:
		return
	_backing = ColorRect.new()
	_backing.name = "IntroBacking"
	_backing.position = Vector2(18.0, 34.0)
	_backing.size = Vector2(430.0, 76.0)
	_backing.color = Color(0.02, 0.014, 0.010, 0.82)
	add_child(_backing)
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.position = Vector2(34.0, 44.0)
	_title_label.size = Vector2(398.0, 26.0)
	add_child(_title_label)
	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.position = Vector2(34.0, 72.0)
	_subtitle_label.size = Vector2(398.0, 24.0)
	add_child(_subtitle_label)
