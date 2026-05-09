class_name CombatFactory
extends RefCounted
static var USE_HULL_ONLY_MASS: bool = true
static var fascist_double_beams_enabled: bool = true

static func create_test_vcr() -> ClassicVcr:
	var vcr: ClassicVcr = ClassicVcr.new()

	# zufälliger Seed (THost: 1–119)
	vcr.battle_seed = randi_range(1, 118)

	vcr.battle_type = CombatConstants.SHIP_TO_SHIP

	# Schiffe erzeugen
	vcr.set_single_combatants(
		create_ship_from_hull(35, 1, 6, 10, 10, 10, 10, 6, 0, 100),
		create_ship_from_hull(99, 2, 10, 10, 10, 10, 0, 0, 8, 36)
	)

	return vcr
	
static func create_ship_from_hull(
	hull_id: int,
	owner_id: int,
	race_id: int,
	_engine_id: int,
	beam_type: int,
	beam_count: int,
	torp_type: int,
	torp_launcher_count: int,
	bay_count: int,
	ammo_count: int,
	object_name: String = ""
) -> CombatObject:
	var hull: Dictionary = ShipData.hulls.get(hull_id, {})
	if hull.is_empty():
		push_error("Unknown hull_id: %d" % hull_id)
		return CombatObject.new()

	var obj: CombatObject = CombatObject.new()
	obj.object_name = object_name if object_name != "" else String(hull.get("name", "Unknown Hull"))
	obj.owner_id = owner_id
	obj.race_id = race_id
	obj.hull_id = hull_id
	obj.component_hull_ids = ShipData.get_stacked_component_ids(hull_id)
	_apply_hull_abilities(obj)
	obj.is_planet = false

	obj.beam_type = beam_type
	obj.beam_count = beam_count
	obj.torp_type = torp_type
	obj.torp_launcher_count = torp_launcher_count
	obj.bay_count = bay_count

	obj.shield = 100
	obj.damage = 0

	obj.crew = int(hull.get("crew", 0))
	obj.crew_max = obj.crew

	obj.mass = int(hull.get("mass", 0))

	if bay_count > 0:
		obj.fighter_count = ammo_count
		obj.torp_count = 0
	else:
		obj.torp_count = ammo_count
		obj.fighter_count = 0

	obj.beam_kill_rate = 1
	obj.beam_charge_rate = 1
	obj.torp_charge_rate = 1
	obj.torp_miss_rate = 35
	obj.torp_range = ShipData.get_torp_range(torp_type)
	obj.crew_defense_rate = 0
	obj.damage_limit = 100
	# Fed bonus
	if obj.race_id == 1:
		obj.mass += 50
		if obj.bay_count > 0:
			obj.bay_count += 3
			obj.bay_bonus_count += 3
			obj.bay_bonus_parts.append(3)

# Fascist / Fury double beams in Nu-Sim nur wenn Option aktiv
	if obj.race_id == 4 and fascist_double_beams_enabled:
		obj.beam_charge_rate = 2

# Damage removes weapons (except race 1)
	if obj.race_id != 1 and obj.damage > 0:
		var max_weapons: int = int(ceil((100.0 - float(obj.damage)) / 10.0))
		if obj.race_id == 2:
			max_weapons = int(ceil((150.0 - float(obj.damage)) / 10.0))
		if max_weapons < 0:
			max_weapons = 0
		obj.bay_count = min(obj.bay_count, max_weapons)
		obj.torp_launcher_count = min(obj.torp_launcher_count, max_weapons)
		obj.beam_count = min(obj.beam_count, max_weapons)
	return obj

static func create_vcr_from_turn_vcr_dict(data: Dictionary) -> ClassicVcr:
	var vcr: ClassicVcr = ClassicVcr.new()
	vcr.battle_seed = int(data.get("seed", 1))
	vcr.battle_type = int(data.get("battletype", 0))

	var left_data: Dictionary = data.get("left", {})
	var right_data: Dictionary = data.get("right", {})
	vcr.set_single_combatants(
		create_combat_object_from_turn_side(left_data, int(data.get("leftownerid", 0))),
		create_combat_object_from_turn_side(right_data, int(data.get("rightownerid", 0)))
	)
	if vcr.battle_type != 0:
		vcr.right.is_planet = true
		if not vcr.right_fleet.is_empty():
			vcr.right_fleet[0].is_planet = true

	return vcr
	
static func create_combat_object_from_turn_side(data: Dictionary, owner_id: int) -> CombatObject:
	var obj: CombatObject = CombatObject.new()
	obj.object_id = int(data.get("objectid", 0))
	obj.object_name = String(data.get("name", ""))
	obj.owner_id = owner_id
	obj.race_id = int(data.get("raceid", 0))
	obj.hull_id = int(data.get("hullid", 0))
	obj.component_hull_ids = ShipData.get_stacked_component_ids(obj.hull_id)
	_apply_hull_abilities(obj)
	obj.is_planet = false
	
	obj.beam_type = int(data.get("beamid", 0))
	obj.beam_count = int(data.get("beamcount", 0))
	obj.torp_type = int(data.get("torpedoid", 0))
	obj.torp_launcher_count = int(data.get("launchercount", 0))
	obj.bay_count = int(data.get("baycount", 0))

	obj.shield = int(data.get("shield", 0))
	obj.damage = int(data.get("damage", 0))
	obj.crew = int(data.get("crew", 0))
	obj.crew_max = obj.crew
	obj.mass = int(data.get("mass", 0))

	obj.torp_count = int(data.get("torpedos", 0))
	obj.fighter_count = int(data.get("fighters", 0))
	var hull: Dictionary = ShipData.get_hull(obj.hull_id)
	var hull_bays: int = int(hull.get("bays", 0))
	if obj.race_id == 1 and hull_bays > 0 and obj.bay_count > hull_bays:
		obj.bay_bonus_count = obj.bay_count - hull_bays
		obj.bay_bonus_parts = [obj.bay_bonus_count]

	obj.beam_kill_rate = int(data.get("beamkillbonus", 1))
	obj.beam_charge_rate = int(data.get("beamchargerate", 1))
	obj.torp_charge_rate = int(data.get("torpchargerate", 1))
	obj.torp_miss_rate = int(data.get("torpmisspercent", 35))
	obj.crew_defense_rate = int(data.get("crewdefensepercent", 0))

	obj.torp_range = 340 if obj.torp_type == 11 else 300
	obj.damage_limit = 150 if obj.race_id == 2 else 100
	obj.has_starbase = bool(data.get("hasstarbase", false))
	return obj


static func _apply_hull_abilities(obj: CombatObject) -> void:
	obj.is_squadron = ShipData.is_squadron_hull(obj.hull_id)
	obj.is_elusive = ShipData.is_elusive_hull(obj.hull_id)
	obj.has_gravitonic_accelerator = ShipData.has_gravitonic_accelerator(obj.hull_id)
	
static func create_vcr_from_turn_dict(data: Dictionary) -> ClassicVcr:
	var vcr: ClassicVcr = ClassicVcr.new()

	vcr.battle_seed = int(data.get("seed", 1))
	vcr.battle_type = int(data.get("battletype", 0))

	var left_data: Dictionary = data.get("left", {})
	var right_data: Dictionary = data.get("right", {})

	vcr.set_single_combatants(
		create_combat_object_from_turn_side(left_data, int(data.get("leftownerid", 0))),
		create_combat_object_from_turn_side(right_data, int(data.get("rightownerid", 0)))
	)

	if vcr.battle_type != 0:
		vcr.right.is_planet = true
		if not vcr.right_fleet.is_empty():
			vcr.right_fleet[0].is_planet = true

	return vcr
