extends Control


signal customizer_closed

const ROCKET_CATEGORIES: Array[String] = [
	"Payload_Fairing",
	"Upper_Stage",
	"Rocket_Core",
	"Rocket_Boosters"
]

const ROVER_CATEGORIES: Array[String] = [
	"Rover_Template",
	"Rover_Comms",
	"Rover_Science",
	"Rover_Extra"
]

@export var is_rover_mode: bool = false
var slot_categories: Array[String] = ROCKET_CATEGORIES.duplicate()

@onready var close_button: Button = $MarginContainer/MainLayout/LeftColumn/TopBar/CloseButton
@onready var component_name_label: Label = $MarginContainer/MainLayout/LeftColumn/InfoPanel/InfoVBox/ComponentNameLabel
@onready var description_label: RichTextLabel = $MarginContainer/MainLayout/LeftColumn/InfoPanel/InfoVBox/DescriptionLabel

@onready var prev_buttons: Array[Button] = [
	$MarginContainer/MainLayout/CenterColumn/LeftArrows/PrevBtn0,
	$MarginContainer/MainLayout/CenterColumn/LeftArrows/PrevBtn1,
	$MarginContainer/MainLayout/CenterColumn/LeftArrows/PrevBtn2,
	$MarginContainer/MainLayout/CenterColumn/LeftArrows/PrevBtn3
]

@onready var next_buttons: Array[Button] = [
	$MarginContainer/MainLayout/CenterColumn/RightArrows/NextBtn0,
	$MarginContainer/MainLayout/CenterColumn/RightArrows/NextBtn1,
	$MarginContainer/MainLayout/CenterColumn/RightArrows/NextBtn2,
	$MarginContainer/MainLayout/CenterColumn/RightArrows/NextBtn3
]

@onready var preview_stack: Control = $MarginContainer/MainLayout/CenterColumn/PreviewStack
@onready var part_textures: Array[TextureRect] = [
	$MarginContainer/MainLayout/CenterColumn/PreviewStack/PartTexture0,
	$MarginContainer/MainLayout/CenterColumn/PreviewStack/PartTexture1,
	$MarginContainer/MainLayout/CenterColumn/PreviewStack/PartTexture2,
	$MarginContainer/MainLayout/CenterColumn/PreviewStack/PartTexture3
]

@onready var mass_label: Label = $MarginContainer/MainLayout/RightColumn/StatsVBox/MassLabel
@onready var mass_bar: ProgressBar = $MarginContainer/MainLayout/RightColumn/StatsVBox/MassBar
@onready var power_label: Label = $MarginContainer/MainLayout/RightColumn/StatsVBox/PowerLabel
@onready var power_bar: ProgressBar = $MarginContainer/MainLayout/RightColumn/StatsVBox/PowerBar
@onready var budget_label: Label = $MarginContainer/MainLayout/RightColumn/StatsVBox/BudgetLabel
@onready var budget_bar: ProgressBar = $MarginContainer/MainLayout/RightColumn/StatsVBox/BudgetBar
@onready var data_label: Label = $MarginContainer/MainLayout/RightColumn/StatsVBox/DataLabel
@onready var data_bar: ProgressBar = $MarginContainer/MainLayout/RightColumn/StatsVBox/DataBar
@onready var comms_label: Label = $MarginContainer/MainLayout/RightColumn/StatsVBox/CommsLabel
@onready var comms_bar: ProgressBar = $MarginContainer/MainLayout/RightColumn/StatsVBox/CommsBar
@onready var time_label: Label = $MarginContainer/MainLayout/RightColumn/StatsVBox/TimeLabel
@onready var time_bar: ProgressBar = $MarginContainer/MainLayout/RightColumn/StatsVBox/TimeBar


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	MissionState.build_changed.connect(_refresh_all_bars)
	
	for i in range(4):
		prev_buttons[i].pressed.connect(_on_arrow_pressed.bind(i, -1))
		next_buttons[i].pressed.connect(_on_arrow_pressed.bind(i, 1))
	
	set_mode(is_rover_mode)
	_refresh_all_bars()


func set_mode(rover: bool) -> void:
	is_rover_mode = rover
	slot_categories = ROVER_CATEGORIES.duplicate() if rover else ROCKET_CATEGORIES.duplicate()
	
	if not is_node_ready():
		return
	
	# Ordena qué capa se dibuja al fondo y cuál al frente
	if rover:
		# Rover: Chasis (0) al fondo, luego Comms (1), Ciencia (2) y Extra (3) encima
		preview_stack.move_child(part_textures[0], 0)
		preview_stack.move_child(part_textures[1], 1)
		preview_stack.move_child(part_textures[2], 2)
		preview_stack.move_child(part_textures[3], 3)
	else:
		# Cohete: Núcleo (2) al fondo, Etapa Sup (1), Cofia (0) y Boosters (3) al frente
		preview_stack.move_child(part_textures[2], 0)
		preview_stack.move_child(part_textures[1], 1)
		preview_stack.move_child(part_textures[0], 2)
		preview_stack.move_child(part_textures[3], 3)
	
	for i in range(4):
		_update_slot_visual(i, false)
	_update_slot_visual(0, true)


func _on_arrow_pressed(slot_idx: int, direction: int) -> void:
	if slot_idx >= slot_categories.size():
		return
		
	var cat: String = slot_categories[slot_idx]
	var options: Array = MissionState.parts_by_category.get(cat, [])
	if options.is_empty():
		return
		
	var current_id: String = MissionState.equipped_ids.get(cat, "")
	var current_idx: int = 0
	for i in range(options.size()):
		if options[i]["id"] == current_id:
			current_idx = i
			break
			
	var next_idx: int = wrapi(current_idx + direction, 0, options.size())
	var new_part: Dictionary = options[next_idx]
	
	MissionState.equip_part(cat, new_part["id"])
	_update_slot_visual(slot_idx, true)


func _update_slot_visual(slot_idx: int, update_info_box: bool) -> void:
	if slot_idx >= slot_categories.size():
		return
		
	var cat: String = slot_categories[slot_idx]
	var part: Dictionary = MissionState.get_equipped_part(cat)
	if part.is_empty():
		return
		
	var tex_rect: TextureRect = part_textures[slot_idx]
	var tex_path: String = part.get("texture", "")
	if tex_path != "" and ResourceLoader.exists(tex_path):
		tex_rect.texture = load(tex_path)
	else:
		tex_rect.texture = null
		
	if update_info_box:
		component_name_label.text = part.get("component", "")
		description_label.text = part.get("description", "")


func _refresh_all_bars() -> void:
	var stats := MissionState.calculate_totals()
	var mission: Dictionary = stats["mission"]
	
	# 1. Mass (kg)
	mass_bar.max_value = maxf(stats["total_tli_capacity"], 1.0)
	mass_bar.value = clampf(stats["required_capacity"], 0.0, mass_bar.max_value)
	mass_label.text = "Mass: %.0f / %.0f kg" % [stats["required_capacity"], stats["total_tli_capacity"]]
	_tint_bar(mass_bar, stats["ok_mass"])
	
	# 2. Power (W)
	power_bar.max_value = float(mission["max_power_w"])
	power_bar.value = clampf(stats["net_power"], 0.0, power_bar.max_value)
	power_label.text = "Power: %.0f / %.0f W" % [stats["net_power"], mission["max_power_w"]]
	_tint_bar(power_bar, stats["ok_power"])
	
	# 3. Budget (USD)
	budget_bar.max_value = float(mission["max_budget_usd"])
	budget_bar.value = clampf(stats["total_budget"], 0.0, budget_bar.max_value)
	budget_label.text = "Budget: %.1fM / %.1fM USD" % [stats["total_budget"] / 1e6, float(mission["max_budget_usd"]) / 1e6]
	_tint_bar(budget_bar, stats["ok_budget"])
	
	# 4. Data per Day (MB/día)
	data_bar.max_value = maxf(stats["max_link_data"], float(mission["min_science_mb"]))
	data_bar.value = clampf(stats["total_data_mb"], 0.0, data_bar.max_value)
	data_label.text = "Data/Day: %.0f MB (Min %.0f)" % [stats["total_data_mb"], mission["min_science_mb"]]
	_tint_bar(data_bar, stats["ok_data"])
	
	# 5. Comms (kbps)
	comms_bar.max_value = 25000.0
	comms_bar.value = clampf(stats["total_comms_kbps"], 0.0, comms_bar.max_value)
	comms_label.text = "Comms: %.0f kbps" % stats["total_comms_kbps"]
	
	# 6. Time (Months)
	time_bar.max_value = float(mission["max_time_months"])
	time_bar.value = clampf(stats["total_time"], 0.0, time_bar.max_value)
	time_label.text = "Time: %.0f / %.0f Months" % [stats["total_time"], mission["max_time_months"]]
	_tint_bar(time_bar, stats["ok_time"])


func _tint_bar(bar: ProgressBar, is_valid: bool) -> void:
	bar.modulate = Color(0.4, 0.9, 1.0) if is_valid else Color(1.0, 0.35, 0.35)


func _on_close_pressed() -> void:
	customizer_closed.emit()
	queue_free()
