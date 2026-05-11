class_name CombatSimulatorThost
extends RefCounted

func simulate_all_seeds(source_vcr: ClassicVcr) -> Dictionary:
	var right_mass_bonus_possible: bool = _right_mass_bonus_possible(source_vcr)
	var summary: Dictionary = _new_summary(right_mass_bonus_possible)

	for battle_seed: int in range(1, 119):
		_simulate_seed_into_summary(source_vcr, battle_seed, right_mass_bonus_possible, summary)

	return _finalize_summary(summary, source_vcr)


func simulate_all_seeds_async(source_vcr: ClassicVcr, progress_callback: Callable = Callable()) -> Dictionary:
	var right_mass_bonus_possible: bool = _right_mass_bonus_possible(source_vcr)
	var summary: Dictionary = _new_summary(right_mass_bonus_possible)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var total_battles: int = int(summary["total_battles"])

	if progress_callback.is_valid():
		progress_callback.call(0, total_battles)
	if tree != null:
		await tree.process_frame

	for battle_seed: int in range(1, total_battles + 1):
		_simulate_seed_into_summary(source_vcr, battle_seed, right_mass_bonus_possible, summary)
		if progress_callback.is_valid():
			progress_callback.call(battle_seed, total_battles)
		if tree != null:
			await tree.process_frame

	return _finalize_summary(summary, source_vcr)


func _new_summary(right_mass_bonus_possible: bool) -> Dictionary:
	return {
		"total_battles": 118,
		"total_weight": 0,
		"right_mass_bonus_possible": right_mass_bonus_possible,
		"left_destroyed_count": 0,
		"right_destroyed_count": 0,
		"both_destroyed_count": 0,
		"left_captured_count": 0,
		"right_captured_count": 0,
		"left_min_non_destroyed_damage": 9999,
		"left_max_non_destroyed_damage": 0,
		"left_min_destroyed_damage": 9999,
		"left_max_destroyed_damage": 0,
		"right_min_non_destroyed_damage": 9999,
		"right_max_non_destroyed_damage": 0,
		"right_min_destroyed_damage": 9999,
		"right_max_destroyed_damage": 0,
		"left_min_end_shield": 9999,
		"left_max_end_shield": 0,
		"right_min_end_shield": 9999,
		"right_max_end_shield": 0,
		"left_min_end_ammo": 9999,
		"left_max_end_ammo": 0,
		"right_min_end_ammo": 9999,
		"right_max_end_ammo": 0
	}


func _simulate_seed_into_summary(source_vcr: ClassicVcr, battle_seed: int, right_mass_bonus_possible: bool, summary: Dictionary) -> void:
	var results: Array[Dictionary] = []

	if right_mass_bonus_possible:
		results.append({"result": _simulate_single(source_vcr, battle_seed, false), "weight": 2})
		results.append({"result": _simulate_single(source_vcr, battle_seed, true), "weight": 3})
	else:
		results.append({"result": _simulate_single(source_vcr, battle_seed, false), "weight": 1})

	for weighted_result: Dictionary in results:
		_record_weighted_result(summary, weighted_result["result"], int(weighted_result["weight"]))


func _record_weighted_result(summary: Dictionary, result: Dictionary, weight: int) -> void:
	summary["total_weight"] = int(summary["total_weight"]) + weight

	var left_destroyed: bool = result["left_destroyed"]
	var right_destroyed: bool = result["right_destroyed"]
	var left_captured: bool = result["left_captured"]
	var right_captured: bool = result["right_captured"]

	var left_damage: int = result["left_damage"]
	var right_damage: int = result["right_damage"]
	var left_shield: int = result["left_shield"]
	var right_shield: int = result["right_shield"]
	var left_ammo: int = result["left_ammo"]
	var right_ammo: int = result["right_ammo"]

	if left_destroyed:
		summary["left_destroyed_count"] = int(summary["left_destroyed_count"]) + weight
	if right_destroyed:
		summary["right_destroyed_count"] = int(summary["right_destroyed_count"]) + weight
	if left_destroyed and right_destroyed:
		summary["both_destroyed_count"] = int(summary["both_destroyed_count"]) + weight

	if left_captured:
		summary["left_captured_count"] = int(summary["left_captured_count"]) + weight
	if right_captured:
		summary["right_captured_count"] = int(summary["right_captured_count"]) + weight

	if left_destroyed:
		summary["left_min_destroyed_damage"] = min(int(summary["left_min_destroyed_damage"]), left_damage)
		summary["left_max_destroyed_damage"] = max(int(summary["left_max_destroyed_damage"]), left_damage)
	else:
		summary["left_min_non_destroyed_damage"] = min(int(summary["left_min_non_destroyed_damage"]), left_damage)
		summary["left_max_non_destroyed_damage"] = max(int(summary["left_max_non_destroyed_damage"]), left_damage)

	if right_destroyed:
		summary["right_min_destroyed_damage"] = min(int(summary["right_min_destroyed_damage"]), right_damage)
		summary["right_max_destroyed_damage"] = max(int(summary["right_max_destroyed_damage"]), right_damage)
	else:
		summary["right_min_non_destroyed_damage"] = min(int(summary["right_min_non_destroyed_damage"]), right_damage)
		summary["right_max_non_destroyed_damage"] = max(int(summary["right_max_non_destroyed_damage"]), right_damage)

	summary["left_min_end_shield"] = min(int(summary["left_min_end_shield"]), left_shield)
	summary["left_max_end_shield"] = max(int(summary["left_max_end_shield"]), left_shield)
	summary["right_min_end_shield"] = min(int(summary["right_min_end_shield"]), right_shield)
	summary["right_max_end_shield"] = max(int(summary["right_max_end_shield"]), right_shield)

	summary["left_min_end_ammo"] = min(int(summary["left_min_end_ammo"]), left_ammo)
	summary["left_max_end_ammo"] = max(int(summary["left_max_end_ammo"]), left_ammo)
	summary["right_min_end_ammo"] = min(int(summary["right_min_end_ammo"]), right_ammo)
	summary["right_max_end_ammo"] = max(int(summary["right_max_end_ammo"]), right_ammo)

	_record_ship_results(summary, "left_ship_stats", result.get("left_ship_results", []), weight)
	_record_ship_results(summary, "right_ship_stats", result.get("right_ship_results", []), weight)


func _finalize_summary(summary: Dictionary, source_vcr: ClassicVcr) -> Dictionary:
	for key: String in ["left_min_non_destroyed_damage", "left_min_destroyed_damage", "right_min_non_destroyed_damage", "right_min_destroyed_damage", "left_min_end_shield", "right_min_end_shield", "left_min_end_ammo", "right_min_end_ammo"]:
		if int(summary[key]) == 9999:
			summary[key] = 0

	var total_weight: int = int(summary["total_weight"])
	var both_destroyed_count: int = int(summary["both_destroyed_count"])
	var left_only_destroyed_count: int = int(summary["left_destroyed_count"]) - both_destroyed_count
	var right_only_destroyed_count: int = int(summary["right_destroyed_count"]) - both_destroyed_count

	return {
		"total_battles": int(summary["total_battles"]),
		"total_weight": total_weight,
		"right_mass_bonus_possible": bool(summary["right_mass_bonus_possible"]),
		"left_destroyed_count": left_only_destroyed_count,
		"right_destroyed_count": right_only_destroyed_count,
		"both_destroyed_count": both_destroyed_count,
		"left_destroyed_percent": _percent(left_only_destroyed_count, total_weight),
		"right_destroyed_percent": _percent(right_only_destroyed_count, total_weight),
		"both_destroyed_percent": _percent(both_destroyed_count, total_weight),
		"left_captured_count": int(summary["left_captured_count"]),
		"right_captured_count": int(summary["right_captured_count"]),
		"left_captured_percent": _percent(int(summary["left_captured_count"]), total_weight),
		"right_captured_percent": _percent(int(summary["right_captured_count"]), total_weight),
		"left_min_non_destroyed_damage": int(summary["left_min_non_destroyed_damage"]),
		"left_max_non_destroyed_damage": int(summary["left_max_non_destroyed_damage"]),
		"left_min_destroyed_damage": int(summary["left_min_destroyed_damage"]),
		"left_max_destroyed_damage": int(summary["left_max_destroyed_damage"]),
		"right_min_non_destroyed_damage": int(summary["right_min_non_destroyed_damage"]),
		"right_max_non_destroyed_damage": int(summary["right_max_non_destroyed_damage"]),
		"right_min_destroyed_damage": int(summary["right_min_destroyed_damage"]),
		"right_max_destroyed_damage": int(summary["right_max_destroyed_damage"]),
		"left_min_end_shield": int(summary["left_min_end_shield"]),
		"left_max_end_shield": int(summary["left_max_end_shield"]),
		"right_min_end_shield": int(summary["right_min_end_shield"]),
		"right_max_end_shield": int(summary["right_max_end_shield"]),
		"left_min_end_ammo": int(summary["left_min_end_ammo"]),
		"left_max_end_ammo": int(summary["left_max_end_ammo"]),
		"right_min_end_ammo": int(summary["right_min_end_ammo"]),
		"right_max_end_ammo": int(summary["right_max_end_ammo"]),
		"left_uses_fighters": source_vcr.left.bay_count > 0,
		"right_uses_fighters": source_vcr.right.bay_count > 0,
		"left_fleet_size": max(1, source_vcr.left_fleet.size()),
		"right_fleet_size": max(1, source_vcr.right_fleet.size()),
		"left_ship_stats": _finalize_ship_stats(summary.get("left_ship_stats", []), total_weight),
		"right_ship_stats": _finalize_ship_stats(summary.get("right_ship_stats", []), total_weight)
	}


func _simulate_single(source_vcr: ClassicVcr, battle_seed: int, mass_bonus: bool) -> Dictionary:
	var sim_vcr: ClassicVcr = _clone_vcr_with_seed(source_vcr, battle_seed)

	if mass_bonus:
		sim_vcr.right.mass += 360
		if not sim_vcr.right_fleet.is_empty():
			sim_vcr.right_fleet[0].mass += 360

	return _simulate_fleet_sequence(sim_vcr)


func _simulate_fleet_sequence(sim_vcr: ClassicVcr) -> Dictionary:
	var left_fleet: Array[CombatObject] = _clone_fleet(sim_vcr.left_fleet)
	var right_fleet: Array[CombatObject] = _clone_fleet(sim_vcr.right_fleet)
	if left_fleet.is_empty():
		left_fleet.append(_clone_combat_object(sim_vcr.left))
	if right_fleet.is_empty():
		right_fleet.append(_clone_combat_object(sim_vcr.right))

	var left_index: int = 0
	var right_index: int = 0
	var current_left: CombatObject = left_fleet[left_index]
	var current_right: CombatObject = right_fleet[right_index]
	var last_left: CombatObject = current_left
	var last_right: CombatObject = current_right
	var left_removed: bool = false
	var right_removed: bool = false
	var left_captured: bool = false
	var right_captured: bool = false
	var battle_count: int = 0
	var left_ship_results: Array = _new_seed_ship_results(left_fleet.size())
	var right_ship_results: Array = _new_seed_ship_results(right_fleet.size())

	while left_index < left_fleet.size() and right_index < right_fleet.size():
		battle_count += 1
		var battle_vcr: ClassicVcr = ClassicVcr.new()
		battle_vcr.battle_seed = sim_vcr.battle_seed
		battle_vcr.battle_type = sim_vcr.battle_type
		battle_vcr.set_single_combatants(current_left, current_right)

		var engine: CombatEngineThost = CombatEngineThost.new()
		engine.init_vcr(battle_vcr)

		while engine.play_cycle():
			pass

		engine.finish_battle()

		var status_word: int = engine.state.status_word
		last_left = engine.state.left.obj
		last_right = engine.state.right.obj
		current_left = last_left
		current_right = last_right

		var this_left_removed: bool = (status_word & (CombatConstants.VCRS_LEFT_DESTROYED | CombatConstants.VCRS_LEFT_CAPTURED)) != 0
		var this_right_removed: bool = (status_word & (CombatConstants.VCRS_RIGHT_DESTROYED | CombatConstants.VCRS_RIGHT_CAPTURED)) != 0
		var this_left_destroyed: bool = (status_word & CombatConstants.VCRS_LEFT_DESTROYED) != 0
		var this_right_destroyed: bool = (status_word & CombatConstants.VCRS_RIGHT_DESTROYED) != 0
		var this_left_captured: bool = (status_word & CombatConstants.VCRS_LEFT_CAPTURED) != 0
		var this_right_captured: bool = (status_word & CombatConstants.VCRS_RIGHT_CAPTURED) != 0
		left_ship_results[left_index] = _new_seed_ship_result(last_left, this_left_destroyed, this_left_captured)
		right_ship_results[right_index] = _new_seed_ship_result(last_right, this_right_destroyed, this_right_captured)

		if not this_left_removed and not this_right_removed:
			break

		if this_left_removed:
			left_index += 1
			left_removed = left_index >= left_fleet.size()
			left_captured = left_removed and this_left_captured
			if left_index < left_fleet.size():
				current_left = left_fleet[left_index]
		if this_right_removed:
			right_index += 1
			right_removed = right_index >= right_fleet.size()
			right_captured = right_removed and this_right_captured
			if right_index < right_fleet.size():
				current_right = right_fleet[right_index]

		if left_index >= left_fleet.size() or right_index >= right_fleet.size():
			break

		if not this_left_removed:
			_regenerate_ssg_shield_between_battles(current_left)
		if not this_right_removed:
			_regenerate_ssg_shield_between_battles(current_right)

	return {
		"left_destroyed": left_removed,
		"right_destroyed": right_removed,
		"left_captured": left_captured,
		"right_captured": right_captured,
		"left_damage": last_left.damage,
		"right_damage": last_right.damage,
		"left_shield": last_left.shield,
		"right_shield": last_right.shield,
		"left_ammo": _get_end_ammo(last_left),
		"right_ammo": _get_end_ammo(last_right),
		"battle_count": battle_count,
		"left_remaining": max(0, left_fleet.size() - left_index),
		"right_remaining": max(0, right_fleet.size() - right_index),
		"left_ship_results": left_ship_results,
		"right_ship_results": right_ship_results
	}


func _regenerate_ssg_shield_between_battles(obj: CombatObject) -> void:
	if obj == null:
		return
	var shield_regen: int = 25 * obj.ssg_support_count
	if not obj.is_planet and obj.race_id == 1:
		shield_regen += 25
	if shield_regen <= 0:
		return

	var max_shield: int = 150 if obj.ssg_support_count > 0 and obj.damage <= 0 else max(0, 100 - obj.damage)
	obj.shield = min(max_shield, obj.shield + shield_regen)


func _new_seed_ship_results(size: int) -> Array:
	var result: Array = []
	for i: int in range(size):
		result.append({"used": false})
	return result


func _new_seed_ship_result(obj: CombatObject, destroyed: bool, captured: bool) -> Dictionary:
	return {
		"used": true,
		"destroyed": destroyed,
		"captured": captured,
		"damage": obj.damage,
		"shield": obj.shield,
		"ammo": _get_end_ammo(obj)
	}


func _new_ship_stat() -> Dictionary:
	return {
		"used_count": 0,
		"not_used_count": 0,
		"destroyed_count": 0,
		"captured_count": 0,
		"survived_count": 0,
		"min_damage": 9999,
		"max_damage": 0,
		"min_shield": 9999,
		"max_shield": 0,
		"min_ammo": 9999,
		"max_ammo": 0
	}


func _record_ship_results(summary: Dictionary, key: String, ship_results: Array, weight: int) -> void:
	var stats: Array = summary.get(key, [])
	while stats.size() < ship_results.size():
		stats.append(_new_ship_stat())

	for i: int in range(ship_results.size()):
		var ship_result: Dictionary = ship_results[i]
		var stat: Dictionary = stats[i]
		if not bool(ship_result.get("used", false)):
			stat["not_used_count"] = int(stat["not_used_count"]) + weight
			continue

		stat["used_count"] = int(stat["used_count"]) + weight
		var destroyed: bool = bool(ship_result.get("destroyed", false))
		var captured: bool = bool(ship_result.get("captured", false))
		if destroyed:
			stat["destroyed_count"] = int(stat["destroyed_count"]) + weight
		if captured:
			stat["captured_count"] = int(stat["captured_count"]) + weight
		if not destroyed and not captured:
			stat["survived_count"] = int(stat["survived_count"]) + weight

		var damage: int = int(ship_result.get("damage", 0))
		var shield: int = int(ship_result.get("shield", 0))
		var ammo: int = int(ship_result.get("ammo", 0))
		stat["min_damage"] = min(int(stat["min_damage"]), damage)
		stat["max_damage"] = max(int(stat["max_damage"]), damage)
		stat["min_shield"] = min(int(stat["min_shield"]), shield)
		stat["max_shield"] = max(int(stat["max_shield"]), shield)
		stat["min_ammo"] = min(int(stat["min_ammo"]), ammo)
		stat["max_ammo"] = max(int(stat["max_ammo"]), ammo)

	summary[key] = stats


func _finalize_ship_stats(stats: Array, total_weight: int) -> Array:
	var finalized: Array = []
	for stat_variant: Variant in stats:
		var stat: Dictionary = stat_variant
		for key: String in ["min_damage", "min_shield", "min_ammo"]:
			if int(stat[key]) == 9999:
				stat[key] = 0
		var entry: Dictionary = stat.duplicate(true)
		entry["used_percent"] = _percent(int(entry["used_count"]), total_weight)
		entry["not_used_percent"] = _percent(int(entry["not_used_count"]), total_weight)
		entry["destroyed_percent"] = _percent(int(entry["destroyed_count"]), total_weight)
		entry["captured_percent"] = _percent(int(entry["captured_count"]), total_weight)
		entry["survived_percent"] = _percent(int(entry["survived_count"]), total_weight)
		finalized.append(entry)
	return finalized


func _right_mass_bonus_possible(source_vcr: ClassicVcr) -> bool:
	if source_vcr.battle_type != CombatConstants.SHIP_TO_SHIP:
		return false
	if source_vcr.right == null or source_vcr.right.is_planet:
		return false
	if source_vcr.left == null or source_vcr.left.bay_count <= 0:
		return false
	return source_vcr.right.mass >= 140


func _get_end_ammo(obj: CombatObject) -> int:
	if obj.bay_count > 0:
		return obj.fighter_count
	return obj.torp_count


func _is_captured(obj: CombatObject, destroyed: bool, enemy_destroyed: bool) -> bool:
	if obj == null:
		return false
	if obj.is_planet:
		return false
	if destroyed:
		return false
	if enemy_destroyed:
		return false
	return obj.crew <= 0


func _percent(value: int, total: int) -> float:
	if total <= 0:
		return 0.0
	return 100.0 * float(value) / float(total)


func _is_destroyed(obj: CombatObject) -> bool:
	if obj == null:
		return true

	if obj.is_planet:
		return obj.damage >= 100

	if obj.damage >= obj.damage_limit:
		return true

	if obj.crew <= 0:
		return true

	return false


func _clone_vcr_with_seed(source: ClassicVcr, battle_seed: int) -> ClassicVcr:
	var vcr: ClassicVcr = ClassicVcr.new()
	vcr.battle_seed = battle_seed
	vcr.battle_type = source.battle_type
	vcr.left = _clone_combat_object(source.left)
	vcr.right = _clone_combat_object(source.right)
	vcr.left_fleet = _clone_fleet(source.left_fleet)
	vcr.right_fleet = _clone_fleet(source.right_fleet)
	vcr.ensure_fleets()
	return vcr


func _clone_fleet(source: Array[CombatObject]) -> Array[CombatObject]:
	var result: Array[CombatObject] = []
	for obj: CombatObject in source:
		result.append(_clone_combat_object(obj))
	return result


func _clone_combat_object(src: CombatObject) -> CombatObject:
	var obj: CombatObject = CombatObject.new()

	obj.object_name = src.object_name
	obj.has_starbase = src.has_starbase
	obj.planet_img = src.planet_img
	obj.starbase_style = src.starbase_style
	obj.object_id = src.object_id
	obj.owner_id = src.owner_id
	obj.race_id = src.race_id
	obj.hull_id = src.hull_id
	obj.component_hull_ids = src.component_hull_ids.duplicate()
	obj.is_squadron = src.is_squadron
	obj.is_elusive = src.is_elusive
	obj.has_gravitonic_accelerator = src.has_gravitonic_accelerator
	obj.is_planet = src.is_planet

	obj.beam_type = src.beam_type
	obj.beam_count = src.beam_count
	obj.torp_type = src.torp_type
	obj.torp_launcher_count = src.torp_launcher_count
	obj.bay_count = src.bay_count
	obj.bay_bonus_count = src.bay_bonus_count
	obj.bay_bonus_parts = src.bay_bonus_parts.duplicate()

	obj.shield = src.shield
	obj.damage = src.damage
	obj.crew = src.crew
	obj.crew_max = src.crew_max
	obj.mass = src.mass

	obj.torp_count = src.torp_count
	obj.fighter_count = src.fighter_count
	obj.ssg_support_count = src.ssg_support_count

	obj.beam_kill_rate = src.beam_kill_rate
	obj.beam_charge_rate = src.beam_charge_rate
	obj.torp_charge_rate = src.torp_charge_rate
	obj.torp_miss_rate = src.torp_miss_rate
	obj.crew_defense_rate = src.crew_defense_rate
	obj.torp_range = src.torp_range
	obj.damage_limit = src.damage_limit

	return obj
