from pathlib import Path
import re

path = Path("scripts/rooms/CombatRoom.gd")
if not path.exists():
    raise SystemExit("Missing scripts/rooms/CombatRoom.gd")

text = path.read_text()
original = text

# Add preload.
if "SpecialRoomPropScene" not in text:
    marker = 'const UpgradeCardScene := preload("res://scenes/ui/UpgradeCard.tscn")'
    if marker in text:
        text = text.replace(
            marker,
            marker + '\nconst SpecialRoomPropScene := preload("res://scenes/props/SpecialRoomProp.tscn")'
        )
    else:
        text = 'const SpecialRoomPropScene := preload("res://scenes/props/SpecialRoomProp.tscn")\n' + text

# Add variable.
if "var special_room_prop" not in text:
    marker = "var upgrade_cards: Array[Node2D] = []"
    if marker in text:
        text = text.replace(marker, marker + "\nvar special_room_prop: Node2D = null")

helpers = """
func _get_special_prop_id_for_room_type() -> String:
	match room_type:
		RunState.ROOM_FORGE:
			return "forge"
		RunState.ROOM_SHRINE:
			return "shrine"
		RunState.ROOM_SHOP:
			return "shop"
		RunState.ROOM_FOUNTAIN:
			return "fountain"
		RunState.ROOM_BOSS:
			return "reward"
		_:
			return "reward"


func _spawn_special_room_prop(prop_id: String) -> void:
	if special_room_prop != null and is_instance_valid(special_room_prop):
		return

	special_room_prop = SpecialRoomPropScene.instantiate() as Node2D

	if special_room_prop == null:
		return

	special_room_prop.global_position = reward_position
	special_room_prop.z_index = 90
	add_child(special_room_prop)

	if special_room_prop.has_method("setup"):
		var label_text := RunState.get_room_display_name(room_type)
		special_room_prop.call("setup", prop_id, label_text)


func _clear_special_room_prop() -> void:
	if special_room_prop != null and is_instance_valid(special_room_prop):
		special_room_prop.queue_free()

	special_room_prop = null


"""

if "func _get_special_prop_id_for_room_type" not in text:
    text = text.replace("\nfunc _spawn_post_clear_reward() -> void:\n", "\n" + helpers + "\nfunc _spawn_post_clear_reward() -> void:\n")

# Add special prop spawn into _spawn_post_clear_reward.
if "_spawn_special_room_prop(_get_special_prop_id_for_room_type())" not in text:
    text = re.sub(
        r'(func _spawn_post_clear_reward\(\) -> void:\n.*?reward_position = _get_template_vector\("reward_position", Vector2\(640, 330\)\)\n)',
        r'\1\n\t_clear_special_room_prop()\n',
        text,
        flags=re.S
    )

    pattern = r'(func _spawn_post_clear_reward\(\) -> void:\n.*?\n)(func _spawn_boon_offers\(\) -> void:)'
    match = re.search(pattern, text, flags=re.S)
    if match:
        body = match.group(1).rstrip() + """

	if reward_available:
		_spawn_special_room_prop(_get_special_prop_id_for_room_type())

"""
        text = text[:match.start()] + body + "\n" + match.group(2) + text[match.end():]

# Clear prop when reward claimed.
claim_match = re.search(r"func _claim_object_reward\(\) -> void:\n.*?\nfunc ", text, re.S)
if claim_match and "_clear_special_room_prop()" not in claim_match.group(0):
    text = re.sub(
        r"(func _claim_object_reward\(\) -> void:\n.*?reward_available = false\n)",
        r"\1\t_clear_special_room_prop()\n",
        text,
        flags=re.S
    )

# Replace _draw_object_reward body with pass so old circle/icon reward disappears.
text = re.sub(
    r"func _draw_object_reward\(\) -> void:\n.*?\n\nfunc _draw_hint\(\) -> void:",
    "func _draw_object_reward() -> void:\n\tpass\n\n\nfunc _draw_hint() -> void:",
    text,
    flags=re.S
)

if text != original:
    path.write_text(text)
    print("Patched CombatRoom.gd for SpecialRoomProp.")
else:
    print("No changes made to CombatRoom.gd.")
