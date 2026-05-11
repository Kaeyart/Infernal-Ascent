from pathlib import Path
import re
import shutil

PROJECT = Path(".")
NEW_SCENE = 'res://scenes/props/ChoiceDoor.tscn'
OLD_SCENES = [
    'res://scenes/run/ChoiceDoor.tscn',
    'res://scenes/rooms/ChoiceDoor.tscn',
]
OLD_SCRIPTS = [
    'res://scripts/rooms/ChoiceDoor.gd',
]

# Force new prop files into place from unpacked zip contents.
Path("scripts/props").mkdir(parents=True, exist_ok=True)
Path("scenes/props").mkdir(parents=True, exist_ok=True)

# Replace hard references in all scripts/scenes.
targets = list(Path("scripts").rglob("*.gd")) + list(Path("scenes").rglob("*.tscn"))

for path in targets:
    text = path.read_text()

    original = text

    for old_scene in OLD_SCENES:
        text = text.replace(old_scene, NEW_SCENE)

    for old_script in OLD_SCRIPTS:
        text = text.replace(old_script, "res://scripts/props/ChoiceDoor.gd")

    # Also catch loose preload variants.
    text = re.sub(
        r'const\s+ChoiceDoorScene\s*:?=\s*preload\("res://[^"]*ChoiceDoor\.tscn"\)',
        f'const ChoiceDoorScene := preload("{NEW_SCENE}")',
        text
    )

    if path.name == "CombatRoom.gd":
        if "func _get_choice_door_sockets" not in text:
            helper = """
func _get_choice_door_sockets(offer_count: int) -> Array[Dictionary]:
	var template := _get_current_room_template()
	var room_rect: Rect2 = template.get("room_rect", arena_rect)
	var center := room_rect.get_center()

	if offer_count <= 1:
		return [
			{"position": Vector2(center.x, room_rect.position.y + room_rect.size.y - 70.0), "orientation": "south"}
		]

	match room_layout_type:
		"cross_hall":
			return [
				{"position": Vector2(640, 166), "orientation": "north"},
				{"position": Vector2(316, 350), "orientation": "west"},
				{"position": Vector2(964, 350), "orientation": "east"}
			]
		"reliquary_chamber":
			return [
				{"position": Vector2(640, 180), "orientation": "north"},
				{"position": Vector2(240, 345), "orientation": "west"},
				{"position": Vector2(1040, 345), "orientation": "east"}
			]
		"chapel_box":
			return [
				{"position": Vector2(640, 154), "orientation": "north"},
				{"position": Vector2(250, 352), "orientation": "west"},
				{"position": Vector2(1030, 352), "orientation": "east"}
			]
		"pillar_hall":
			return [
				{"position": Vector2(640, 154), "orientation": "north"},
				{"position": Vector2(228, 352), "orientation": "west"},
				{"position": Vector2(1052, 352), "orientation": "east"}
			]
		"blood_pit":
			return [
				{"position": Vector2(640, 158), "orientation": "north"},
				{"position": Vector2(244, 352), "orientation": "west"},
				{"position": Vector2(1036, 352), "orientation": "east"}
			]
		"boss_sanctum":
			return [
				{"position": Vector2(640, 166), "orientation": "north"},
				{"position": Vector2(232, 356), "orientation": "west"},
				{"position": Vector2(1048, 356), "orientation": "east"}
			]
		_:
			return [
				{"position": Vector2(center.x, room_rect.position.y + 72.0), "orientation": "north"},
				{"position": Vector2(room_rect.position.x + 72.0, center.y), "orientation": "west"},
				{"position": Vector2(room_rect.position.x + room_rect.size.x - 72.0, center.y), "orientation": "east"}
			]


"""
            text = text.replace("\nfunc _spawn_choice_doors() -> void:\n", "\n" + helper + "func _spawn_choice_doors() -> void:\n")

        new_spawn = """func _spawn_choice_doors() -> void:
	if not choice_doors.is_empty():
		return

	var offers: Array[String] = RunState.generate_offers_after_clear()

	if offers.is_empty():
		return

	var sockets: Array[Dictionary] = _get_choice_door_sockets(offers.size())

	for i in range(offers.size()):
		var offered_room_type: String = str(offers[i])
		var socket: Dictionary = sockets[i % sockets.size()]

		var door := ChoiceDoorScene.instantiate() as Node2D
		door.global_position = socket.get("position", Vector2(640, 520))
		add_child(door)

		if door.has_method("setup"):
			door.setup(offered_room_type, str(socket.get("orientation", "south")))

		if door.has_signal("room_choice_requested"):
			door.room_choice_requested.connect(_on_choice_door_selected)

		choice_doors.append(door)


"""
        text = re.sub(
            r"func _spawn_choice_doors\(\) -> void:\n.*?\nfunc _on_choice_door_selected",
            new_spawn + "func _on_choice_door_selected",
            text,
            flags=re.S
        )

    if text != original:
        path.write_text(text)
        print(f"patched {path}")

# Optional: make old scene visually impossible to use by moving it aside, only if it exists.
# We do NOT delete it; project rollback stays possible.
for old in [Path("scenes/run/ChoiceDoor.tscn")]:
    if old.exists():
        disabled = old.with_suffix(".tscn.disabled")
        shutil.copyfile(old, disabled)
        print(f"backup copy made: {disabled}")

print("\\nRemaining ChoiceDoor references:")
for path in targets:
    if path.exists():
        text = path.read_text()
        if "ChoiceDoor" in text:
            for i, line in enumerate(text.splitlines(), start=1):
                if "ChoiceDoor" in line:
                    print(f"{path}:{i}: {line}")
