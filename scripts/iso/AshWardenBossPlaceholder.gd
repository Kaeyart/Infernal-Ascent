extends Node2D

## V23.3 fallback file. The boss arena placeholder is currently implemented through RunRoomInteractable.
## This file remains only to avoid missing-file confusion if an older local reference exists.

func setup(spawn_position: Vector2) -> void:
	global_position = spawn_position
