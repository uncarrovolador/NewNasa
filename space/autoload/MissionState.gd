extends Node

signal build_changed

@export_file("*.json") var data_file_path: String = "res://space_customizer/data/simulador_v15.json"

var active_mission_id: String = "MIS_A" # Cambia entre "MIS_A", "MIS_B" y "MIS_C"

var missions_db: Dictionary = {}
var parts_by_category: Dictionary = {}
var all_parts_by_id: Dictionary = {}

# Estado compartido de las 8 piezas (4 del Cohete + 4 del Rover)
var equipped_ids: Dictionary = {
	# Escena 1: Cohete
	"Payload_Fairing": "FRG_202",
	"Upper_Stage": "STG_200",
	"Rocket_Core": "LCH_202",
	"Rocket_Boosters": "SRB_201",
	# Escena 2: Rover
	"Rover_Template": "BASE_201",
	"Rover_Comms": "COM_204",
	"Rover_Science": "INS_B",
	"Rover_Extra": "EXT_001"
}


func _ready() -> void:
	load_database()


func load_database() -> void:
	if not FileAccess.file_exists(data_file_path):
		push_error("No se encontró el JSON en: " + data_file_path)
		return
		
	var file := FileAccess.open(data_file_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Formato JSON inválido.")
		return
		
	missions_db = parsed.get("missions", {})
	parts_by_category.clear()
	all_parts_by_id.clear()
	
	for item in parsed.get("components", []):
		var id: String = item.get("id", "")
		var cat: String = item.get("category", "")
		all_parts_by_id[id] = item
		if not parts_by_category.has(cat):
			parts_by_category[cat] = []
		parts_by_category[cat].append(item)


func equip_part(category: String, part_id: String) -> void:
	equipped_ids[category] = part_id
	build_changed.emit()
	
	

func set_mission(mission_id: String) -> void:
	if missions_db.has(mission_id):
		active_mission_id = mission_id
		build_changed.emit()
		
		
func get_equipped_part(category: String) -> Dictionary:
	var id: String = equipped_ids.get(category, "")
	return all_parts_by_id.get(id, {})


func calculate_totals() -> Dictionary:
	var mission: Dictionary = missions_db.get(active_mission_id, {
		"lander_mass_kg": 2600.0,
		"lander_cost_usd": 150000000.0,
		"integration_months": 18.0,
		"min_fairing_diameter_m": 5.2,
		"min_mass_margin_pct": 0.15,
		"contact_hours_day": 6.0,
		"min_science_mb": 400.0,
		"max_power_w": 450.0,
		"max_budget_usd": 800000000.0,
		"max_time_months": 60.0
	})
	
	var total_mass: float = float(mission["lander_mass_kg"])
	var total_tli_capacity: float = 0.0
	var net_power: float = 0.0
	var total_budget: float = float(mission["lander_cost_usd"])
	var total_data_mb: float = 0.0
	var total_comms_kbps: float = 0.0
	var slowest_part_months: float = 0.0
	
	for cat in equipped_ids.keys():
		var part := get_equipped_part(cat)
		if part.is_empty():
			continue
		total_mass += float(part.get("mass_kg", 0))
		total_tli_capacity += float(part.get("capacity_kg", 0))
		net_power += float(part.get("power_w", 0))
		total_budget += float(part.get("budget_usd", 0))
		total_data_mb += float(part.get("data_mb_day", 0))
		total_comms_kbps += float(part.get("comms_kbps", 0))
		slowest_part_months = maxf(slowest_part_months, float(part.get("time_months", 0)))
	
	var required_capacity: float = total_mass * (1.0 + float(mission["min_mass_margin_pct"]))
	var total_time: float = slowest_part_months + float(mission["integration_months"])
	var max_link_data: float = total_comms_kbps * 0.45 * float(mission["contact_hours_day"])
	
	var rover_base := get_equipped_part("Rover_Template")
	var rover_max_payload: float = float(rover_base.get("rover_payload_kg", 0))
	var rover_used_payload: float = (
		float(get_equipped_part("Rover_Comms").get("mass_kg", 0)) +
		float(get_equipped_part("Rover_Science").get("mass_kg", 0)) +
		float(get_equipped_part("Rover_Extra").get("mass_kg", 0))
	)
	
	var fairing_diam: float = float(get_equipped_part("Payload_Fairing").get("fairing_diameter_m", 0))
	
	return {
		"mission": mission,
		"required_capacity": required_capacity,
		"total_tli_capacity": total_tli_capacity,
		"net_power": net_power,
		"total_budget": total_budget,
		"total_data_mb": total_data_mb,
		"max_link_data": max_link_data,
		"total_comms_kbps": total_comms_kbps,
		"total_time": total_time,
		"rover_used_payload": rover_used_payload,
		"rover_max_payload": rover_max_payload,
		"fairing_diam": fairing_diam,
		"ok_mass": required_capacity <= total_tli_capacity,
		"ok_fairing": fairing_diam >= float(mission["min_fairing_diameter_m"]),
		"ok_rover_payload": rover_used_payload <= rover_max_payload,
		"ok_power": net_power <= float(mission["max_power_w"]),
		"ok_data": total_data_mb >= float(mission["min_science_mb"]) and total_data_mb <= max_link_data,
		"ok_budget": total_budget <= float(mission["max_budget_usd"]),
		"ok_time": total_time <= float(mission["max_time_months"])
	}
