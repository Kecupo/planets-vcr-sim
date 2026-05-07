extends Node

# Autoload: ShipData

var beams: Dictionary = {}
var torps: Dictionary = {}
var engines: Dictionary = {}
var hulls: Dictionary = {}

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

func get_hull_image_id(hull_id: int) -> int:
	var hull: Dictionary = get_hull(hull_id)
	if hull.is_empty():
		return hull_id

	var parent_id: int = int(hull.get("parentid", 0))
	if parent_id > 0:
		return parent_id

	return hull_id
