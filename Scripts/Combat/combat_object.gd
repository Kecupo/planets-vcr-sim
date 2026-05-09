class_name CombatObject
extends RefCounted
var has_starbase: bool = false
var planet_img: String = ""
var starbase_style: int = 1
var object_name: String = ""
var owner_id: int = 0
var race_id: int = 0
var hull_id: int = 0
var object_id: int = 0
var is_planet: bool = false
var component_hull_ids: Array[int] = []
var is_squadron: bool = false
var is_elusive: bool = false

var beam_type: int = 0
var beam_count: int = 0
var torp_type: int = 0
var torp_launcher_count: int = 0
var bay_count: int = 0
var bay_bonus_count: int = 0
var bay_bonus_parts: Array[int] = []

var shield: int = 100
var damage: int = 0
var crew: int = 0
var crew_max: int = 0
var mass: int = 0
var torp_count: int = 0
var fighter_count: int = 0

var beam_kill_rate: int = 1
var beam_charge_rate: int = 1
var torp_charge_rate: int = 1
var torp_miss_rate: int = 35
var torp_range: int = 300
var crew_defense_rate: int = 0
var damage_limit: int = 100

func duplicate_object() -> CombatObject:
	var c: CombatObject = CombatObject.new()
	c.object_name = object_name
	c.has_starbase = has_starbase
	c.planet_img = planet_img
	c.starbase_style = starbase_style
	c.owner_id = owner_id
	c.race_id = race_id
	c.hull_id = hull_id
	c.object_id = object_id
	c.is_planet = is_planet
	c.component_hull_ids = component_hull_ids.duplicate()
	c.is_squadron = is_squadron
	c.is_elusive = is_elusive
	c.beam_type = beam_type
	c.beam_count = beam_count
	c.torp_type = torp_type
	c.torp_launcher_count = torp_launcher_count
	c.bay_count = bay_count
	c.bay_bonus_count = bay_bonus_count
	c.bay_bonus_parts = bay_bonus_parts.duplicate()
	c.shield = shield
	c.damage = damage
	c.crew = crew
	c.crew_max = crew_max
	c.mass = mass
	c.torp_count = torp_count
	c.fighter_count = fighter_count
	c.beam_kill_rate = beam_kill_rate
	c.beam_charge_rate = beam_charge_rate
	c.torp_charge_rate = torp_charge_rate
	c.torp_miss_rate = torp_miss_rate
	c.torp_range = torp_range
	c.crew_defense_rate = crew_defense_rate
	c.damage_limit = damage_limit
	return c

func is_freighter() -> bool:
	return beam_count == 0 and torp_launcher_count == 0 and bay_count == 0
