@tool
extends Node2D
class_name IsoYSortGroup

@export var enabled_on_ready: bool = true

func _ready() -> void:
	if enabled_on_ready:
		y_sort_enabled = true
