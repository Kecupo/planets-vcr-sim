class_name CombatState
extends RefCounted

class SideState:
	extends RefCounted

	var obj: CombatObject = CombatObject.new()
	var beam_status: PackedInt32Array = PackedInt32Array()
	var torp_status: PackedInt32Array = PackedInt32Array()
	var fighter_active: PackedInt32Array = PackedInt32Array()
	var fighter_x: PackedInt32Array = PackedInt32Array()
	var cur_x: int = 0
	var side: int = CombatTypes.Side.LEFT
	var num_fighters_out: int = 0
	var initial_shield: int = 100
	var initial_crew: int = 0

	func setup(p_obj: CombatObject, p_side: int) -> void:
		obj = p_obj.duplicate_object()
		side = p_side
		cur_x = 0
		num_fighters_out = 0
		initial_shield = obj.shield
		initial_crew = obj.crew

		beam_status = PackedInt32Array()
		torp_status = PackedInt32Array()
		fighter_active = PackedInt32Array()
		fighter_x = PackedInt32Array()

		beam_status.resize(CombatConstants.MAX_BEAMS)
		torp_status.resize(CombatConstants.MAX_TORPS)
		fighter_active.resize(CombatConstants.MAX_FIGHTERS)
		fighter_x.resize(CombatConstants.MAX_FIGHTERS)

		for i: int in range(CombatConstants.MAX_BEAMS):
			beam_status[i] = 0
			torp_status[i] = 0
		for i: int in range(CombatConstants.MAX_FIGHTERS):
			fighter_active[i] = CombatConstants.FIGHTER_IDLE
			fighter_x[i] = 0

var left: SideState = SideState.new()
var right: SideState = SideState.new()
var time: int = 0
var status_word: int = CombatConstants.VCRS_NONE
var battle_type: int = CombatConstants.SHIP_TO_SHIP
var rounding_mode: CombatTypes.RoundingMode = CombatTypes.RoundingMode.IEEE_NEAREST_EVEN
