extends Node

# Autoload: ShipData

var beams: Dictionary = {}
var torps: Dictionary = {}
var engines: Dictionary = {}
var hulls: Dictionary = {}
var quantum_torpedos_enabled: bool = false
var quantum_torpedo_miss_rate_for_gravitonics: int = 0
var gravitonic_quantum_elusive_enabled: bool = false
const QUANTUM_TORP_ID: int = 11
const GRAVITONIC_QUANTUM_ELUSIVE_START_YEAR: int = 2023
const GRAVITONIC_QUANTUM_ELUSIVE_START_MONTH: int = 1
const GRAVITONIC_QUANTUM_ELUSIVE_START_DAY: int = 1
const STACKED_HULL_COMPONENTS: Dictionary = {
	150: [98, 103],
	151: [95, 98],
	152: [98, 100],
	153: [98, 92],
	154: [98, 101],
	155: [102, 98],
	156: [95, 103],
	157: [95, 100],
	158: [95, 92],
	159: [95, 101],
	160: [95, 102],
	161: [103, 100],
	162: [103, 92],
	163: [103, 101],
	164: [102, 103],
	165: [92, 100],
	166: [101, 100],
	167: [102, 100],
	168: [101, 92],
	169: [102, 92],
	170: [102, 101]
}

func load_from_turn_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("ShipData: turn file not found: " + path)
		return false

	var json_text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ShipData: invalid JSON root")
		return false

	var root: Dictionary = parsed

	if not root.has("rst"):
		push_error("ShipData: no 'rst' key in turn file")
		return false

	var rst_var: Variant = root.get("rst")
	if typeof(rst_var) != TYPE_DICTIONARY:
		push_error("ShipData: 'rst' is not a dictionary")
		return false

	var rst: Dictionary = rst_var

	_load_beams_from_rst(rst)
	_load_torps_from_rst(rst)
	_load_engines_from_rst(rst)
	_load_hulls_from_rst(rst)
	_load_combat_settings(rst)

	print("ShipData loaded: beams=", beams.size(), " torps=", torps.size(), " engines=", engines.size(), " hulls=", hulls.size())
	return true


func _load_beams_from_rst(rst: Dictionary) -> void:
	beams.clear()

	var arr_var: Variant = rst.get("beams", [])
	if typeof(arr_var) != TYPE_ARRAY:
		return

	for entry_var in arr_var:
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_var
		var id: int = int(entry.get("id", 0))
		if id <= 0:
			continue

		beams[id] = {
			"name": String(entry.get("name", "Unknown Beam")),
			"mass": int(entry.get("mass", 0)),
			"damage": int(entry.get("damage", 0)),
			"kill": int(entry.get("crewkill", 0))
		}


func _load_torps_from_rst(rst: Dictionary) -> void:
	torps.clear()

	var key: String = ""
	if rst.has("torpedos"):
		key = "torpedos"
	elif rst.has("torpedoes"):
		key = "torpedoes"
	else:
		return

	var arr_var: Variant = rst.get(key, [])
	if typeof(arr_var) != TYPE_ARRAY:
		return

	for entry_var in arr_var:
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_var
		var id: int = int(entry.get("id", 0))
		if id <= 0:
			continue

		var range_val: int = 300
		if entry.has("combatrange"):
			range_val = int(entry.get("combatrange", 300))
		elif entry.has("range"):
			range_val = int(entry.get("range", 300))
		elif id == 11:
			range_val = 340

		torps[id] = {
			"name": String(entry.get("name", "Unknown Torpedo")),
			"mass": int(entry.get("mass", 0)),
			"damage": int(entry.get("damage", 0)),
			"kill": int(entry.get("crewkill", 0)),
			"range": range_val
		}


func _load_engines_from_rst(rst: Dictionary) -> void:
	engines.clear()

	var arr_var: Variant = rst.get("engines", [])
	if typeof(arr_var) != TYPE_ARRAY:
		return

	for entry_var in arr_var:
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_var
		var id: int = int(entry.get("id", 0))
		if id <= 0:
			continue

		engines[id] = {
			"name": String(entry.get("name", "Unknown Engine"))
		}


func _load_hulls_from_rst(rst: Dictionary) -> void:
	hulls.clear()

	var arr_var: Variant = rst.get("hulls", [])
	if typeof(arr_var) != TYPE_ARRAY:
		return

	for entry_var in arr_var:
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_var
		var id: int = int(entry.get("id", 0))
		if id <= 0:
			continue

		hulls[id] = {
			"name": String(entry.get("name", "Unknown Hull")),
			"imageid": int(entry.get("imageid", entry.get("image", 0))),
			"special": String(entry.get("special", "")),
			"mass": int(entry.get("mass", 0)),
			"cargo": int(entry.get("cargo", 0)),
			"crew": int(entry.get("crew", 0)),
			"engines": int(entry.get("engines", 0)),
			"beams": int(entry.get("beams", 0)),
			"launchers": int(entry.get("launchers", 0)),
			"bays": int(entry.get("fighterbays", 0)),
			"parentid": int(entry.get("parentid", 0)),
			"isbase": bool(entry.get("isbase", false)),
			"techlevel": int(entry.get("techlevel", 0))
		}


func get_beam(beam_id: int) -> Dictionary:
	return beams.get(beam_id, {})


func get_torp(torp_id: int) -> Dictionary:
	return torps.get(torp_id, {})


func get_engine(engine_id: int) -> Dictionary:
	return engines.get(engine_id, {})


func get_hull(hull_id: int) -> Dictionary:
	return hulls.get(hull_id, {})


func get_beam_name(beam_id: int) -> String:
	var beam: Dictionary = get_beam(beam_id)
	return String(beam.get("name", "Unknown Beam"))


func get_torp_name(torp_id: int) -> String:
	var torp: Dictionary = get_torp(torp_id)
	return String(torp.get("name", "Unknown Torpedo"))


func get_beam_damage(beam_id: int) -> int:
	return int(get_beam(beam_id).get("damage", 0))


func get_beam_kill(beam_id: int) -> int:
	return int(get_beam(beam_id).get("kill", 0))


func get_torp_damage(torp_id: int) -> int:
	return int(get_torp(torp_id).get("damage", 0))


func get_torp_kill(torp_id: int) -> int:
	return int(get_torp(torp_id).get("kill", 0))


func get_torp_range(torp_id: int) -> int:
	return int(get_torp(torp_id).get("range", 300))


func is_quantum_torp(torp_id: int) -> bool:
	return torp_id == QUANTUM_TORP_ID


func _load_combat_settings(rst: Dictionary) -> void:
	quantum_torpedos_enabled = false
	quantum_torpedo_miss_rate_for_gravitonics = 0
	gravitonic_quantum_elusive_enabled = false

	var settings: Dictionary = rst.get("settings", {})
	var game: Dictionary = rst.get("game", {})
	quantum_torpedos_enabled = bool(settings.get("quantumtorpedos", false))
	quantum_torpedo_miss_rate_for_gravitonics = int(settings.get("quantumtorpedomissrateforgravitonics", 0))
	gravitonic_quantum_elusive_enabled = quantum_torpedos_enabled \
		and quantum_torpedo_miss_rate_for_gravitonics > 0 \
		and _game_started_on_or_after(game, GRAVITONIC_QUANTUM_ELUSIVE_START_YEAR, GRAVITONIC_QUANTUM_ELUSIVE_START_MONTH, GRAVITONIC_QUANTUM_ELUSIVE_START_DAY)


func _game_started_on_or_after(game: Dictionary, year: int, month: int, day: int) -> bool:
	var date_text: String = String(game.get("datecreated", ""))
	var parsed: Dictionary = _parse_us_date(date_text)
	if parsed.is_empty():
		return true

	var parsed_year: int = int(parsed.get("year", 0))
	var parsed_month: int = int(parsed.get("month", 0))
	var parsed_day: int = int(parsed.get("day", 0))
	if parsed_year != year:
		return parsed_year > year
	if parsed_month != month:
		return parsed_month > month
	return parsed_day >= day


func _parse_us_date(date_text: String) -> Dictionary:
	var date_part: String = date_text.strip_edges().split(" ")[0]
	var parts: PackedStringArray = date_part.split("/")
	if parts.size() < 3:
		return {}
	return {
		"month": int(parts[0]),
		"day": int(parts[1]),
		"year": int(parts[2])
	}

func get_hull_image_id(hull_id: int) -> int:
	var candidates: Array[int] = get_hull_image_ids(hull_id)
	if not candidates.is_empty():
		return candidates[0]
	return hull_id


func get_hull_image_ids(hull_id: int) -> Array[int]:
	var candidates: Array[int] = []
	var hull: Dictionary = get_hull(hull_id)
	if hull.is_empty():
		_append_image_candidate(candidates, hull_id)
		_append_image_candidate(candidates, _campaign_base_hull_id(hull_id))
		return candidates

	_append_image_candidate(candidates, hull_id)
	_append_image_candidate(candidates, int(hull.get("imageid", 0)))
	var parent_id: int = int(hull.get("parentid", 0))
	_append_image_candidate(candidates, parent_id)
	_append_image_candidate(candidates, _campaign_base_hull_id(hull_id))
	_append_image_candidate(candidates, _campaign_base_hull_id(parent_id))

	return candidates


func is_squadron_hull(hull_id: int) -> bool:
	if hull_id in [1065, 2065, 1071, 2071]:
		return true

	var special: String = String(get_hull(hull_id).get("special", "")).to_lower()
	if special.find("squadron") >= 0:
		return true

	var hull_name: String = String(get_hull(hull_id).get("name", "")).to_lower()
	return hull_name.find("gunboats") >= 0


func is_elusive_hull(hull_id: int) -> bool:
	var special: String = String(get_hull(hull_id).get("special", "")).to_lower()
	return special.find("elusive") >= 0


func has_gravitonic_accelerator(hull_id: int) -> bool:
	var special: String = String(get_hull(hull_id).get("special", "")).to_lower()
	return special.find("gravitonic") >= 0


func is_jacker_hull(hull_id: int) -> bool:
	if hull_id in [118, 212]:
		return true
	var hull_name: String = String(get_hull(hull_id).get("name", "")).to_lower()
	return hull_name.find("jacker") >= 0


func is_frigate_hull(hull_id: int) -> bool:
	var hull_name: String = String(get_hull(hull_id).get("name", "")).to_lower()
	return hull_name.find("frigate") >= 0


func keeps_shields_without_beams(hull_id: int) -> bool:
	var hull: Dictionary = get_hull(hull_id)
	var hull_name: String = String(hull.get("name", "")).to_lower()
	var special: String = String(hull.get("special", "")).to_lower()
	return hull_name.find("dungeon") >= 0 and (hull_name.find("stargate") >= 0 or special.find("stargate") >= 0)


func is_stacked_hull(hull_id: int) -> bool:
	return STACKED_HULL_COMPONENTS.has(hull_id)


func get_stacked_component_ids(hull_id: int) -> Array[int]:
	var result: Array[int] = []
	var raw_components: Array = STACKED_HULL_COMPONENTS.get(hull_id, [])
	for component_id in raw_components:
		result.append(int(component_id))
	return result


func _append_image_candidate(candidates: Array[int], image_id: int) -> void:
	if image_id <= 0:
		return
	if image_id in candidates:
		return
	candidates.append(image_id)


func _campaign_base_hull_id(hull_id: int) -> int:
	if hull_id < 1000:
		return 0
	var base_id: int = hull_id % 1000
	return base_id if base_id > 0 else 0
