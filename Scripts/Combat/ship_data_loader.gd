class_name ShipDataLoader
extends RefCounted

var hulls: Dictionary = {}
var beams: Dictionary = {}
var torps: Dictionary = {}

func load_from_json(json_text: String) -> void:
	var data = JSON.parse_string(json_text)

	for h in data["hulls"]:
		hulls[h["id"]] = h

	for b in data["beams"]:
		beams[b["id"]] = b

	for t in data["torpedos"]:
		torps[t["id"]] = t
