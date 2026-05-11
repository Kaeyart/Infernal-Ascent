extends Node2D

@export var prop_id: String = "reward"
@export var sprite_scale: Vector2 = Vector2(0.30, 0.30)
@export var bob_amount: float = 3.0
@export var bob_speed: float = 1.6
@export var glow_enabled: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var base_sprite_position: Vector2 = Vector2.ZERO
var visual_time: float = 0.0


func setup(new_prop_id: String, label_text: String = "") -> void:
    prop_id = new_prop_id
    _load_texture()

    if label != null:
        label.text = label_text if label_text != "" else _get_default_label()


func _ready() -> void:
    add_to_group("special_room_prop")
    z_index = 80

    if sprite != null:
        sprite.centered = true
        sprite.scale = sprite_scale
        base_sprite_position = sprite.position

    if label != null:
        label.position = Vector2(-92, 74)
        label.size = Vector2(184, 26)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.add_theme_font_size_override("font_size", 14)
        label.add_theme_color_override("font_color", _get_prop_color())
        label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
        label.add_theme_constant_override("shadow_offset_x", 2)
        label.add_theme_constant_override("shadow_offset_y", 2)

    _load_texture()
    set_process(true)


func _process(delta: float) -> void:
    visual_time += delta

    if sprite != null:
        var bob := sin(visual_time * bob_speed) * bob_amount
        sprite.position = base_sprite_position + Vector2(0, bob)

        if glow_enabled:
            var pulse := 0.70 + 0.20 * absf(sin(visual_time * 2.25))
            var color := _get_prop_color()
            sprite.modulate = Color(
                lerpf(1.0, color.r, 0.14),
                lerpf(1.0, color.g, 0.14),
                lerpf(1.0, color.b, 0.14),
                pulse
            )
        else:
            sprite.modulate = Color.WHITE


func _load_texture() -> void:
    if sprite == null:
        return

    var path := "res://art/props/special_rooms/%s.png" % prop_id

    if not ResourceLoader.exists(path):
        path = "res://art/props/special_rooms/reward.png"

    if not ResourceLoader.exists(path):
        push_warning("Missing SpecialRoomProp asset: %s" % prop_id)
        return

    var texture := load(path) as Texture2D

    if texture != null:
        sprite.texture = texture


func _get_default_label() -> String:
    match prop_id:
        "forge":
            return "Forge"
        "fountain":
            return "Fountain"
        "shrine":
            return "Shrine"
        "shop":
            return "Shop"
        "reward":
            return "Reward"
        _:
            return prop_id.capitalize()


func _get_prop_color() -> Color:
    match prop_id:
        "forge":
            return Color("#ff684a")
        "fountain":
            return Color("#b49ce2")
        "shrine":
            return Color("#dfaa46")
        "shop":
            return Color("#7fdc54")
        "reward":
            return Color("#ffd36a")
        _:
            return Color("#f7e8d4")
