class_name ClassicVcr
extends RefCounted

var battle_seed: int = 1
var signature: int = 0
var battle_type: int = CombatConstants.SHIP_TO_SHIP
var left: CombatObject = CombatObject.new()
var right: CombatObject = CombatObject.new()

func duplicate_vcr() -> ClassicVcr:
	var v: ClassicVcr = ClassicVcr.new()
	v.battle_seed = battle_seed
	v.signature = signature
	v.battle_type = battle_type
	v.left = left.duplicate_object()
	v.right = right.duplicate_object()
	return v
