extends Node2D

signal enter_requested()

@export var interaction_radius: float = 86.0
@export var sprite_scale: Vector2 = Vector2(0.16, 0.16)
@export var prompt_offset: Vector2 = Vector2(-90, 76)

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel

var player: Node2D = null
var player_near: bool = false
var pulse_time: float = 0.0


func _ready() -> void:
    add_to_group("hell_gate")
    z_index = 200

    if sprite != null:
        sprite.scale = sprite_scale
        sprite.centered = true

    if prompt_label != null:
        prompt_label.visible = false
        prompt_label.position = prompt_offset

    set_process(true)


func _process(delta: float) -> void:
    pulse_time += delta

    if player == null or not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player") as Node2D

    player_near = false

    if player != null:
        player_near = global_position.distance_to(player.global_position) <= interaction_radius

        if player_near and _is_interact_pressed():
            enter_requested.emit()

    _update_visuals()


func _is_interact_pressed() -> bool:
    if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
        return true

    return Input.is_physical_key_pressed(KEY_E)


func _update_visuals() -> void:
    var pulse: float = 0.55 + 0.25 * absf(sin(pulse_time * 2.4))

    if sprite != null:
        sprite.modulate = Color(
            1.0,
            0.86 + pulse * 0.14,
            0.74 + pulse * 0.12,
            1.0
        )

    if prompt_label != null:
        prompt_label.visible = player_near
