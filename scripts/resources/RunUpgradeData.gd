extends Resource
class_name RunUpgradeData

@export var upgrade_id: String = ""
@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""
@export_enum("Common", "Uncommon", "Rare") var rarity: String = "Common"
@export var effect_type: String = ""
@export var flat_value: float = 0.0
@export var multiplier_value: float = 1.0
