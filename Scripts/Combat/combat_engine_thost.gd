class_name CombatEngineThost
extends RefCounted
signal beam_hit_fighter(attacker_side: int, from_x: int, target_side: int, target_index: int)
signal cycle_completed(time: int)
signal battle_finished(status_word: int)
signal fighter_intercept_beam(attacker_side: int, attacker_index: int, target_index: int)
signal fighter_launched(side: int, track_id: int)
signal fighter_landed(side: int, track_id: int)
signal fighter_killed(side: int, track_id: int)
signal beam_fired(side: int, from_x: int, to_x: int, from_is_fighter: bool, track_id: int)
signal torpedo_fired(side: int, from_x: int, to_x: int, hit: bool)
signal hit_resolved(side: int, shield: int, damage: int, crew: int)

var state: CombatState = CombatState.new()
var rng: CombatRngThost = CombatRngThost.new()

func _get_beam_damage(beam_id: int) -> int:
	return ShipData.get_beam_damage(beam_id)


func _get_beam_kill(beam_id: int) -> int:
	return ShipData.get_beam_kill(beam_id)


func _get_torp_damage(torp_id: int) -> int:
	return ShipData.get_torp_damage(torp_id)


func _get_torp_kill(torp_id: int) -> int:
	return ShipData.get_torp_kill(torp_id)
	
func init_vcr(vcr: ClassicVcr) -> void:
	vcr.ensure_fleets()
	state = CombatState.new()
	state.time = 0
	state.status_word = CombatConstants.VCRS_NONE
	state.battle_type = vcr.battle_type
	state.rounding_mode = CombatTypes.RoundingMode.IEEE_NEAREST_EVEN

	state.left.setup(vcr.left, CombatTypes.Side.LEFT)
	state.right.setup(vcr.right, CombatTypes.Side.RIGHT)
	if state.left.obj.torp_type > 0:
		state.left.obj.torp_range = ShipData.get_torp_range(state.left.obj.torp_type)

	if state.right.obj.torp_type > 0:
		state.right.obj.torp_range = ShipData.get_torp_range(state.right.obj.torp_type)
		
	state.left.cur_x = 30
	state.right.cur_x = 610 if vcr.battle_type == CombatConstants.SHIP_TO_SHIP else 570

	rng.set_seed(vcr.battle_seed)

	_preload_weapons(state.left)
	_preload_weapons(state.right)


func play_cycle() -> bool:
	if state.status_word != CombatConstants.VCRS_NONE:
		return false

	if state.left.obj.damage >= state.left.obj.damage_limit:
		if _restart_squadron_if_possible(state.left):
			return true
		return false
	if state.right.obj.damage >= state.right.obj.damage_limit:
		if _restart_squadron_if_possible(state.right):
			return true
		return false

	if state.left.obj.crew <= 0:
		if _restart_squadron_if_possible(state.left):
			return true
		return false
	if state.right.obj.crew <= 0 and not state.right.obj.is_planet:
		if _restart_squadron_if_possible(state.right):
			return true
		return false

	if state.time >= 2000:
		return false

	state.time += 1

	var distance: int = state.right.cur_x - state.left.cur_x
	if distance > 30:
		state.left.cur_x += 1
		distance -= 1

		if not state.right.obj.is_planet:
			state.right.cur_x -= 1
			distance -= 1

	if distance < 200:
		_fire_beams(state.left, state.right)

	_fire_beams_at_fighter(state.left, state.right)
	_fire_beams_at_fighter(state.right, state.left)

	if distance < 200:
		_fire_beams(state.right, state.left)

	if distance < state.left.obj.torp_range:
		_fire_torpedoes(state.left, state.right)
	if distance < state.right.obj.torp_range:
		_fire_torpedoes(state.right, state.left)

	_launch_fighters(state.left)
	_launch_fighters(state.right)

	if state.left.num_fighters_out > 0 or state.right.num_fighters_out > 0:
		_fighter_stuff()

	_recharge_beams(state.left)
	_recharge_beams(state.right)

	emit_signal("cycle_completed", state.time)
	return true


func finish_battle() -> void:
	for i: int in range(CombatConstants.MAX_FIGHTERS):
		if state.left.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
			state.left.obj.fighter_count += 1
			state.left.fighter_active[i] = CombatConstants.FIGHTER_IDLE
			state.left.num_fighters_out -= 1

		if state.right.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
			state.right.obj.fighter_count += 1
			state.right.fighter_active[i] = CombatConstants.FIGHTER_IDLE
			state.right.num_fighters_out -= 1

	state.status_word = _compute_result_status()
	emit_signal("battle_finished", state.status_word)


func _compute_result_status() -> int:
	var result: int = CombatConstants.VCRS_NONE

	if state.right.obj.is_planet:
		if state.left.obj.damage >= 100 or state.left.obj.crew <= 0:
			result |= CombatConstants.VCRS_LEFT_DESTROYED
		if state.right.obj.damage >= 100:
			result |= CombatConstants.VCRS_RIGHT_DESTROYED
	else:
		if state.left.obj.damage >= state.left.obj.damage_limit:
			result |= CombatConstants.VCRS_LEFT_DESTROYED
		elif state.left.obj.is_squadron and state.left.obj.crew <= 0:
			result |= CombatConstants.VCRS_LEFT_DESTROYED
		elif state.left.obj.crew <= 0:
			if state.left.obj.damage < state.left.obj.damage_limit:
				result |= CombatConstants.VCRS_LEFT_CAPTURED
			else:
				result |= CombatConstants.VCRS_LEFT_DESTROYED

		if state.right.obj.damage >= state.right.obj.damage_limit:
			result |= CombatConstants.VCRS_RIGHT_DESTROYED
		elif state.right.obj.is_squadron and state.right.obj.crew <= 0:
			result |= CombatConstants.VCRS_RIGHT_DESTROYED
		elif state.right.obj.crew <= 0:
			if state.right.obj.damage < state.right.obj.damage_limit:
				result |= CombatConstants.VCRS_RIGHT_CAPTURED
			else:
				result |= CombatConstants.VCRS_RIGHT_DESTROYED

	if result == CombatConstants.VCRS_NONE:
		result = CombatConstants.VCRS_TIMEOUT

	return result


func _restart_squadron_if_possible(side: CombatState.SideState) -> bool:
	if not side.obj.is_squadron:
		return false
	if side.obj.beam_count <= 1:
		return false

	_recover_active_fighters(state.left)
	_recover_active_fighters(state.right)

	side.obj.beam_count -= 1
	side.obj.damage = 0
	side.obj.shield = side.initial_shield
	side.obj.crew = side.initial_crew
	side.num_fighters_out = 0
	side.cur_x = 30 if side.side == CombatTypes.Side.LEFT else (610 if state.battle_type == CombatConstants.SHIP_TO_SHIP else 570)

	for i: int in range(CombatConstants.MAX_BEAMS):
		side.beam_status[i] = 100 if i < side.obj.beam_count else 0
		side.torp_status[i] = 30 if i < side.obj.torp_launcher_count else 0
	for i: int in range(CombatConstants.MAX_FIGHTERS):
		side.fighter_active[i] = CombatConstants.FIGHTER_IDLE
		side.fighter_x[i] = 0

	if side.side == CombatTypes.Side.LEFT:
		state.right.cur_x = 610 if state.battle_type == CombatConstants.SHIP_TO_SHIP else 570
	else:
		state.left.cur_x = 30

	emit_signal("hit_resolved", side.side, side.obj.shield, side.obj.damage, side.obj.crew)
	return true


func _recover_active_fighters(side: CombatState.SideState) -> void:
	for i: int in range(CombatConstants.MAX_FIGHTERS):
		if side.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
			side.obj.fighter_count += 1
			side.fighter_active[i] = CombatConstants.FIGHTER_IDLE
			side.fighter_x[i] = 0
	side.num_fighters_out = 0


func _preload_weapons(side: CombatState.SideState) -> void:
	if side.obj.shield >= 100 or (side.obj.race_id == 12 and side.obj.damage <= 0):
		for i: int in range(CombatConstants.MAX_BEAMS):
			side.torp_status[i] = 30
			side.beam_status[i] = 100


func _recharge_beams(side: CombatState.SideState) -> void:
	for i: int in range(side.obj.beam_count):
		var charge: int = side.beam_status[i]
		if rng.random_1_100() > 50 and charge < 100:
			side.beam_status[i] = min(100, charge + side.obj.beam_charge_rate)


func _fire_beams(side: CombatState.SideState, opp: CombatState.SideState) -> void:
	for i: int in range(side.obj.beam_count):
		var pick: int = rng.random_1_20()
		if pick < 7 and side.beam_status[i] > 50:
			_fire_beam(side, opp, i)

func _fire_beam(side: CombatState.SideState, opp: CombatState.SideState, which: int) -> void:
	var charge: int = side.beam_status[which]
	var beam_damage: int = _get_beam_damage(side.obj.beam_type)
	var beam_kill: int = _get_beam_kill(side.obj.beam_type)

	var damage: int = rdivadd(charge * beam_damage, 100, 0, state.rounding_mode)
	var kill: int = rdivadd(charge * beam_kill, 100, 0, state.rounding_mode) * side.obj.beam_kill_rate

	emit_signal("beam_fired", side.side, side.cur_x, opp.cur_x, false, -1)
	_hit(opp, damage, kill)

	side.beam_status[which] = 0
	
func _fire_beams_at_fighter(side: CombatState.SideState, opp: CombatState.SideState) -> void:
	if opp.num_fighters_out <= 0:
		rng.advance_beam_fighter_skip(side.obj.beam_count)
		return

	for i: int in range(side.obj.beam_count):
		var pick: int = rng.random_1_20()
		if side.beam_status[i] > 40 and pick < 5:
			var target_index: int = _fire_at_fighter(side, opp, i)
			if target_index >= 0:
				emit_signal("beam_hit_fighter", side.side, side.cur_x, opp.side, target_index)

func _fire_at_fighter(side: CombatState.SideState, opp: CombatState.SideState, beam_index: int) -> int:
	var best_index: int = -1
	var best_dist: int = 999999

	for i: int in range(CombatConstants.MAX_FIGHTERS):
		if opp.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
			var dist: int = abs(opp.fighter_x[i] - side.cur_x)
			if dist < best_dist:
				best_dist = dist
				best_index = i

	if best_index < 0:
		return -1

	opp.fighter_active[best_index] = CombatConstants.FIGHTER_IDLE
	opp.num_fighters_out -= 1
	side.beam_status[beam_index] = 0

	emit_signal("fighter_killed", opp.side, best_index)
	return best_index


func _fire_torpedoes(side: CombatState.SideState, opp: CombatState.SideState) -> void:
	for i: int in range(side.obj.torp_launcher_count):
		if side.obj.torp_count > 0:
			var n: int = rng.random_1_17()
			if side.torp_status[i] > 40 or (side.torp_status[i] > 30 and n < side.obj.torp_type):
				side.obj.torp_count -= 1
				side.torp_status[i] = 0
				_fire_torp(side, opp, i)

			side.torp_status[i] += side.obj.torp_charge_rate

func _fire_torp(side: CombatState.SideState, opp: CombatState.SideState, _launcher: int) -> void:
	var n: int = rng.random_1_100()
	var hit: bool = n >= _torpedo_miss_rate_against_target(side, opp)

	emit_signal("torpedo_fired", side.side, side.cur_x, opp.cur_x, hit)

	if hit:
		var torp_damage: int = _get_torp_damage(side.obj.torp_type)
		var torp_kill: int = _get_torp_kill(side.obj.torp_type)
		_hit_torp(opp, torp_damage, torp_kill)


func _torpedo_miss_rate_against_target(side: CombatState.SideState, opp: CombatState.SideState) -> int:
	if opp.obj.is_elusive:
		return 91
	if ShipData.gravitonic_quantum_elusive_enabled \
	and opp.obj.has_gravitonic_accelerator \
	and ShipData.is_quantum_torp(side.obj.torp_type):
		return ShipData.quantum_torpedo_miss_rate_for_gravitonics + 1
	return side.obj.torp_miss_rate

func _launch_fighters(side: CombatState.SideState) -> void:
	if side.obj.bay_count > 0:
		var n: int = rng.random_1_20()
		if n <= side.obj.bay_count and side.obj.fighter_count > 0 and side.num_fighters_out < CombatConstants.MAX_FIGHTERS:
			_launch_fighter(side)


func _launch_fighter(side: CombatState.SideState) -> void:
	for i: int in range(CombatConstants.MAX_FIGHTERS):
		if side.fighter_active[i] == CombatConstants.FIGHTER_IDLE:
			side.obj.fighter_count -= 1
			side.fighter_active[i] = CombatConstants.FIGHTER_ATTACKS
			side.fighter_x[i] = side.cur_x
			side.num_fighters_out += 1
			emit_signal("fighter_launched", side.side, i)
			return

func _fighter_stuff() -> void:
	_move_fighters()

	for i: int in range(CombatConstants.MAX_FIGHTERS):
		_fighter_shoot_left(i)
		_fighter_shoot_right(i)

	if state.left.obj.bay_count > 0 and state.right.obj.bay_count > 0:
		for i: int in range(CombatConstants.MAX_FIGHTERS):
			if state.left.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
				for j: int in range(CombatConstants.MAX_FIGHTERS):
					if state.right.fighter_active[j] != CombatConstants.FIGHTER_IDLE:
						if state.left.fighter_x[i] == state.right.fighter_x[j]:
							var n: int = rng.random_1_100()

							# entspricht dem nu.js-Sonderfall:
							# ein "toter" linker Fighter kann in diesem Pfad noch eine Rolle spielen
							if state.left.fighter_active[i] == CombatConstants.FIGHTER_IDLE:
								if n >= 50:
									_kill_fighter(state.right, j, CombatTypes.Side.RIGHT)
							else:
								if n < 50:
									emit_signal("fighter_intercept_beam", CombatTypes.Side.RIGHT, j, i)
									_kill_fighter(state.left, i, CombatTypes.Side.LEFT)
								else:
									emit_signal("fighter_intercept_beam", CombatTypes.Side.LEFT, i, j)
									_kill_fighter(state.right, j, CombatTypes.Side.RIGHT)

func _fighter_shoot(side: CombatState.SideState, opp: CombatState.SideState, i: int) -> void:
	if side.fighter_active[i] != CombatConstants.FIGHTER_ATTACKS:
		return

	if abs(side.fighter_x[i] - opp.cur_x) < 20:
		if not _fighter_hit_blocked_by_target(opp):
			emit_signal("beam_fired", side.side, side.fighter_x[i], opp.cur_x, true, i)
			_hit(opp, 2, 2)

func _hit(target: CombatState.SideState, damage: int, kill: int) -> void:
	var combat_mass: int = target.obj.mass

	var shld: int = -rdivadd(80 * damage, combat_mass + 1, 1 - target.obj.shield, state.rounding_mode)

	if shld < 0:
		target.obj.shield = 0
		var hull_damage: int = rdivadd(-80 * shld, combat_mass + 1, target.obj.damage + 1, state.rounding_mode)
		target.obj.damage = min(9999, hull_damage)
		shld = 0

	if target.obj.shield == 0 and not target.obj.is_planet and not target.obj.is_squadron:
		var effective_kill: int = kill
		if target.obj.crew_defense_rate > 0:
			var defense: int = clamp(target.obj.crew_defense_rate, 0, 100)
			effective_kill = radiv((100 - defense) * kill, 100)

		var crew_after: int = -rdivadd(80 * effective_kill, combat_mass + 1, -target.obj.crew, state.rounding_mode)
		target.obj.crew = max(0, crew_after)

	target.obj.shield = shld
	emit_signal("hit_resolved", target.side, target.obj.shield, target.obj.damage, target.obj.crew)

func radiv(a: int, b: int) -> int:
	return _idiv_trunc(a + _idiv_trunc(b, 2), b)
	
func rdivadd(a: int, b: int, plus: int, mode: CombatTypes.RoundingMode) -> int:
	var base: int = _idiv_trunc(a, b) + plus
	var rest: int = a % b
	var bump: int = base & 1

	if mode == CombatTypes.RoundingMode.ARITHMETIC_NEAREST_UP:
		bump |= 1

	if rest * 2 + bump > b:
		base += 1

	return base

func rdivadd_nu(a: int, b: int, plus: int) -> int:
	var x: int = _idiv_trunc(a, b) + plus
	var r: int = a % b

	if r * 2 + (x & 1) > b:
		x += 1

	return x

func _idiv_trunc(a: int, b: int) -> int:
	return int(float(a) / float(b))
	
func _is_carrier(side: CombatState.SideState) -> bool:
	return side.obj.bay_count > 0


func _compute_combat_mass(side: CombatState.SideState, opp: CombatState.SideState) -> int:
	var mass: int = side.obj.mass

	# Federation: +50 KT Combat Mass
	if side.obj.race_id == 1:
		mass += 50

	# Right-side bonus:
	# If a right-hand ship of 140 KT or more fights and the left-hand side is a carrier,
	# there is a 60% chance for +360 KT Combat Mass.
	if side.side == CombatTypes.Side.RIGHT:
		if side.obj.mass >= 140 and _is_carrier(opp):
			if rng.random_1_100() <= 60:
				mass += 360

	return mass

func _move_fighters() -> void:
	for i: int in range(CombatConstants.MAX_FIGHTERS):
		# left side
		if state.left.fighter_active[i] == CombatConstants.FIGHTER_ATTACKS \
		and state.left.fighter_x[i] > state.right.cur_x + 10:
			state.left.fighter_active[i] = CombatConstants.FIGHTER_RETURNS		

		if state.left.fighter_active[i] == CombatConstants.FIGHTER_RETURNS \
		and state.left.fighter_x[i] < state.left.cur_x:
			state.left.obj.fighter_count += 1
			state.left.fighter_active[i] = CombatConstants.FIGHTER_IDLE
			state.left.num_fighters_out -= 1
			emit_signal("fighter_landed", CombatTypes.Side.LEFT, i)

		if state.left.fighter_active[i] == CombatConstants.FIGHTER_ATTACKS:
			state.left.fighter_x[i] += 4
		elif state.left.fighter_active[i] == CombatConstants.FIGHTER_RETURNS:
			state.left.fighter_x[i] -= 4

		# right side
		if state.right.fighter_active[i] == CombatConstants.FIGHTER_ATTACKS \
		and state.right.fighter_x[i] < state.left.cur_x - 10:
			state.right.fighter_active[i] = CombatConstants.FIGHTER_RETURNS

		if state.right.fighter_active[i] == CombatConstants.FIGHTER_RETURNS \
		and state.right.fighter_x[i] > state.right.cur_x:
			state.right.obj.fighter_count += 1
			state.right.fighter_active[i] = CombatConstants.FIGHTER_IDLE
			state.right.num_fighters_out -= 1
			emit_signal("fighter_landed", CombatTypes.Side.RIGHT, i)

		if state.right.fighter_active[i] == CombatConstants.FIGHTER_ATTACKS:
			state.right.fighter_x[i] -= 4
		elif state.right.fighter_active[i] == CombatConstants.FIGHTER_RETURNS:
			state.right.fighter_x[i] += 4
				
func _fighter_shoot_left(i: int) -> void:
	if state.left.fighter_active[i] == CombatConstants.FIGHTER_ATTACKS \
	and abs(state.left.fighter_x[i] - state.right.cur_x) < 20:
		if not _fighter_hit_blocked_by_target(state.right):
			_hit(state.right, 2, 2)
			emit_signal("beam_fired", CombatTypes.Side.LEFT, state.left.fighter_x[i], state.right.cur_x, true, i)
		
func _fighter_shoot_right(i: int) -> void:
	if state.right.fighter_active[i] == CombatConstants.FIGHTER_ATTACKS \
	and abs(state.right.fighter_x[i] - state.left.cur_x) < 20:
		if not _fighter_hit_blocked_by_target(state.left):
			_hit(state.left, 2, 2)
			emit_signal("beam_fired", CombatTypes.Side.RIGHT, state.right.fighter_x[i], state.left.cur_x, true, i)


func _fighter_hit_blocked_by_target(target: CombatState.SideState) -> bool:
	var fighter_defense: int = 0
	if target.obj.crew_defense_rate > 100:
		fighter_defense = target.obj.crew_defense_rate - 100
	elif target.obj.crew_defense_rate < 0:
		fighter_defense = -target.obj.crew_defense_rate

	return fighter_defense > 0 and rng.random_1_100() <= fighter_defense
		
func _kill_fighter(side: CombatState.SideState, which: int, side_id: int) -> void:
	if side.fighter_active[which] != CombatConstants.FIGHTER_IDLE:
		side.fighter_active[which] = CombatConstants.FIGHTER_IDLE
		side.num_fighters_out -= 1
		emit_signal("fighter_killed", side_id, which)
		
func _hit_torp(target: CombatState.SideState, damage: int, kill: int) -> void:
	var combat_mass: int = target.obj.mass

	var shield_damage: int = damage * 2
	var shld: int = -rdivadd(80 * shield_damage, combat_mass + 1, 1 - target.obj.shield, state.rounding_mode)

	if shld < 0:
		target.obj.shield = 0

		# Nur echter Torpedo-Schaden auf die Hülle, nicht verdoppelt
		var hull_damage: int = rdivadd(-80 * shld, combat_mass + 1, target.obj.damage + 1, state.rounding_mode)
		target.obj.damage = min(9999, hull_damage)
		shld = 0

	if target.obj.shield == 0 and not target.obj.is_planet and not target.obj.is_squadron:
		var defense: int = clamp(target.obj.crew_defense_rate, 0, 100)
		var effective_kill: int = int(round(2*kill * (1.0 - float(defense) / 100.0)))

		var crew_after: int = -rdivadd_nu(80 * effective_kill, combat_mass + 1, -target.obj.crew)
		target.obj.crew = max(0, crew_after)

	target.obj.shield = shld
	emit_signal("hit_resolved", target.side, target.obj.shield, target.obj.damage, target.obj.crew)
