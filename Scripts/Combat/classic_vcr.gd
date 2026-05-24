class_name ClassicVcr
extends RefCounted

var battle_seed: int = 1
var expanded_rng: bool = false
var signature: int = 0
var battle_type: int = CombatConstants.SHIP_TO_SHIP
var left: CombatObject = CombatObject.new()
var right: CombatObject = CombatObject.new()
var left_fleet: Array[CombatObject] = []
var right_fleet: Array[CombatObject] = []

func duplicate_vcr() -> ClassicVcr:
	var v: ClassicVcr = ClassicVcr.new()
	v.battle_seed = battle_seed
	v.expanded_rng = expanded_rng
	v.signature = signature
	v.battle_type = battle_type
	v.left = left.duplicate_object()
	v.right = right.duplicate_object()
	v.left_fleet = _duplicate_fleet(left_fleet)
	v.right_fleet = _duplicate_fleet(right_fleet)
	v.ensure_fleets()
	return v


func ensure_fleets() -> void:
	if left_fleet.is_empty() and left != null:
		left_fleet = [left.duplicate_object()]
	if right_fleet.is_empty() and right != null:
		right_fleet = [right.duplicate_object()]


func set_single_combatants(left_obj: CombatObject, right_obj: CombatObject) -> void:
	left = left_obj
	right = right_obj
	left_fleet = [left_obj.duplicate_object()]
	right_fleet = [right_obj.duplicate_object()]


func _duplicate_fleet(source: Array[CombatObject]) -> Array[CombatObject]:
	var result: Array[CombatObject] = []
	for obj: CombatObject in source:
		result.append(obj.duplicate_object())
	return result
