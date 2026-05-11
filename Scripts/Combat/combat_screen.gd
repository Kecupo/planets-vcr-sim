class_name CombatScreen
extends Node2D
@onready var top_hud_frame: Control = $UI/TopHudFrame
@onready var bottom_hud_frame: Control = $UI/BottomHudFrame
@onready var top_bar: Control = $UI/TopBar
@onready var left_info_panel: Control = $UI/LeftInfoPanel
@onready var right_info_panel: Control = $UI/RightInfoPanel
@onready var weapon_panel: Control = $UI/WeaponPanel

@onready var left_name_label: Label = $UI/TopBar/LeftName
@onready var right_name_label: Label = $UI/TopBar/RightName
@onready var time_label: Label = $UI/TopBar/TimeLabel
@onready var distance_label: Label = $UI/TopBar/DistanceLabel
@onready var vcr_index_label: Label = $UI/TopBar/VcrIndexLabel

@onready var left_shield_label: Label = $UI/LeftInfoPanel/LeftShieldLabel
@onready var left_damage_label: Label = $UI/LeftInfoPanel/LeftDamageLabel
@onready var left_crew_label: Label = $UI/LeftInfoPanel/LeftCrewLabel
@onready var left_fighters_label: Label = $UI/LeftInfoPanel/LeftFightersLabel
@onready var left_torps_label: Label = $UI/LeftInfoPanel/LeftTorpsLabel

@onready var right_shield_label: Label = $UI/RightInfoPanel/RightShieldLabel
@onready var right_damage_label: Label = $UI/RightInfoPanel/RightDamageLabel
@onready var right_crew_label: Label = $UI/RightInfoPanel/RightCrewLabel
@onready var right_fighters_label: Label = $UI/RightInfoPanel/RightFightersLabel
@onready var right_torps_label: Label = $UI/RightInfoPanel/RightTorpsLabel

@onready var left_beam_title: Label = $UI/WeaponPanel/LeftBeamTitle
@onready var left_torp_title: Label = $UI/WeaponPanel/LeftTorpTitle
@onready var left_bay_title: Label = $UI/WeaponPanel/LeftBayTitle
@onready var right_beam_title: Label = $UI/WeaponPanel/RightBeamTitle
@onready var right_torp_title: Label = $UI/WeaponPanel/RightTorpTitle
@onready var right_bay_title: Label = $UI/WeaponPanel/RightBayTitle

@onready var left_beam_bank: WeaponBankView = $UI/WeaponPanel/LeftBeamBank
@onready var left_torp_bank: WeaponBankView = $UI/WeaponPanel/LeftTorpBank
@onready var left_bay_bank: WeaponBankView = $UI/WeaponPanel/LeftBayBank
@onready var right_beam_bank: WeaponBankView = $UI/WeaponPanel/RightBeamBank
@onready var right_torp_bank: WeaponBankView = $UI/WeaponPanel/RightTorpBank
@onready var right_bay_bank: WeaponBankView = $UI/WeaponPanel/RightBayBank
@onready var simulation_overlay: Control = $UI/SimulationOverlay
@onready var simulation_result_label: Label = $UI/SimulationOverlay/Panel/SimulationResultLabel
@onready var buttons_bar: MenuBar = $UI/Buttons
@onready var start_button: Button = $UI/Buttons/StartButton
@onready var step_button: Button = $UI/Buttons/StepButton
@onready var fast_button: Button = $UI/Buttons/FastButton
@onready var reset_button: Button = $UI/Buttons/ResetButton
@onready var simulate_button: Button = $UI/Buttons/SimulateButton
@onready var prev_button: Button = $UI/Buttons/PrevButton
@onready var next_button: Button = $UI/Buttons/NextButton
@onready var close_app_button: Button = $UI/Buttons/CloseAppButton

@onready var left_ship: ShipView = $BattleArea/Ships/LeftShip
@onready var right_ship: ShipView = $BattleArea/Ships/RightShip

@onready var fighters_layer: Node2D = $BattleArea/Fighters
@onready var torpedoes_layer: Node2D = $BattleArea/Torpedoes
@onready var effects_layer: Node2D = $BattleArea/Effects
@onready var background_sprite: Sprite2D = $BattleArea/Background

var simulator: CombatSimulatorThost = CombatSimulatorThost.new()
var engine: CombatEngineThost = CombatEngineThost.new()
var current_vcr: ClassicVcr = ClassicVcr.new()
var FIGHTER_LEFT_BASE_OFFSET: float = -50.0
var FIGHTER_RIGHT_BASE_OFFSET: float = 50.0
var TORP_LEFT_BASE_OFFSET: float = -22.0
var TORP_RIGHT_BASE_OFFSET: float = 22.0
var _fighter_views_left: Array[FighterView] = []
var _fighter_views_right: Array[FighterView] = []
var _pending_torp_hit_projectiles: Dictionary = {}
var _left_visual_key: String = ""
var _right_visual_key: String = ""
var left_status_bar: ShieldDamageBar = null
var right_status_bar: ShieldDamageBar = null
var simulation_progress_bar: ProgressBar = null
var simulation_progress_label: Label = null
var _simulation_in_progress: bool = false

var _running: bool = false
var _run_speed: int = 1
var _cycle_accumulator: float = 0.0
var _seconds_per_cycle: float = 0.06
var _turn_data: Dictionary = {}
var _turn_vcrs: Array = []
var _current_vcr_index: int = 0
var _battle_builder_mode: bool = false
var battle_sim_button: Button = null
var button_bar_frame: CombatHudFrame = null
var battle_setup_overlay: Control = null
var battle_setup_panel: Panel = null
var _builder_controls: Dictionary = {}
var TOP_UI_HEIGHT: float = 95.0
var BOTTOM_UI_HEIGHT: float = 120.0
var BATTLE_LEFT_MARGIN: float = 30.0
var BATTLE_RIGHT_MARGIN: float = 30.0
var _visual_track_left_bound: float = 30.0
var _visual_track_right_bound: float = 610.0

var BATTLE_TOP: float = 95.0
var BATTLE_BOTTOM: float = 600.0
var BATTLE_HEIGHT: float = 505.0
var BATTLE_CENTER_Y: float = 0.0

var SHIP_Y: float = 0.0
const FIGHTER_VIEW_SCENE := preload("res://Scenes/Combat/fighter_sprite_2d.tscn")
const DEFAULT_TURN_FILE: String = "user://latest_turn.json"
const PROJECT_TURN_FILE: String = "res://latest_turn.json"
const PROJECT_DEFAULT_SHIP_DATA_FILE: String = "res://default_ship_data.json"

func _ready() -> void:
	var turn_file_path: String = _resolve_turn_file_path()
	var loaded_ship_data: bool = false

	if turn_file_path != "" and FileAccess.file_exists(turn_file_path):
		if ShipData.load_from_turn_file(turn_file_path):
			loaded_ship_data = true
			_load_turn_file(turn_file_path)
		else:
			print("Could not load weapon/spec data from ", turn_file_path)
	else:
		print("No latest_turn.json found; starting without loaded VCRs.")

	if not loaded_ship_data and FileAccess.file_exists(PROJECT_DEFAULT_SHIP_DATA_FILE):
		if ShipData.load_from_turn_file(PROJECT_DEFAULT_SHIP_DATA_FILE):
			loaded_ship_data = true
			_load_turn_file(PROJECT_DEFAULT_SHIP_DATA_FILE)
		else:
			print("Could not load default ship data from ", PROJECT_DEFAULT_SHIP_DATA_FILE)

	_ensure_battle_builder_ui()
	_ensure_status_bars()
	_ensure_simulation_progress_ui()
	_apply_ui_layout()
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_connect_buttons()
	_apply_background()
	simulation_overlay.visible = false
	if _turn_vcrs.size() > 0:
		_load_current_vcr()
	else:
		_show_no_vcr_state()

func _on_viewport_size_changed() -> void:
	_apply_ui_layout()
	if engine != null:
		_refresh_view()


func _ensure_status_bars() -> void:
	if left_status_bar == null:
		left_status_bar = ShieldDamageBar.new()
		left_status_bar.name = "LeftStatusBar"
		left_info_panel.add_child(left_status_bar)
	if right_status_bar == null:
		right_status_bar = ShieldDamageBar.new()
		right_status_bar.name = "RightStatusBar"
		right_info_panel.add_child(right_status_bar)

	left_shield_label.visible = false
	left_damage_label.visible = false
	right_shield_label.visible = false
	right_damage_label.visible = false


func _ensure_simulation_progress_ui() -> void:
	var panel: Control = simulation_result_label.get_parent() as Control
	if panel == null:
		return

	if simulation_progress_label == null:
		simulation_progress_label = Label.new()
		simulation_progress_label.name = "ProgressLabel"
		simulation_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(simulation_progress_label)

	if simulation_progress_bar == null:
		simulation_progress_bar = ProgressBar.new()
		simulation_progress_bar.name = "ProgressBar"
		simulation_progress_bar.min_value = 0.0
		simulation_progress_bar.max_value = 118.0
		simulation_progress_bar.step = 1.0
		simulation_progress_bar.show_percentage = false
		panel.add_child(simulation_progress_bar)

func _resolve_turn_file_path() -> String:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	for arg: String in user_args:
		if arg.begins_with("--turn-file="):
			return arg.substr("--turn-file=".length())
		if arg.to_lower().ends_with(".json"):
			return arg

	if FileAccess.file_exists(DEFAULT_TURN_FILE):
		return DEFAULT_TURN_FILE
	if OS.has_feature("editor") and FileAccess.file_exists(PROJECT_TURN_FILE):
		return PROJECT_TURN_FILE
	return ""

func _apply_ui_layout() -> void:
	_ensure_button_bar_frame()
	var size: Vector2 = get_viewport_rect().size
	var w: float = size.x
	var h: float = size.y
	TOP_UI_HEIGHT = 82.0
	BOTTOM_UI_HEIGHT = 230.0
	var button_h: float = 48.0
	var buttons_y: float = h - button_h - 18.0
	var bottom_y: float = h - BOTTOM_UI_HEIGHT - 18.0
	buttons_bar.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	buttons_bar.position = Vector2(18.0, buttons_y)
	buttons_bar.size = Vector2(w - 36.0, 44.0)
	buttons_bar.z_index = 20
	buttons_bar.visible = true

	var bx: float = 8.0
	var by: float = 6.0
	var bw: float = 95.0
	var bh: float = 28.0
	var gap: float = 8.0

	prev_button.position = Vector2(bx, by)
	prev_button.size = Vector2(bw, bh)
	bx += bw + gap

	next_button.position = Vector2(bx, by)
	next_button.size = Vector2(bw, bh)
	bx += bw + gap

	start_button.position = Vector2(bx, by)
	start_button.size = Vector2(bw, bh)
	bx += bw + gap

	step_button.position = Vector2(bx, by)
	step_button.size = Vector2(bw, bh)
	bx += bw + gap

	fast_button.position = Vector2(bx, by)
	fast_button.size = Vector2(bw, bh)
	bx += bw + gap

	reset_button.position = Vector2(bx, by)
	reset_button.size = Vector2(bw, bh)
	bx += bw + gap

	simulate_button.position = Vector2(bx, by + 1.0)
	simulate_button.size = Vector2(bw + 20.0, bh)
	simulate_button.visible = false

	close_app_button.position = Vector2(w - 135.0, by)
	close_app_button.size = Vector2(110.0, bh)

	if battle_sim_button != null:
		var battle_button_w: float = 178.0
		var sim_right: float = reset_button.position.x + reset_button.size.x
		var close_left: float = close_app_button.position.x
		var centered_x: float = ((sim_right + close_left) * 0.5) - battle_button_w * 0.5
		battle_sim_button.position = Vector2(clamp(centered_x, sim_right + gap, close_left - battle_button_w - gap), 1.0)
		battle_sim_button.size = Vector2(battle_button_w, 40.0)
	
	var info_h: float = buttons_y - bottom_y - 10.0

	BATTLE_TOP = TOP_UI_HEIGHT
	BATTLE_BOTTOM = bottom_y
	BATTLE_HEIGHT = BATTLE_BOTTOM - BATTLE_TOP
	BATTLE_CENTER_Y = BATTLE_TOP + BATTLE_HEIGHT * 0.5
	SHIP_Y = BATTLE_CENTER_Y + 18.0

	top_hud_frame.position = Vector2(6.0, 6.0)
	top_hud_frame.size = Vector2(w - 12.0, TOP_UI_HEIGHT - 12.0)
	top_hud_frame.queue_redraw()

	bottom_hud_frame.position = Vector2(6.0, bottom_y - 6.0)
	bottom_hud_frame.size = Vector2(w - 12.0, buttons_y - bottom_y - 8.0)
	bottom_hud_frame.queue_redraw()

	button_bar_frame.position = Vector2(6.0, buttons_y - 6.0)
	button_bar_frame.size = Vector2(w - 12.0, h - buttons_y - 12.0)
	button_bar_frame.queue_redraw()

	top_bar.position = Vector2(0.0, 0.0)
	top_bar.size = Vector2(w, TOP_UI_HEIGHT)

	left_name_label.position = Vector2(40.0, 14.0)
	left_name_label.size = Vector2(430.0, 52.0)
	left_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	right_name_label.position = Vector2(w - 470.0, 14.0)
	right_name_label.size = Vector2(430.0, 52.0)
	right_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	time_label.position = Vector2(w * 0.5 - 120.0, 16.0)
	time_label.size = Vector2(100.0, 24.0)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	distance_label.position = Vector2(w * 0.5 + 20.0, 16.0)
	distance_label.size = Vector2(160.0, 24.0)
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	vcr_index_label.position = Vector2(w * 0.5 - 200.0, 43.0)
	vcr_index_label.size = Vector2(400.0, 24.0)
	vcr_index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var side_info_w: float = clampf(w * 0.18, 180.0, 330.0)
	if w >= 1500.0:
		side_info_w = 330.0
	var side_margin: float = 24.0
	var weapon_gap: float = clampf(w * 0.018, 16.0, 34.0)

	left_info_panel.position = Vector2(side_margin, bottom_y + 8.0)
	left_info_panel.size = Vector2(side_info_w, info_h - 16.0)

	right_info_panel.position = Vector2(w - side_margin - side_info_w, bottom_y + 8.0)
	right_info_panel.size = Vector2(side_info_w, info_h - 16.0)

	var status_bar_w: float = 116.0
	var status_bar_h: float = max(82.0, left_info_panel.size.y - 16.0)
	if left_status_bar != null:
		left_status_bar.position = Vector2(12.0, 8.0)
		left_status_bar.size = Vector2(status_bar_w, status_bar_h)
		left_status_bar.visible = true
	if right_status_bar != null:
		right_status_bar.position = Vector2(12.0, 8.0)
		right_status_bar.size = Vector2(status_bar_w, status_bar_h)
		right_status_bar.visible = true

	left_shield_label.visible = false
	left_damage_label.visible = false
	right_shield_label.visible = false
	right_damage_label.visible = false

	var stat_x: float = 46.0
	var stat_w: float = max(74.0, side_info_w - stat_x - 8.0)
	var stat_y: float = max(24.0, status_bar_h * 0.5 - 18.0)
	# Info labels links
	left_crew_label.position = Vector2(stat_x, stat_y)
	left_fighters_label.position = Vector2(stat_x, stat_y + 22.0)
	left_torps_label.position = Vector2(stat_x, stat_y + 44.0)

	# Info labels rechts
	right_crew_label.position = Vector2(stat_x, stat_y)
	right_fighters_label.position = Vector2(stat_x, stat_y + 22.0)
	right_torps_label.position = Vector2(stat_x, stat_y + 44.0)

	left_crew_label.size = Vector2(stat_w, 20.0)
	left_fighters_label.size = Vector2(stat_w, 20.0)
	left_torps_label.size = Vector2(stat_w, 20.0)
	right_crew_label.size = Vector2(stat_w, 20.0)
	right_fighters_label.size = Vector2(stat_w, 20.0)
	right_torps_label.size = Vector2(stat_w, 20.0)
	var weapon_x: float = left_info_panel.position.x + left_info_panel.size.x + weapon_gap
	var weapon_right: float = right_info_panel.position.x - weapon_gap
	weapon_panel.position = Vector2(weapon_x, bottom_y + 10.0)
	weapon_panel.size = Vector2(max(240.0, weapon_right - weapon_x), info_h - 8.0)

	var wp_w: float = weapon_panel.size.x

	var weapon_title_y: float = max(122.0, weapon_panel.size.y - 18.0)
	var side_weapon_gap: float = clampf(wp_w * 0.04, 20.0, 46.0)
	var side_weapon_w: float = max(96.0, (wp_w - side_weapon_gap) * 0.5)
	var right_weapon_x: float = side_weapon_w + side_weapon_gap
	var tight_weapon_layout: bool = side_weapon_w < 160.0
	var beam_title_x: float = 0.0
	var beam_bank_x: float = 20.0
	var torp_title_x: float = clampf(side_weapon_w * 0.52, 56.0 if tight_weapon_layout else 88.0, 210.0)
	var torp_bank_x: float = torp_title_x + 20.0
	var bay_title_x: float = clampf(side_weapon_w * 0.76, 92.0 if tight_weapon_layout else 132.0, 300.0)
	var bay_bank_x: float = bay_title_x + 20.0
	var compact_weapon_layout: bool = wp_w < 620.0
	var beam_slot_w: float = 28.0 if tight_weapon_layout else (32.0 if compact_weapon_layout else 36.0)

	left_beam_title.position = Vector2(beam_title_x, weapon_title_y)
	left_beam_title.size = Vector2(140.0, 20.0)
	_style_weapon_title(left_beam_title)
	left_beam_bank.position = Vector2(beam_bank_x, 0.0)

	left_torp_title.position = Vector2(torp_title_x, weapon_title_y)
	left_torp_title.size = Vector2(120.0, 20.0)
	_style_weapon_title(left_torp_title)
	left_torp_bank.position = Vector2(torp_bank_x, 0.0)

	left_bay_title.position = Vector2(bay_title_x, weapon_title_y)
	left_bay_title.size = Vector2(120.0, 20.0)
	_style_weapon_title(left_bay_title)
	left_bay_bank.position = Vector2(bay_bank_x, 0.0)

	right_beam_title.position = Vector2(right_weapon_x + beam_title_x, weapon_title_y)
	right_beam_title.size = Vector2(140.0, 20.0)
	_style_weapon_title(right_beam_title)
	right_beam_bank.position = Vector2(right_weapon_x + beam_bank_x, 0.0)

	right_torp_title.position = Vector2(right_weapon_x + torp_title_x, weapon_title_y)
	right_torp_title.size = Vector2(120.0, 20.0)
	_style_weapon_title(right_torp_title)
	right_torp_bank.position = Vector2(right_weapon_x + torp_bank_x, 0.0)

	right_bay_title.position = Vector2(right_weapon_x + bay_title_x, weapon_title_y)
	right_bay_title.size = Vector2(120.0, 20.0)
	_style_weapon_title(right_bay_title)
	right_bay_bank.position = Vector2(right_weapon_x + bay_bank_x, 0.0)

	left_beam_bank.set_slot_metrics(beam_slot_w, 10.0, 4.0)
	right_beam_bank.set_slot_metrics(beam_slot_w, 10.0, 4.0)

	left_torp_bank.set_slot_metrics(12.0, 10.0, 4.0)
	right_torp_bank.set_slot_metrics(12.0, 10.0, 4.0)

	left_bay_bank.set_slot_metrics(12.0, 10.0, 4.0)
	right_bay_bank.set_slot_metrics(12.0, 10.0, 4.0)

	left_torp_bank.value_scale = 100.0 / 30.0
	right_torp_bank.value_scale = 100.0 / 30.0

	_layout_simulation_result_label()

	_apply_background()
	_layout_battle_builder_ui()

func _process(delta: float) -> void:
	if not _running:
		return

	_cycle_accumulator += delta

	while _cycle_accumulator >= _seconds_per_cycle:
		_cycle_accumulator -= _seconds_per_cycle

		for _i: int in range(_run_speed):
			var still_running: bool = engine.play_cycle()
			if not still_running:
				engine.finish_battle()
				_running = false
				_cycle_accumulator = 0.0
				return

func _connect_buttons() -> void:
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	if not step_button.pressed.is_connected(_on_step_button_pressed):
		step_button.pressed.connect(_on_step_button_pressed)
	if not fast_button.pressed.is_connected(_on_fast_button_pressed):
		fast_button.pressed.connect(_on_fast_button_pressed)
	if not reset_button.pressed.is_connected(_on_reset_button_pressed):
		reset_button.pressed.connect(_on_reset_button_pressed)
	if not simulate_button.pressed.is_connected(_on_simulate_button_pressed):
		simulate_button.pressed.connect(_on_simulate_button_pressed)
	if not prev_button.pressed.is_connected(_on_prev_button_pressed):
		prev_button.pressed.connect(_on_prev_button_pressed)
	if not next_button.pressed.is_connected(_on_next_button_pressed):
		next_button.pressed.connect(_on_next_button_pressed)
	if not close_app_button.pressed.is_connected(_on_close_app_button_pressed):
		close_app_button.pressed.connect(_on_close_app_button_pressed)
	if battle_sim_button != null and not battle_sim_button.pressed.is_connected(_on_battle_sim_button_pressed):
		battle_sim_button.pressed.connect(_on_battle_sim_button_pressed)


func _ensure_button_bar_frame() -> void:
	if button_bar_frame != null:
		return

	button_bar_frame = CombatHudFrame.new()
	button_bar_frame.name = "ButtonBarFrame"
	button_bar_frame.z_index = 19
	var ui_layer: CanvasLayer = $UI
	ui_layer.add_child(button_bar_frame)
	ui_layer.move_child(button_bar_frame, buttons_bar.get_index())
	buttons_bar.z_index = 20


func _style_weapon_title(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 14)
	label.clip_text = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF


func _style_builder_checkbox(check_box: CheckBox) -> void:
	check_box.add_theme_icon_override("unchecked", _make_checkbox_icon(false))
	check_box.add_theme_icon_override("checked", _make_checkbox_icon(true))
	check_box.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
	check_box.add_theme_color_override("font_hover_color", Color.WHITE)
	check_box.add_theme_font_size_override("font_size", 14)


func _make_checkbox_icon(checked: bool) -> Texture2D:
	var image: Image = Image.create(18, 18, false, Image.FORMAT_RGBA8)
	var fill_color: Color = Color(0.04, 0.05, 0.07, 1.0)
	var border_color: Color = Color(0.78, 0.90, 1.0, 1.0)
	var check_color: Color = Color(0.15, 0.72, 1.0, 1.0)
	image.fill(Color(0, 0, 0, 0))

	for y: int in range(18):
		for x: int in range(18):
			if x <= 1 or y <= 1 or x >= 16 or y >= 16:
				image.set_pixel(x, y, border_color)
			else:
				image.set_pixel(x, y, fill_color)

	if checked:
		for offset: int in range(3):
			image.set_pixel(5 + offset, 9 + offset, check_color)
			image.set_pixel(6 + offset, 9 + offset, check_color)
			image.set_pixel(8 + offset, 11 - offset, check_color)
			image.set_pixel(9 + offset, 10 - offset, check_color)

	return ImageTexture.create_from_image(image)


func _set_playback_buttons_enabled(enabled: bool) -> void:
	start_button.disabled = not enabled
	step_button.disabled = not enabled
	fast_button.disabled = not enabled
	reset_button.disabled = not enabled
	simulate_button.disabled = not enabled
	prev_button.disabled = not enabled or _turn_vcrs.is_empty()
	next_button.disabled = not enabled or _turn_vcrs.is_empty()
	if battle_sim_button != null:
		battle_sim_button.disabled = false


func _show_no_vcr_state() -> void:
	_running = false
	_battle_builder_mode = false
	_set_playback_buttons_enabled(false)

	left_ship.visible = false
	right_ship.visible = false
	left_name_label.text = ""
	right_name_label.text = ""
	time_label.text = "Time: 0"
	distance_label.text = ""
	vcr_index_label.text = "No VCRs loaded - use Battle Simulator"

	left_shield_label.text = ""
	left_damage_label.text = ""
	left_crew_label.text = ""
	left_fighters_label.text = ""
	left_torps_label.text = ""
	right_shield_label.text = ""
	right_damage_label.text = ""
	right_crew_label.text = ""
	right_fighters_label.text = ""
	right_torps_label.text = ""
	if left_status_bar != null:
		left_status_bar.set_values(0, 0, 100, 100)
		left_status_bar.visible = false
	if right_status_bar != null:
		right_status_bar.set_values(0, 0, 100, 100)
		right_status_bar.visible = false

	left_beam_title.visible = false
	left_torp_title.visible = false
	left_bay_title.visible = false
	right_beam_title.visible = false
	right_torp_title.visible = false
	right_bay_title.visible = false

	var empty_values: PackedInt32Array = PackedInt32Array()
	left_beam_bank.set_values(empty_values, 0)
	left_torp_bank.set_values(empty_values, 0)
	left_bay_bank.set_values(empty_values, 0)
	right_beam_bank.set_values(empty_values, 0)
	right_torp_bank.set_values(empty_values, 0)
	right_bay_bank.set_values(empty_values, 0)
	_clear_effect_layers()


func _reset_battle() -> void:
	_running = false
	_set_playback_buttons_enabled(true)
	engine = CombatEngineThost.new()
	engine.init_vcr(current_vcr)

	_bind_engine()
	_apply_static_labels()
	_setup_ship_views()
	_rebuild_fighters()
	_clear_effect_layers()
	_refresh_view()

func _bind_engine() -> void:
	if not engine.cycle_completed.is_connected(_on_cycle_completed):
		engine.cycle_completed.connect(_on_cycle_completed)

	if not engine.battle_finished.is_connected(_on_battle_finished):
		engine.battle_finished.connect(_on_battle_finished)

	if not engine.beam_fired.is_connected(_on_beam_fired):
		engine.beam_fired.connect(_on_beam_fired)

	if not engine.torpedo_fired.is_connected(_on_torpedo_fired):
		engine.torpedo_fired.connect(_on_torpedo_fired)

	if not engine.fighter_intercept_beam.is_connected(_on_fighter_intercept_beam):
		engine.fighter_intercept_beam.connect(_on_fighter_intercept_beam)
		
	if not engine.beam_hit_fighter.is_connected(_on_beam_hit_fighter):
		engine.beam_hit_fighter.connect(_on_beam_hit_fighter)
		
	if not engine.hit_resolved.is_connected(_on_hit_resolved):
		engine.hit_resolved.connect(_on_hit_resolved)

func _apply_static_labels() -> void:
	var left_obj := engine.state.left.obj
	var right_obj := engine.state.right.obj

	left_ship.set_ship_name(left_obj.object_name)
	right_ship.set_ship_name(right_obj.object_name)
	left_ship.visible = true
	right_ship.visible = true
	left_name_label.text = "%s (ID %d) - %s\nCombat Mass: %d" % [
		left_obj.object_name,
		left_obj.object_id,
		_get_race_short(left_obj.race_id),
		left_obj.mass
	]

	right_name_label.text = "%s (ID %d) - %s\nCombat Mass: %d" % [
		right_obj.object_name,
		right_obj.object_id,
		_get_race_short(right_obj.race_id),
		right_obj.mass
	]

	_apply_weapon_titles()

func _setup_ship_views() -> void:
	left_ship.body_color = Color(0.80, 0.90, 1.00, 1.0)
	right_ship.body_color = Color(1.00, 0.82, 0.72, 1.0)

	left_ship.set_facing(true)
	right_ship.set_facing(false)
	_apply_side_visual(left_ship, engine.state.left.obj)
	_apply_side_visual(right_ship, engine.state.right.obj)
	_left_visual_key = _side_visual_key(engine.state.left.obj)
	_right_visual_key = _side_visual_key(engine.state.right.obj)

func _apply_side_visual(view: ShipView, obj: CombatObject) -> void:
	if obj.is_planet:
		view.set_planet_texture(obj.planet_img)
		if obj.has_starbase:
			view.set_starbase_overlay(obj.starbase_style)
		else:
			view.clear_starbase_overlay()
	else:
		view.set_ship_texture(obj.hull_id, _squadron_visual_count(obj))
		view.clear_starbase_overlay()

func _side_visual_key(obj: CombatObject) -> String:
	if obj.is_planet:
		return "planet:%s:%s:%d" % [obj.planet_img, str(obj.has_starbase), obj.starbase_style]
	return "ship:%d:%d" % [obj.hull_id, _squadron_visual_count(obj)]

func _squadron_visual_count(obj: CombatObject) -> int:
	if not ShipData.is_squadron_hull(obj.hull_id):
		return 1
	return clamp(obj.beam_count, 1, 5)
		
func _rebuild_fighters() -> void:
	for child: Node in fighters_layer.get_children():
		child.queue_free()

	_fighter_views_left.clear()
	_fighter_views_right.clear()

	for i: int in range(CombatConstants.MAX_FIGHTERS):
		var left_f := FIGHTER_VIEW_SCENE.instantiate() as FighterView
		left_f.setup(CombatTypes.Side.LEFT, i)
		left_f.visible = false
		fighters_layer.add_child(left_f)
		_fighter_views_left.append(left_f)

		var right_f := FIGHTER_VIEW_SCENE.instantiate() as FighterView
		right_f.setup(CombatTypes.Side.RIGHT, i)
		right_f.visible = false
		fighters_layer.add_child(right_f)
		_fighter_views_right.append(right_f)

func _clear_effect_layers() -> void:
	_pending_torp_hit_projectiles.clear()
	for child: Node in torpedoes_layer.get_children():
		child.queue_free()

	for child: Node in effects_layer.get_children():
		child.queue_free()

func _refresh_view() -> void:
	time_label.text = "Time: %d" % engine.state.time
	distance_label.text = "Distance: %d" % ((engine.state.right.cur_x - engine.state.left.cur_x) * 100)

	if left_status_bar != null:
		left_status_bar.visible = true
		left_status_bar.set_values(
			engine.state.left.obj.shield,
			engine.state.left.obj.damage,
			engine.state.left.initial_shield,
			engine.state.left.obj.damage_limit
		)
	left_crew_label.text = "Crew: %d" % engine.state.left.obj.crew
	_update_ammo_labels(
		left_fighters_label,
		left_torps_label,
		engine.state.left.obj
	)

	if right_status_bar != null:
		right_status_bar.visible = true
		right_status_bar.set_values(
			engine.state.right.obj.shield,
			engine.state.right.obj.damage,
			engine.state.right.initial_shield,
			engine.state.right.obj.damage_limit
		)
	right_crew_label.text = "Crew: %d" % engine.state.right.obj.crew
	_update_ammo_labels(
		right_fighters_label,
		right_torps_label,
		engine.state.right.obj
	)

	_refresh_dynamic_ship_visuals()
	_apply_weapon_titles()

	left_beam_bank.set_values(engine.state.left.beam_status, engine.state.left.obj.beam_count)
	left_torp_bank.set_values(engine.state.left.torp_status, engine.state.left.obj.torp_launcher_count)
	left_bay_bank.set_values(_build_bay_status(engine.state.left), _visible_bay_slot_count(engine.state.left.obj))

	right_beam_bank.set_values(engine.state.right.beam_status, engine.state.right.obj.beam_count)
	right_torp_bank.set_values(engine.state.right.torp_status, engine.state.right.obj.torp_launcher_count)
	right_bay_bank.set_values(_build_bay_status(engine.state.right), _visible_bay_slot_count(engine.state.right.obj))

	var left_half_w: float = left_ship.get_visual_width() * 0.5
	var right_half_w: float = right_ship.get_visual_width() * 0.5

	var viewport_width: float = get_viewport_rect().size.x
	_update_visual_track_bounds(left_half_w, right_half_w, viewport_width)

	var left_x: float = battle_x_to_screen_x(engine.state.left.cur_x)
	var right_x: float = battle_x_to_screen_x(engine.state.right.cur_x)

	var min_gap: float = 24.0
	var desired_distance: float = left_half_w + right_half_w + min_gap

	var max_possible_distance: float = viewport_width - (left_half_w + right_half_w) - 12.0
	var actual_distance: float = min(desired_distance, max_possible_distance)

	if right_x - left_x < actual_distance:
		var mid_x: float = (left_x + right_x) * 0.5

		left_x = mid_x - actual_distance * 0.5
		right_x = mid_x + actual_distance * 0.5

	var min_left_x: float = left_half_w + 6.0
	var max_right_x: float = viewport_width - right_half_w - 6.0
	if left_x < min_left_x:
		var shift_right: float = min_left_x - left_x
		left_x += shift_right
		right_x += shift_right
	if right_x > max_right_x:
		var shift_left: float = right_x - max_right_x
		left_x -= shift_left
		right_x -= shift_left

	left_ship.position = Vector2(left_x, SHIP_Y)
	right_ship.position = Vector2(right_x, SHIP_Y)

	_refresh_fighters()


func _refresh_dynamic_ship_visuals() -> void:
	var left_key: String = _side_visual_key(engine.state.left.obj)
	if left_key != _left_visual_key:
		_apply_side_visual(left_ship, engine.state.left.obj)
		_left_visual_key = left_key

	var right_key: String = _side_visual_key(engine.state.right.obj)
	if right_key != _right_visual_key:
		_apply_side_visual(right_ship, engine.state.right.obj)
		_right_visual_key = right_key


func _update_ammo_labels(fighters_label: Label, torps_label: Label, obj: CombatObject) -> void:
	fighters_label.visible = obj.bay_count > 0
	torps_label.visible = obj.torp_launcher_count > 0

	fighters_label.text = "Fighters: %d" % obj.fighter_count if obj.bay_count > 0 else ""
	torps_label.text = "Torps: %d" % obj.torp_count if obj.torp_launcher_count > 0 else ""

func _build_bay_status(side: CombatState.SideState) -> PackedInt32Array:
	var values: PackedInt32Array = PackedInt32Array()
	var visible_count: int = _visible_bay_slot_count(side.obj)
	values.resize(visible_count)

	for i: int in range(visible_count):
		if i < CombatConstants.MAX_FIGHTERS and side.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
			values[i] = 0
		else:
			values[i] = 100

	return values


func _visible_bay_slot_count(obj: CombatObject) -> int:
	var base_count: int = obj.bay_count - clamp(obj.bay_bonus_count, 0, obj.bay_count)
	if base_count <= 0:
		base_count = obj.bay_count
	return min(10, base_count)

func _refresh_fighters() -> void:
	for i: int in range(CombatConstants.MAX_FIGHTERS):
		var left_active: bool = engine.state.left.fighter_active[i] != CombatConstants.FIGHTER_IDLE
		var left_view: FighterView = _fighter_views_left[i]
		left_view.visible = left_active
		left_view.set_returning(engine.state.left.fighter_active[i] == CombatConstants.FIGHTER_RETURNS)
		if left_active:
			left_view.position = Vector2(
				battle_x_to_screen_x(engine.state.left.fighter_x[i]),
				_fighter_lane_y_left(i)
			)

		var right_active: bool = engine.state.right.fighter_active[i] != CombatConstants.FIGHTER_IDLE
		var right_view: FighterView = _fighter_views_right[i]
		right_view.visible = right_active
		right_view.set_returning(engine.state.right.fighter_active[i] == CombatConstants.FIGHTER_RETURNS)
		if right_active:
			right_view.position = Vector2(
				battle_x_to_screen_x(engine.state.right.fighter_x[i]),
				_fighter_lane_y_right(i)
			)

func _on_cycle_completed(_time: int) -> void:
	_refresh_view()

func _on_battle_finished(_status_word: int) -> void:
	_refresh_view()

	var left_destroyed: bool = _is_visually_destroyed(engine.state.left.obj)
	var right_destroyed: bool = _is_visually_destroyed(engine.state.right.obj)

	if left_destroyed:
		_defer_until_projectiles_finish(
			func() -> void:
				_spawn_big_explosion(
					left_ship.position,
					max(left_ship.get_visual_width(), left_ship.get_visual_height())
				)
				left_ship.visible = false
		)

	if right_destroyed:
		_defer_until_projectiles_finish(
			func() -> void:
				_spawn_big_explosion(
					right_ship.position,
					max(right_ship.get_visual_width(), right_ship.get_visual_height())
				)
				right_ship.visible = false
		)

func _on_start_button_pressed() -> void:
	_hide_simulation_results()
	_reset_battle()
	_run_speed = 1
	_cycle_accumulator = 0.0
	_seconds_per_cycle = 0.06
	_running = true

func _on_step_button_pressed() -> void:
	_hide_simulation_results()
	var still_running: bool = engine.play_cycle()
	if not still_running:
		engine.finish_battle()
	else:
		_refresh_view()

func _on_fast_button_pressed() -> void:
	_hide_simulation_results()
	_run_speed = 2
	_cycle_accumulator = 0.0
	_seconds_per_cycle = 0.05
	_running = true

func _on_reset_button_pressed() -> void:
	if _battle_builder_mode:
		_hide_simulation_results()
		_reset_battle()
		vcr_index_label.text = "BattleSimulator"
		return

	_load_current_vcr()


func _hide_simulation_results() -> void:
	_simulation_in_progress = false
	simulation_result_label.text = ""
	simulation_result_label.visible = false
	if simulation_progress_bar != null:
		simulation_progress_bar.visible = false
	if simulation_progress_label != null:
		simulation_progress_label.visible = false
	simulation_overlay.visible = false

func _on_beam_fired(side: int, from_x: int, to_x: int, from_is_fighter: bool, track_id: int) -> void:
	var from_pos: Vector2
	var to_pos: Vector2

	# --- Startposition ---
	if from_is_fighter:
		if side == CombatTypes.Side.LEFT:
			from_pos = Vector2(
				battle_x_to_screen_x(from_x),
				_fighter_lane_y_left(track_id)
			)
		else:
			from_pos = Vector2(
				battle_x_to_screen_x(from_x),
				_fighter_lane_y_right(track_id)
			)
	else:
		from_pos = Vector2(
			battle_x_to_screen_x(from_x),
			SHIP_Y
		)

	# --- Zielposition ---
	var target_y: float = SHIP_Y

	# Prüfen: gibt es einen Fighter genau an dieser X-Position?
	for i: int in range(CombatConstants.MAX_FIGHTERS):
		if side == CombatTypes.Side.LEFT:
			if engine.state.right.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
				if engine.state.right.fighter_x[i] == to_x:
					target_y = _fighter_lane_y_right(i)
					break
		else:
			if engine.state.left.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
				if engine.state.left.fighter_x[i] == to_x:
					target_y = _fighter_lane_y_left(i)
					break

	to_pos = Vector2(
		battle_x_to_screen_x(to_x),
		target_y
	)

	# --- Beam zeichnen ---
	var p: CombatProjectileView = CombatProjectileView.new()
	p.color = Color(1.0, 1.0, 0.2, 1.0) if from_is_fighter else Color(0.5, 0.9, 1.0, 0.95)
	p.width = 2.0 if from_is_fighter else 4.0
	p.projectile_radius = 3.0 if from_is_fighter else 2.0
	p.draw_trail = true
	p.lifetime = 0.22 if from_is_fighter else 0.10

	effects_layer.add_child(p)
	p.setup(from_pos, to_pos)

func _on_torpedo_fired(side: int, from_x: int, to_x: int, hit: bool) -> void:
	var lane_index: int = 0

	if side == CombatTypes.Side.LEFT:
		lane_index = _find_active_torp_lane(engine.state.left)
	else:
		lane_index = _find_active_torp_lane(engine.state.right)

	var from_y: float = _torp_lane_y(side, lane_index)
	var to_y: float = from_y

	var from_pos: Vector2 = Vector2(battle_x_to_screen_x(from_x), from_y)

	var target_battle_x: float = float(to_x)
	var miss_offset_y: float = 0.0

	if not hit:
		if side == CombatTypes.Side.LEFT:
			target_battle_x += 140.0
		else:
			target_battle_x -= 140.0

		miss_offset_y = -36.0 if lane_index % 2 == 0 else 36.0

	var to_pos: Vector2 = Vector2(
		battle_x_to_screen_x_unclamped(target_battle_x),
		to_y + miss_offset_y
	)

	var p: CombatProjectileView = CombatProjectileView.new()
	p.color = Color(1.0, 0.45, 0.15, 1.0) if hit else Color(0.85, 0.85, 0.85, 0.95)
	p.width = 3.0
	p.projectile_radius = 5.0
	p.draw_trail = true
	p.use_constant_speed = true
	p.speed = 900.0
	torpedoes_layer.add_child(p)
	p.setup(from_pos, to_pos)

	if hit:
		var target_side: int = CombatTypes.Side.RIGHT if side == CombatTypes.Side.LEFT else CombatTypes.Side.LEFT
		_queue_torp_hit_projectile(target_side, p)


func _defer_until_projectiles_finish(callback: Callable) -> void:
	var max_wait: float = 0.0
	for child: Node in torpedoes_layer.get_children():
		if child is CombatProjectileView:
			var projectile: CombatProjectileView = child as CombatProjectileView
			max_wait = max(max_wait, projectile.lifetime)

	if max_wait <= 0.0:
		callback.call()
		return

	var timer: SceneTreeTimer = get_tree().create_timer(max_wait + 0.05)
	timer.timeout.connect(callback)


func _queue_torp_hit_projectile(target_side: int, projectile: CombatProjectileView) -> void:
	if not _pending_torp_hit_projectiles.has(target_side):
		_pending_torp_hit_projectiles[target_side] = []
	(_pending_torp_hit_projectiles[target_side] as Array).append(projectile)


func _take_torp_hit_projectile(target_side: int) -> CombatProjectileView:
	if not _pending_torp_hit_projectiles.has(target_side):
		return null
	var projectiles: Array = _pending_torp_hit_projectiles[target_side] as Array
	if projectiles.is_empty():
		return null
	return projectiles.pop_front() as CombatProjectileView


func battle_x_to_screen_x(v: float) -> float:
	return lerpf(_visual_track_left_bound, _visual_track_right_bound, clampf(_battle_x_ratio(v), 0.0, 1.0))


func _update_visual_track_bounds(left_half_w: float, right_half_w: float, viewport_width: float) -> void:
	_visual_track_left_bound = max(BATTLE_LEFT_MARGIN, left_half_w + 6.0)
	_visual_track_right_bound = min(viewport_width - BATTLE_RIGHT_MARGIN, viewport_width - right_half_w - 6.0)
	if _visual_track_right_bound <= _visual_track_left_bound:
		_visual_track_left_bound = viewport_width * 0.25
		_visual_track_right_bound = viewport_width * 0.75


func _battle_x_ratio(v: float) -> float:
	var min_x: float = 30.0
	var max_x: float = 610.0
	if engine != null and engine.state.battle_type != CombatConstants.SHIP_TO_SHIP:
		max_x = 570.0
	return (v - min_x) / max(1.0, max_x - min_x)

func _fighter_lane_y_left(track_id: int) -> float:
	return SHIP_Y - 90.0 + float(track_id % 8) * 16.0

func _fighter_lane_y_right(track_id: int) -> float:
	return SHIP_Y + 90.0 - float(track_id % 8) * 16.0

func _torp_lane_y(side: int, lane_index: int) -> float:
	if side == CombatTypes.Side.LEFT:
		return SHIP_Y - 32.0 + float(lane_index) * 8.0
	return SHIP_Y + 32.0 - float(lane_index) * 8.0

func _find_active_torp_lane(side: CombatState.SideState) -> int:
	var best_index: int = 0
	var best_value: int = 999999

	for i: int in range(side.obj.torp_launcher_count):
		if side.torp_status[i] < best_value:
			best_value = side.torp_status[i]
			best_index = i

	return best_index

func _on_simulate_button_pressed() -> void:
	if _simulation_in_progress:
		return

	_running = false
	_simulation_in_progress = true
	simulation_overlay.visible = true
	_layout_simulation_result_label()
	simulation_result_label.visible = false
	simulation_result_label.text = ""
	simulation_result_label.visible_characters = -1
	simulation_result_label.visible_ratio = 1.0
	simulation_result_label.lines_skipped = 0
	_update_simulation_progress(0, 118)

	var result: Dictionary = await simulator.simulate_all_seeds_async(current_vcr, _on_simulation_progress)
	_simulation_in_progress = false
	_update_simulation_progress(118, 118, "Simulation complete")

	var left_ammo_name: String = "Torps"
	if result["left_uses_fighters"]:
		left_ammo_name = "Fighters"

	var right_ammo_name: String = "Torps"
	if result["right_uses_fighters"]:
		right_ammo_name = "Fighters"

	var total_weight: int = int(result.get("total_weight", result["total_battles"]))

	var left_text: String = ""
	left_text += "LEFT\n"
	left_text += "Destroyed: %.2f%%\n" % result["left_destroyed_percent"]
	left_text += "Captured: %.2f%%\n" % result["left_captured_percent"]
	left_text += "Shield end: %d - %d\n" % [
		result["left_min_end_shield"],
		result["left_max_end_shield"]
	]
	left_text += "%s end: %d - %d\n" % [
		left_ammo_name,
		result["left_min_end_ammo"],
		result["left_max_end_ammo"]
	]

	if result["left_destroyed_count"] < total_weight:
		left_text += "Damage survived: %d - %d\n" % [
			result["left_min_non_destroyed_damage"],
			result["left_max_non_destroyed_damage"]
		]
	else:
		left_text += "Damage destroyed: %d - %d\n" % [
			result["left_min_destroyed_damage"],
			result["left_max_destroyed_damage"]
		]

	var right_text: String = ""
	right_text += "RIGHT\n"
	right_text += "Destroyed: %.2f%%\n" % result["right_destroyed_percent"]
	right_text += "Captured: %.2f%%\n" % result["right_captured_percent"]
	right_text += "Shield end: %d - %d\n" % [
		result["right_min_end_shield"],
		result["right_max_end_shield"]
	]
	right_text += "%s end: %d - %d\n" % [
		right_ammo_name,
		result["right_min_end_ammo"],
		result["right_max_end_ammo"]
	]

	if result["right_destroyed_count"] < total_weight:
		right_text += "Damage survived: %d - %d\n" % [
			result["right_min_non_destroyed_damage"],
			result["right_max_non_destroyed_damage"]
		]
	else:
		right_text += "Damage destroyed: %d - %d\n" % [
			result["right_min_destroyed_damage"],
			result["right_max_destroyed_damage"]
		]

	var middle_text: String = ""
	middle_text += "Seeds: %d\n" % result["total_battles"]
	middle_text += "Both destroyed: %.2f%%\n" % result["both_destroyed_percent"]

	simulation_result_label.text = left_text + "\n" + middle_text + "\n" + right_text
	simulation_result_label.visible = true
	simulation_result_label.queue_redraw()


func _layout_simulation_result_label() -> void:
	_ensure_simulation_progress_ui()
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel: Control = simulation_result_label.get_parent() as Control

	simulation_overlay.position = Vector2.ZERO
	simulation_overlay.size = viewport_size
	var label_size: Vector2 = Vector2(460.0, min(420.0, max(300.0, BATTLE_HEIGHT - 36.0)))
	var label_screen_pos: Vector2 = Vector2(max(24.0, viewport_size.x * 0.5 - 230.0), max(96.0, BATTLE_TOP + 18.0))
	if panel != null:
		panel.position = label_screen_pos - Vector2(12.0, 12.0)
		panel.size = label_size + Vector2(24.0, 70.0)
		panel.clip_contents = false
		if simulation_progress_label != null:
			simulation_progress_label.position = Vector2(12.0, 10.0)
			simulation_progress_label.size = Vector2(label_size.x, 20.0)
		if simulation_progress_bar != null:
			simulation_progress_bar.position = Vector2(12.0, 34.0)
			simulation_progress_bar.size = Vector2(label_size.x, 18.0)
		simulation_result_label.position = Vector2(12.0, 58.0)
	else:
		simulation_result_label.position = label_screen_pos
	simulation_result_label.size = label_size
	simulation_result_label.clip_text = false


func _on_simulation_progress(completed: int, total: int) -> void:
	_update_simulation_progress(completed, total)


func _update_simulation_progress(completed: int, total: int, label_override: String = "") -> void:
	_ensure_simulation_progress_ui()
	if simulation_progress_bar == null or simulation_progress_label == null:
		return

	var safe_total: int = max(1, total)
	simulation_progress_bar.max_value = safe_total
	simulation_progress_bar.value = clamp(completed, 0, safe_total)
	simulation_progress_bar.visible = true
	simulation_progress_label.visible = true
	if label_override != "":
		simulation_progress_label.text = "%s (%d / %d)" % [label_override, completed, safe_total]
	else:
		simulation_progress_label.text = "Simulating seed %d / %d" % [completed, safe_total]

func _build_ship_header(obj: CombatObject) -> String:
	return "%s (ID %d)" % [
		obj.object_name,
		obj.object_id
	]

func _load_turn_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("Turn file not found: ", path)
		return

	var json_text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		print("Invalid JSON root in ", path)
		return

	var root: Dictionary = parsed

	if not root.has("rst"):
		print("No 'rst' key found in turn file: ", path)
		return

	var rst_data: Variant = root.get("rst")
	if typeof(rst_data) != TYPE_DICTIONARY:
		print("'rst' is not a dictionary in ", path)
		return

	var rst: Dictionary = rst_data

	if not rst.has("vcrs"):
		_turn_data = root
		_turn_vcrs.clear()
		print("Turn file has no VCRs: ", path)
		return

	var vcrs_data: Variant = rst.get("vcrs")
	if typeof(vcrs_data) != TYPE_ARRAY:
		_turn_data = root
		_turn_vcrs.clear()
		print("'rst.vcrs' is not an array in ", path)
		return

	_turn_data = root
	_turn_vcrs.clear()

	for entry in vcrs_data:
		if typeof(entry) == TYPE_DICTIONARY:
			_turn_vcrs.append(entry)

	if _turn_vcrs.is_empty():
		print("No valid VCR entries found in rst.vcrs: ", path)
		return

	_current_vcr_index = 0

	print("Loaded VCRs from rst.vcrs: ", _turn_vcrs.size())

func _load_current_vcr() -> void:
	if _turn_vcrs.is_empty():
		return
	simulation_result_label.text = ""
	simulation_result_label.visible = false
	var entry: Dictionary = _turn_vcrs[_current_vcr_index]
	_battle_builder_mode = false
	current_vcr = CombatFactory.create_vcr_from_turn_dict(entry)
	_apply_planet_visual_data_from_turn(entry)
	_reset_battle()
	_update_vcr_index_label()

func _update_vcr_index_label() -> void:
	if _turn_vcrs.is_empty():
		vcr_index_label.text = "Kein Kampf"
		return

	var entry: Dictionary = _turn_vcrs[_current_vcr_index]
	var vcr_id: int = int(entry.get("id", 0))
	vcr_index_label.text = "Kampf %d / %d   (VCR %d)" % [
		_current_vcr_index + 1,
		_turn_vcrs.size(),
		vcr_id
	]

func _on_prev_button_pressed() -> void:
	if _turn_vcrs.is_empty():
		return
	if _current_vcr_index > 0:
		_current_vcr_index -= 1
		_load_current_vcr()

func _on_fighter_intercept_beam(attacker_side: int, attacker_index: int, target_index: int) -> void:
	var from_x: float
	var to_x: float

	if attacker_side == CombatTypes.Side.LEFT:
		from_x = engine.state.left.fighter_x[attacker_index]
		to_x = engine.state.right.fighter_x[target_index]
	else:
		from_x = engine.state.right.fighter_x[attacker_index]
		to_x = engine.state.left.fighter_x[target_index]

	_on_beam_fired(attacker_side, from_x, to_x, true, attacker_index)

func _on_next_button_pressed() -> void:
	if _turn_vcrs.is_empty():
		return
	if _current_vcr_index + 1 < _turn_vcrs.size():
		_current_vcr_index += 1
		_load_current_vcr()

func _on_close_app_button_pressed() -> void:
	get_tree().quit()

func _ensure_battle_builder_ui() -> void:
	if battle_setup_overlay != null:
		return

	battle_sim_button = Button.new()
	battle_sim_button.name = "BattleSimButton"
	battle_sim_button.text = "Battle Simulator"
	_style_battle_sim_button(battle_sim_button)
	buttons_bar.add_child(battle_sim_button)

	var ui_layer: CanvasLayer = $UI
	battle_setup_overlay = Control.new()
	battle_setup_overlay.name = "BattleSetupOverlay"
	battle_setup_overlay.visible = false
	battle_setup_overlay.z_index = 40
	ui_layer.add_child(battle_setup_overlay)

	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	battle_setup_overlay.add_child(dim)

	battle_setup_panel = Panel.new()
	battle_setup_panel.name = "Panel"
	battle_setup_overlay.add_child(battle_setup_panel)

	var title: Label = _builder_add_label(battle_setup_panel, "Battle Simulator", Vector2(24.0, 14.0), Vector2(420.0, 24.0))
	title.add_theme_font_size_override("font_size", 18)

	_create_side_builder(battle_setup_panel, "left", "Left combatant", 28.0, false)
	_create_side_builder(battle_setup_panel, "right", "Right combatant", 590.0, true)

	var builder_button_y: float = 670.0

	var apply_button: Button = Button.new()
	apply_button.name = "ApplyButton"
	apply_button.text = "Start Simulation"
	apply_button.position = Vector2(760.0, builder_button_y)
	apply_button.size = Vector2(150.0, 30.0)
	_style_start_simulation_button(apply_button)
	battle_setup_panel.add_child(apply_button)
	apply_button.pressed.connect(_on_builder_apply_pressed)

	var swap_button: Button = Button.new()
	swap_button.name = "SwapSidesButton"
	swap_button.text = "Swap sides"
	swap_button.position = Vector2(620.0, builder_button_y)
	swap_button.size = Vector2(130.0, 30.0)
	battle_setup_panel.add_child(swap_button)
	swap_button.pressed.connect(_on_builder_swap_sides_pressed)

	var close_button: Button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.position = Vector2(900.0, builder_button_y)
	close_button.size = Vector2(80.0, 30.0)
	battle_setup_panel.add_child(close_button)
	close_button.pressed.connect(func() -> void:
		battle_setup_overlay.visible = false
	)

	_populate_builder_defaults()


func _style_battle_sim_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.42, 0.95, 1.0)
	normal.border_color = Color(0.62, 0.84, 1.0, 1.0)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 12.0
	normal.content_margin_right = 12.0

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.55, 1.0, 1.0)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.05, 0.30, 0.78, 1.0)

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.18, 0.22, 0.30, 1.0)
	disabled.border_color = Color(0.35, 0.40, 0.48, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.78, 0.86, 1.0))
	button.add_theme_font_size_override("font_size", 16)


func _style_start_simulation_button(button: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.55, 0.25, 1.0)
	normal.border_color = Color(0.42, 1.0, 0.62, 1.0)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_left = 5
	normal.corner_radius_bottom_right = 5
	normal.content_margin_left = 10.0
	normal.content_margin_right = 10.0

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.10, 0.68, 0.32, 1.0)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.05, 0.38, 0.18, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.96, 1.0, 0.96, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 14)


func _layout_battle_builder_ui() -> void:
	if battle_setup_overlay == null:
		return

	var size: Vector2 = get_viewport_rect().size
	battle_setup_overlay.position = Vector2.ZERO
	battle_setup_overlay.size = size

	var dim: ColorRect = battle_setup_overlay.get_node("Dim") as ColorRect
	dim.position = Vector2.ZERO
	dim.size = size

	battle_setup_panel.size = Vector2(1120.0, 740.0)
	battle_setup_panel.position = Vector2(
		max(20.0, (size.x - battle_setup_panel.size.x) * 0.5),
		max(78.0, (size.y - battle_setup_panel.size.y) * 0.5)
	)


func _create_side_builder(parent: Control, side_key: String, title: String, x: float, allow_planet: bool) -> void:
	var controls: Dictionary = {}
	_builder_controls[side_key] = controls

	var header: Label = _builder_add_label(parent, title, Vector2(x, 46.0), Vector2(430.0, 22.0))
	header.add_theme_font_size_override("font_size", 15)

	var y: float = 78.0
	if allow_planet:
		var planet_check: CheckBox = CheckBox.new()
		planet_check.text = "Planet / Starbase"
		planet_check.position = Vector2(x + 118.0, y - 2.0)
		planet_check.size = Vector2(220.0, 26.0)
		_style_builder_checkbox(planet_check)
		parent.add_child(planet_check)
		controls["is_planet"] = planet_check
		planet_check.toggled.connect(_on_builder_planet_toggled.bind(side_key))
		y += 30.0

	_add_builder_spin_row(parent, controls, "object_id", "Object ID", x, y, 1.0, 999999.0, 1.0, 0.0)
	y += 30.0
	var name_edit: LineEdit = _add_builder_line_row(parent, controls, "name", "Name", x, y)
	name_edit.editable = false
	name_edit.focus_mode = Control.FOCUS_NONE
	_set_builder_row_visible(controls, "name", false)
	_add_builder_spin_row(parent, controls, "owner", "Owner", x, y, 1.0, 999.0, 1.0, 1.0)
	_set_builder_row_visible(controls, "owner", false)

	var race_option: OptionButton = _add_builder_option_row(parent, controls, "race", "Race", x, y)
	_fill_race_option(race_option)
	race_option.item_selected.connect(_on_builder_race_selected.bind(side_key))
	y += 30.0

	var hull_option: OptionButton = _add_builder_option_row(parent, controls, "hull", "Hull", x, y)
	_fill_hull_option(hull_option, _option_id(controls, "race"))
	hull_option.item_selected.connect(_on_builder_hull_selected.bind(side_key))
	y += 34.0

	var engine_option: OptionButton = _add_builder_option_row(parent, controls, "engine_type", "Engines", x, y)
	_fill_data_option(engine_option, ShipData.engines, "No engine", false)
	y += 30.0

	_add_builder_spin_row(parent, controls, "ssg_count", "SSG Support", x, y, 0.0, 2.0, 1.0, 0.0)
	y += 30.0
	var red_wind_check: CheckBox = CheckBox.new()
	red_wind_check.text = "cloaked Red Wind"
	red_wind_check.position = Vector2(x + 118.0, y - 2.0)
	red_wind_check.size = Vector2(190.0, 26.0)
	_style_builder_checkbox(red_wind_check)
	parent.add_child(red_wind_check)
	controls["red_wind_support"] = red_wind_check
	red_wind_check.toggled.connect(_on_builder_red_wind_toggled.bind(side_key))

	var red_wind_fighters_label: Label = _builder_add_label(parent, "Fighters", Vector2(x + 316.0, y + 3.0), Vector2(58.0, 22.0))
	var red_wind_fighters_spin: SpinBox = SpinBox.new()
	red_wind_fighters_spin.min_value = 0.0
	red_wind_fighters_spin.max_value = 60.0
	red_wind_fighters_spin.step = 1.0
	red_wind_fighters_spin.value = 60.0
	red_wind_fighters_spin.position = Vector2(x + 374.0, y)
	red_wind_fighters_spin.size = Vector2(86.0, 26.0)
	red_wind_fighters_spin.select_all_on_focus = true
	parent.add_child(red_wind_fighters_spin)
	controls["red_wind_fighters_label"] = red_wind_fighters_label
	controls["red_wind_fighters"] = red_wind_fighters_spin
	y += 30.0

	_add_builder_spin_row(parent, controls, "mass", "Combat mass", x, y, 1.0, 9999.0, 1.0, 100.0)
	y += 30.0
	_add_builder_spin_row(parent, controls, "shield", "Shield", x, y, 0.0, 100.0, 1.0, 100.0)
	y += 30.0
	var damage_spin: SpinBox = _add_builder_spin_row(parent, controls, "damage", "Damage", x, y, 0.0, 999.0, 1.0, 0.0)
	damage_spin.value_changed.connect(_on_builder_damage_changed.bind(side_key))
	y += 30.0
	_add_builder_spin_row(parent, controls, "crew", "Crew", x, y, 0.0, 99999.0, 1.0, 0.0)
	y += 34.0

	var beam_option: OptionButton = _add_builder_option_row(parent, controls, "beam_type", "Beam", x, y)
	_fill_data_option(beam_option, ShipData.beams, "No beam", true)
	beam_option.item_selected.connect(_on_builder_weapon_selected.bind(side_key))
	y += 30.0
	var beam_count_spin: SpinBox = _add_builder_spin_row(parent, controls, "beam_count", "Beam count", x, y, 0.0, 10.0, 1.0, 0.0)
	beam_count_spin.value_changed.connect(_on_builder_weapon_count_changed.bind(side_key))
	var fast_beams_check: CheckBox = CheckBox.new()
	fast_beams_check.text = "fast"
	fast_beams_check.position = Vector2(x + 250.0, y - 2.0)
	fast_beams_check.size = Vector2(90.0, 26.0)
	parent.add_child(fast_beams_check)
	controls["fast_beams"] = fast_beams_check
	y += 34.0

	var torp_option: OptionButton = _add_builder_option_row(parent, controls, "torp_type", "Torpedo", x, y)
	_fill_data_option(torp_option, ShipData.torps, "No torpedo", true)
	torp_option.item_selected.connect(_on_builder_weapon_selected.bind(side_key))
	y += 30.0
	var torp_count_spin: SpinBox = _add_builder_spin_row(parent, controls, "torp_count", "Tubes", x, y, 0.0, 10.0, 1.0, 0.0)
	torp_count_spin.value_changed.connect(_on_builder_weapon_count_changed.bind(side_key))
	y += 30.0
	var bay_count_spin: SpinBox = _add_builder_spin_row(parent, controls, "bay_count", "Bays", x, y, 0.0, 10.0, 1.0, 0.0)
	bay_count_spin.value_changed.connect(_on_builder_weapon_count_changed.bind(side_key))
	y += 30.0
	_add_builder_spin_row(parent, controls, "ammo", "Ammo", x, y, 0.0, 9999.0, 1.0, 0.0)
	y += 34.0

	if allow_planet:
		var starbase_check: CheckBox = CheckBox.new()
		starbase_check.text = "Starbase visible"
		starbase_check.position = Vector2(x + 118.0, y - 2.0)
		starbase_check.size = Vector2(200.0, 26.0)
		_style_builder_checkbox(starbase_check)
		parent.add_child(starbase_check)
		controls["starbase"] = starbase_check
		starbase_check.toggled.connect(_on_builder_starbase_toggled.bind(side_key))
		y += 30.0

		var starbase_type_option: OptionButton = _add_builder_option_row(parent, controls, "starbase_type", "Base Type", x, y)
		_fill_starbase_type_option(starbase_type_option)
		starbase_type_option.item_selected.connect(_on_builder_starbase_type_selected.bind(side_key))
		y += 30.0
		_add_builder_spin_row(parent, controls, "starbase_style", "Base style", x, y, 1.0, 9.0, 1.0, 1.0)
		y += 30.0
		_add_builder_spin_row(parent, controls, "planet_defense_posts", "Planet Defense", x, y, 0.0, 200.0, 1.0, 0.0)
		y += 30.0
		_add_builder_spin_row(parent, controls, "starbase_defense_posts", "Base Defense", x, y, 0.0, 200.0, 1.0, 0.0)
		y += 30.0
		_add_builder_spin_row(parent, controls, "starbase_fighters", "Fighters", x, y, 0.0, 9999.0, 1.0, 0.0)
		y += 30.0
		_add_builder_spin_row(parent, controls, "starbase_beam_tech", "Beam Tech", x, y, 1.0, 10.0, 1.0, 10.0)


func _builder_add_label(parent: Control, text: String, label_position: Vector2, label_size: Vector2) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = label_position
	label.size = label_size
	parent.add_child(label)
	return label


func _add_builder_line_row(parent: Control, controls: Dictionary, key: String, label_text: String, x: float, y: float) -> LineEdit:
	var label: Label = _builder_add_label(parent, label_text, Vector2(x, y + 3.0), Vector2(112.0, 22.0))
	var edit: LineEdit = LineEdit.new()
	edit.position = Vector2(x + 118.0, y)
	edit.size = Vector2(365.0, 26.0)
	parent.add_child(edit)
	controls[key + "_label"] = label
	controls[key] = edit
	return edit


func _add_builder_spin_row(parent: Control, controls: Dictionary, key: String, label_text: String, x: float, y: float, min_value: float, max_value: float, step: float, value: float) -> SpinBox:
	var label: Label = _builder_add_label(parent, label_text, Vector2(x, y + 3.0), Vector2(112.0, 22.0))
	var spin: SpinBox = SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.value = value
	spin.position = Vector2(x + 118.0, y)
	spin.size = Vector2(120.0, 26.0)
	spin.select_all_on_focus = true
	parent.add_child(spin)
	controls[key + "_label"] = label
	controls[key] = spin
	return spin


func _add_builder_option_row(parent: Control, controls: Dictionary, key: String, label_text: String, x: float, y: float) -> OptionButton:
	var label: Label = _builder_add_label(parent, label_text, Vector2(x, y + 3.0), Vector2(112.0, 22.0))
	var option: OptionButton = OptionButton.new()
	option.position = Vector2(x + 118.0, y)
	option.size = Vector2(365.0, 28.0)
	parent.add_child(option)
	controls[key + "_label"] = label
	controls[key] = option
	return option


func _fill_race_option(option: OptionButton) -> void:
	option.clear()
	for race_id: int in range(1, 13):
		option.add_item("%d - %s" % [race_id, _get_race_short(race_id)], race_id)
	_select_option_by_id(option, 1)


func _fill_starbase_type_option(option: OptionButton) -> void:
	option.clear()
	option.add_item("Normal Starbase", 0)
	option.add_item("Shielded Starbase", 1)
	option.add_item("Mining Station", 2)
	option.select(0)


func _fill_data_option(option: OptionButton, source: Dictionary, empty_label: String, include_empty: bool) -> void:
	option.clear()
	if include_empty:
		option.add_item(empty_label, 0)

	var ids: Array[int] = []
	for key in source.keys():
		ids.append(int(key))
	ids.sort()

	for id: int in ids:
		var entry: Dictionary = source.get(id, {})
		option.add_item(String(entry.get("name", "Unknown")), id)

	if option.get_item_count() > 0:
		option.select(0)


func _fill_hull_option(option: OptionButton, race_id: int, preferred_hull_id: int = 0) -> void:
	option.clear()

	var ids: Array[int] = []
	for key in ShipData.hulls.keys():
		var hull_id: int = int(key)
		if _is_hull_allowed_for_race(hull_id, race_id):
			ids.append(hull_id)
	ids.sort()

	for id: int in ids:
		var entry: Dictionary = ShipData.hulls.get(id, {})
		option.add_item(String(entry.get("name", "Unknown Hull")), id)

	if preferred_hull_id > 0 and _is_hull_allowed_for_race(preferred_hull_id, race_id):
		_select_option_by_id(option, preferred_hull_id)
	elif option.get_item_count() > 0:
		option.select(0)


func _is_hull_allowed_for_race(hull_id: int, race_id: int) -> bool:
	if _is_excluded_builder_hull(hull_id):
		return false

	var is_horwasp_hull: bool = _is_horwasp_hull(hull_id)
	if race_id == 12:
		return is_horwasp_hull
	return not is_horwasp_hull


func _is_excluded_builder_hull(hull_id: int) -> bool:
	if hull_id in [119, 171, 172, 173, 180, 181, 200, 212]:
		return true

	var hull: Dictionary = ShipData.get_hull(hull_id)
	var hull_name: String = String(hull.get("name", "")).to_lower()
	return hull_name == "galactic trade station" \
		or hull_name == "trade station" \
		or hull_name.begins_with("babu ")


func _is_horwasp_hull(hull_id: int) -> bool:
	if hull_id in [115, 116, 117, 118, 119, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215]:
		return true

	var hull: Dictionary = ShipData.get_hull(hull_id)
	var hull_name: String = String(hull.get("name", "")).to_lower()
	return hull_name in [
		"hive",
		"soldier",
		"brood",
		"jacker",
		"protofield",
		"stinger",
		"accelerator",
		"armoured nest",
		"nest",
		"farm",
		"sentry",
		"dunghill",
		"duranium rock",
		"tritanium rock",
		"molybdenum rock"
	]


func _select_option_by_id(option: OptionButton, id: int) -> void:
	for index: int in range(option.get_item_count()):
		if option.get_item_id(index) == id:
			option.select(index)
			return
	if option.get_item_count() > 0:
		option.select(0)


func _select_last_nonzero_option(option: OptionButton) -> void:
	for index: int in range(option.get_item_count() - 1, -1, -1):
		if option.get_item_id(index) > 0:
			option.select(index)
			return
	_select_option_by_id(option, 0)


func _option_id(controls: Dictionary, key: String) -> int:
	var option: OptionButton = controls[key] as OptionButton
	return option.get_selected_id()


func _spin_value(controls: Dictionary, key: String) -> int:
	var spin: SpinBox = controls[key] as SpinBox
	return int(spin.value)


func _set_spin_max_value(controls: Dictionary, key: String, max_value: int) -> void:
	var spin: SpinBox = controls[key] as SpinBox
	spin.max_value = max_value
	if spin.value > max_value:
		spin.value = max_value


func _set_builder_label_text(controls: Dictionary, key: String, text: String) -> void:
	if controls.has(key + "_label"):
		(controls[key + "_label"] as Label).text = text


func _line_text(controls: Dictionary, key: String) -> String:
	var edit: LineEdit = controls[key] as LineEdit
	return edit.text.strip_edges()


func _populate_builder_defaults() -> void:
	_set_side_to_first_available_hull("left")
	_set_side_to_first_available_hull("right")

	var left: Dictionary = _builder_controls["left"]
	var right: Dictionary = _builder_controls["right"]
	(left["name"] as LineEdit).text = "Left Ship"
	(right["name"] as LineEdit).text = "Right Ship"
	_select_option_by_id(left["race"] as OptionButton, 1)
	_select_option_by_id(right["race"] as OptionButton, 2)
	(left["owner"] as SpinBox).value = _option_id(left, "race")
	(right["owner"] as SpinBox).value = _option_id(right, "race")
	_update_builder_fast_beams_default(left)
	_update_builder_fast_beams_default(right)
	_fill_hull_option(left["hull"] as OptionButton, 1)
	_fill_hull_option(right["hull"] as OptionButton, 2)
	_update_builder_hull_defaults("left", true)
	_update_builder_hull_defaults("right", true)
	_on_builder_planet_toggled(false, "right")


func _set_side_to_first_available_hull(side_key: String) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	var hull_option: OptionButton = controls["hull"] as OptionButton
	if hull_option.get_item_count() > 0:
		hull_option.select(0)


func _on_battle_sim_button_pressed() -> void:
	if _battle_builder_mode:
		_populate_builder_from_current_vcr()
	else:
		_populate_builder_defaults()
	_layout_battle_builder_ui()
	battle_setup_overlay.visible = true


func _populate_builder_from_current_vcr() -> void:
	if current_vcr == null:
		_populate_builder_defaults()
		return

	_populate_side_builder_from_object("left", current_vcr.left)
	_populate_side_builder_from_object("right", current_vcr.right)


func _populate_side_builder_from_object(side_key: String, obj: CombatObject) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	var object_name: String = _builder_display_name_for_object(obj)

	if controls.has("is_planet"):
		(controls["is_planet"] as CheckBox).button_pressed = obj.is_planet
		_on_builder_planet_toggled(obj.is_planet, side_key)

	(controls["object_id"] as SpinBox).value = obj.object_id
	(controls["name"] as LineEdit).text = object_name
	_select_option_by_id(controls["race"] as OptionButton, max(1, obj.race_id))
	(controls["owner"] as SpinBox).value = _option_id(controls, "race")
	_fill_hull_option(controls["hull"] as OptionButton, max(1, obj.race_id), obj.hull_id)
	_select_option_by_id(controls["hull"] as OptionButton, obj.hull_id)
	_select_option_by_id(controls["engine_type"] as OptionButton, 9)
	(controls["ssg_count"] as SpinBox).value = 0
	if controls.has("red_wind_support"):
		(controls["red_wind_support"] as CheckBox).button_pressed = false
	if controls.has("red_wind_fighters"):
		(controls["red_wind_fighters"] as SpinBox).value = _red_wind_max_fighters()
	(controls["mass"] as SpinBox).value = max(1, obj.mass)
	(controls["shield"] as SpinBox).value = clamp(obj.shield, 0, 100)
	(controls["damage"] as SpinBox).value = max(0, obj.damage)
	(controls["crew"] as SpinBox).value = max(0, obj.crew)
	_select_option_by_id(controls["beam_type"] as OptionButton, obj.beam_type)
	(controls["beam_count"] as SpinBox).value = clamp(obj.beam_count, 0, 10)
	_select_option_by_id(controls["torp_type"] as OptionButton, obj.torp_type)
	(controls["torp_count"] as SpinBox).value = clamp(obj.torp_launcher_count, 0, 10)
	(controls["bay_count"] as SpinBox).value = clamp(obj.bay_count, 0, 10)
	if _is_horwasp_hull(obj.hull_id):
		(controls["ammo"] as SpinBox).value = _estimate_horwasp_clans_from_object(obj)
	else:
		(controls["ammo"] as SpinBox).value = obj.fighter_count if obj.bay_count > 0 else obj.torp_count

	if controls.has("starbase"):
		(controls["starbase"] as CheckBox).button_pressed = obj.has_starbase
	if controls.has("starbase_type"):
		_select_option_by_id(controls["starbase_type"] as OptionButton, 0)
	if controls.has("starbase_style"):
		(controls["starbase_style"] as SpinBox).value = max(1, obj.starbase_style)
	if controls.has("planet_defense_posts"):
		(controls["planet_defense_posts"] as SpinBox).value = max(0, obj.mass - 100) if obj.is_planet else 0
	if controls.has("starbase_defense_posts"):
		(controls["starbase_defense_posts"] as SpinBox).value = 0
	if controls.has("starbase_fighters"):
		(controls["starbase_fighters"] as SpinBox).value = obj.fighter_count if obj.is_planet else 0
	if controls.has("starbase_beam_tech"):
		(controls["starbase_beam_tech"] as SpinBox).value = clamp(obj.beam_type, 1, 10) if obj.is_planet and obj.beam_type > 0 else 10
	if controls.has("fast_beams"):
		(controls["fast_beams"] as CheckBox).button_pressed = obj.beam_charge_rate > 1 or obj.race_id == 4
	if obj.is_planet:
		_update_builder_starbase_fields(side_key)

	if not obj.is_planet:
		_update_builder_hull_defaults(side_key, false)
		(controls["name"] as LineEdit).text = object_name


func _estimate_horwasp_clans_from_object(obj: CombatObject) -> int:
	var hull: Dictionary = ShipData.get_hull(obj.hull_id)
	var cargo: int = int(hull.get("cargo", 0))
	var hull_mass: int = max(1, int(hull.get("mass", obj.mass)))
	if cargo <= 0:
		return 0

	var ratio: float = clampf((float(obj.mass) - float(hull_mass)) / float(hull_mass), 0.0, 1.0)
	return int(round(ratio * float(cargo)))


func _builder_display_name_for_object(obj: CombatObject) -> String:
	if obj.is_planet:
		return "Planet"
	var hull: Dictionary = ShipData.get_hull(obj.hull_id)
	if not hull.is_empty():
		return String(hull.get("name", "Ship"))
	return "Ship"


func _sync_builder_name_to_hull(side_key: String) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	var is_planet: bool = controls.has("is_planet") and (controls["is_planet"] as CheckBox).button_pressed
	if is_planet:
		(controls["name"] as LineEdit).text = "Planet"
		return

	var hull: Dictionary = ShipData.get_hull(_option_id(controls, "hull"))
	(controls["name"] as LineEdit).text = String(hull.get("name", "Ship"))


func _on_builder_planet_toggled(enabled: bool, side_key: String) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	_set_builder_row_visible(controls, "hull", not enabled)
	_set_builder_row_visible(controls, "engine_type", not enabled)
	_set_builder_row_visible(controls, "ssg_count", not enabled)
	_set_builder_row_visible(controls, "mass", not enabled)
	_set_builder_row_visible(controls, "shield", not enabled)
	_set_builder_row_visible(controls, "damage", not enabled)
	_set_builder_row_visible(controls, "crew", not enabled)

	if controls.has("starbase"):
		(controls["starbase"] as Control).visible = enabled
	if controls.has("fast_beams"):
		(controls["fast_beams"] as Control).visible = false

	if enabled:
		(controls["name"] as LineEdit).text = "Planet"
		(controls["shield"] as SpinBox).value = 0
		(controls["damage"] as SpinBox).value = 0
		(controls["crew"] as SpinBox).value = 10000
		(controls["mass"] as SpinBox).value = 100
		_apply_builder_weapon_visibility(controls, false, false, false)
		_update_builder_starbase_fields(side_key)
	else:
		if controls.has("starbase"):
			(controls["starbase"] as CheckBox).button_pressed = false
		_update_builder_starbase_fields(side_key)
		_update_builder_hull_defaults(side_key, false)
		_sync_builder_name_to_hull(side_key)


func _set_builder_enabled(control: Variant, enabled: bool) -> void:
	if control is BaseButton:
		(control as BaseButton).disabled = not enabled
	elif control is LineEdit:
		(control as LineEdit).editable = enabled
	elif control is SpinBox:
		(control as SpinBox).editable = enabled


func _on_builder_starbase_toggled(_enabled: bool, side_key: String) -> void:
	_update_builder_starbase_fields(side_key)


func _update_builder_starbase_fields(side_key: String) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	var is_planet: bool = controls.has("is_planet") and (controls["is_planet"] as CheckBox).button_pressed
	var has_starbase: bool = is_planet and controls.has("starbase") and (controls["starbase"] as CheckBox).button_pressed

	if is_planet:
		_layout_builder_starbase_rows(controls)

	_set_builder_row_visible(controls, "starbase_type", has_starbase)
	_set_builder_row_visible(controls, "starbase_style", has_starbase)
	_set_builder_row_visible(controls, "planet_defense_posts", is_planet)
	_set_builder_row_visible(controls, "starbase_defense_posts", has_starbase)
	_set_builder_row_visible(controls, "starbase_fighters", has_starbase)
	_set_builder_row_visible(controls, "starbase_beam_tech", has_starbase)
	if controls.has("fast_beams"):
		var is_fury: bool = _option_id(controls, "race") == 4
		(controls["fast_beams"] as Control).visible = is_planet and is_fury
	if has_starbase:
		_apply_starbase_type_limits(controls)
	elif is_planet:
		_set_spin_max_value(controls, "planet_defense_posts", 200)


func _layout_builder_starbase_rows(controls: Dictionary) -> void:
	if controls.has("starbase") and controls.has("hull"):
		var hull_control: Control = controls["hull"] as Control
		var starbase_check: CheckBox = controls["starbase"] as CheckBox
		starbase_check.position = Vector2(hull_control.position.x, hull_control.position.y - 2.0)

	_move_builder_row_to_match(controls, "starbase_type", "mass")
	_move_builder_row_to_match(controls, "planet_defense_posts", "shield")
	_move_builder_row_to_match(controls, "starbase_defense_posts", "damage")
	_move_builder_row_to_match(controls, "starbase_fighters", "crew")
	_move_builder_row_to_match(controls, "starbase_beam_tech", "torp_type")
	_move_builder_row_to_match(controls, "starbase_style", "beam_type")
	if controls.has("fast_beams"):
		var fast_check: Control = controls["fast_beams"] as Control
		var anchor_control: Control = controls["starbase_beam_tech"] as Control if (controls.has("starbase_beam_tech") and (controls["starbase_beam_tech"] as Control).visible) else controls["planet_defense_posts"] as Control
		fast_check.position = Vector2(anchor_control.position.x + 132.0, anchor_control.position.y - 2.0)


func _move_builder_row_to_match(controls: Dictionary, source_key: String, target_key: String) -> void:
	if not controls.has(source_key) or not controls.has(target_key):
		return

	var source_control: Control = controls[source_key] as Control
	var target_control: Control = controls[target_key] as Control
	source_control.position = target_control.position

	if controls.has(source_key + "_label") and controls.has(target_key + "_label"):
		var source_label: Control = controls[source_key + "_label"] as Control
		var target_label: Control = controls[target_key + "_label"] as Control
		source_label.position = target_label.position


func _on_builder_starbase_type_selected(_index: int, side_key: String) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	_apply_starbase_type_limits(controls)


func _apply_starbase_type_limits(controls: Dictionary) -> void:
	var starbase_type: int = _option_id(controls, "starbase_type")
	_set_spin_max_value(controls, "starbase_defense_posts", _starbase_max_defense(starbase_type))
	_set_spin_max_value(controls, "starbase_fighters", _starbase_max_fighters(starbase_type))


func _starbase_max_defense(starbase_type: int) -> int:
	match starbase_type:
		1: return 250
		2: return 50
		_: return 200


func _starbase_max_fighters(starbase_type: int) -> int:
	match starbase_type:
		1: return 80
		2: return 20
		_: return 60


func _starbase_mass_bonus(starbase_type: int) -> int:
	return 200 if starbase_type == 1 else 0


func _on_builder_hull_selected(_index: int, side_key: String) -> void:
	_update_builder_hull_defaults(side_key, true)


func _on_builder_race_selected(_index: int, side_key: String) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	var race_id: int = _option_id(controls, "race")
	(controls["owner"] as SpinBox).value = race_id
	var previous_hull_id: int = _option_id(controls, "hull")
	_update_builder_fast_beams_default(controls)
	if controls.has("is_planet") and (controls["is_planet"] as CheckBox).button_pressed:
		_update_builder_starbase_fields(side_key)
		return
	_fill_hull_option(controls["hull"] as OptionButton, race_id, previous_hull_id)
	_update_builder_hull_defaults(side_key, true)


func _on_builder_owner_changed(value: float, side_key: String) -> void:
	var owner_id: int = int(value)
	if owner_id < 1 or owner_id > 12:
		return

	var controls: Dictionary = _builder_controls[side_key]
	_select_option_by_id(controls["race"] as OptionButton, owner_id)
	_on_builder_race_selected(0, side_key)


func _on_builder_damage_changed(_value: float, side_key: String) -> void:
	_update_builder_hull_defaults(side_key, false)


func _on_builder_weapon_selected(_index: int, side_key: String) -> void:
	_update_builder_shield_rule(side_key)


func _on_builder_weapon_count_changed(_value: float, side_key: String) -> void:
	_update_builder_shield_rule(side_key)


func _on_builder_red_wind_toggled(_enabled: bool, side_key: String) -> void:
	_update_builder_hull_defaults(side_key, false)


func _update_builder_hull_defaults(side_key: String, overwrite_values: bool) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	if controls.has("is_planet") and (controls["is_planet"] as CheckBox).button_pressed:
		_apply_builder_weapon_visibility(controls, false, false, false)
		_set_builder_row_visible(controls, "red_wind_support", false)
		_set_builder_row_visible(controls, "red_wind_fighters", false)
		_set_builder_enabled(controls["shield"], true)
		_update_builder_starbase_fields(side_key)
		return

	var hull_id: int = _option_id(controls, "hull")
	var hull: Dictionary = ShipData.get_hull(hull_id)
	if hull.is_empty():
		return

	var max_beams: int = int(hull.get("beams", 0))
	var max_tubes: int = int(hull.get("launchers", 0))
	var max_bays: int = int(hull.get("bays", 0))
	var cargo_capacity: int = int(hull.get("cargo", 0))
	var is_horwasp: bool = _is_horwasp_hull(hull_id)
	var damage_weapon_limit: int = _builder_damage_weapon_limit(controls)
	var available_beams: int = min(max_beams, damage_weapon_limit)
	var available_tubes: int = min(max_tubes, damage_weapon_limit)
	var available_bays: int = min(max_bays, damage_weapon_limit)
	var can_have_shields: bool = available_beams > 0 or ShipData.keeps_shields_without_beams(hull_id)

	_set_spin_max_value(controls, "beam_count", available_beams)
	_set_spin_max_value(controls, "torp_count", available_tubes)
	_set_spin_max_value(controls, "bay_count", available_bays)
	_set_spin_max_value(controls, "ammo", max(0, cargo_capacity))
	_set_spin_max_value(controls, "red_wind_fighters", _red_wind_max_fighters())
	_set_builder_label_text(controls, "ammo", "Clans" if is_horwasp else "Ammo")

	if is_horwasp:
		_apply_builder_horwasp_visibility(controls)
	else:
		_set_builder_row_visible(controls, "engine_type", true)
		_set_builder_row_visible(controls, "ssg_count", true)
		_set_builder_row_visible(controls, "red_wind_support", available_bays > 0)
		_set_builder_row_visible(controls, "red_wind_fighters", available_bays > 0 and (controls["red_wind_support"] as CheckBox).button_pressed)
		_set_builder_row_visible(controls, "mass", true)
		_set_builder_row_visible(controls, "shield", true)
		_set_builder_row_visible(controls, "damage", true)
		_set_builder_row_visible(controls, "crew", true)
		_apply_builder_weapon_visibility(controls, available_beams > 0, available_tubes > 0, available_bays > 0)
		if controls.has("fast_beams"):
			(controls["fast_beams"] as Control).visible = _option_id(controls, "race") == 4 and available_beams > 0

	if overwrite_values:
		var race_id: int = _option_id(controls, "race")
		var mass: int = int(hull.get("mass", 0))
		if race_id == 1:
			mass += 50

		(controls["name"] as LineEdit).text = String(hull.get("name", "Ship"))
		_select_option_by_id(controls["engine_type"] as OptionButton, 9)
		if controls.has("red_wind_support"):
			(controls["red_wind_support"] as CheckBox).button_pressed = false
		if controls.has("red_wind_fighters"):
			(controls["red_wind_fighters"] as SpinBox).value = _red_wind_max_fighters()
		(controls["mass"] as SpinBox).value = max(1, mass)
		(controls["crew"] as SpinBox).value = max(1, int(hull.get("crew", 0)))
		(controls["shield"] as SpinBox).value = 100 if can_have_shields else 0
		(controls["beam_count"] as SpinBox).value = available_beams
		(controls["torp_count"] as SpinBox).value = available_tubes
		(controls["bay_count"] as SpinBox).value = available_bays
		if is_horwasp:
			(controls["ammo"] as SpinBox).value = cargo_capacity
		else:
			if available_bays > 0:
				(controls["ammo"] as SpinBox).value = min(cargo_capacity, 60)
			elif available_tubes > 0:
				(controls["ammo"] as SpinBox).value = min(cargo_capacity, 20)
			else:
				(controls["ammo"] as SpinBox).value = 0
		if available_beams > 0:
			_select_last_nonzero_option(controls["beam_type"] as OptionButton)
		else:
			_select_option_by_id(controls["beam_type"] as OptionButton, 0)
		if available_tubes > 0:
			_select_last_nonzero_option(controls["torp_type"] as OptionButton)
		else:
			_select_option_by_id(controls["torp_type"] as OptionButton, 0)
	else:
		(controls["beam_count"] as SpinBox).value = min((controls["beam_count"] as SpinBox).value, available_beams)
		(controls["torp_count"] as SpinBox).value = min((controls["torp_count"] as SpinBox).value, available_tubes)
		(controls["bay_count"] as SpinBox).value = min((controls["bay_count"] as SpinBox).value, available_bays)
		(controls["ammo"] as SpinBox).value = min((controls["ammo"] as SpinBox).value, cargo_capacity)

	_update_builder_shield_rule(side_key)


func _update_builder_fast_beams_default(controls: Dictionary) -> void:
	if controls.has("fast_beams"):
		(controls["fast_beams"] as CheckBox).button_pressed = _option_id(controls, "race") == 4


func _apply_builder_horwasp_visibility(controls: Dictionary) -> void:
	_set_builder_row_visible(controls, "engine_type", false)
	_set_builder_row_visible(controls, "ssg_count", false)
	_set_builder_row_visible(controls, "red_wind_support", false)
	_set_builder_row_visible(controls, "red_wind_fighters", false)
	_set_builder_row_visible(controls, "mass", false)
	_set_builder_row_visible(controls, "shield", false)
	_set_builder_row_visible(controls, "damage", false)
	_set_builder_row_visible(controls, "crew", false)
	_set_builder_row_visible(controls, "beam_type", false)
	_set_builder_row_visible(controls, "beam_count", false)
	_set_builder_row_visible(controls, "torp_type", false)
	_set_builder_row_visible(controls, "torp_count", false)
	_set_builder_row_visible(controls, "bay_count", false)
	_set_builder_row_visible(controls, "ammo", true)
	if controls.has("fast_beams"):
		(controls["fast_beams"] as Control).visible = false


func _builder_damage_weapon_limit(controls: Dictionary) -> int:
	var damage: int = _spin_value(controls, "damage")
	var race_id: int = _option_id(controls, "race")

	if damage <= 0 or race_id == 1:
		return CombatConstants.MAX_BEAMS

	var damage_limit: int = 150 if race_id == 2 else 100
	var max_weapons: int = int(ceil((float(damage_limit) - float(damage)) / 10.0))
	return max(0, max_weapons)


func _update_builder_shield_rule(side_key: String) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	if controls.has("is_planet") and (controls["is_planet"] as CheckBox).button_pressed:
		_set_builder_enabled(controls["shield"], true)
		return
	if _is_horwasp_hull(_option_id(controls, "hull")):
		(controls["shield"] as SpinBox).value = 0
		return

	var hull_id: int = _option_id(controls, "hull")
	var has_beams: bool = _option_id(controls, "beam_type") > 0 and _spin_value(controls, "beam_count") > 0
	if has_beams or ShipData.keeps_shields_without_beams(hull_id):
		_set_builder_enabled(controls["shield"], true)
	else:
		(controls["shield"] as SpinBox).value = 0
		_set_builder_enabled(controls["shield"], false)


func _apply_builder_weapon_visibility(controls: Dictionary, has_beams: bool, has_tubes: bool, has_bays: bool) -> void:
	_set_builder_row_visible(controls, "beam_type", has_beams)
	_set_builder_row_visible(controls, "beam_count", has_beams)
	_set_builder_row_visible(controls, "torp_type", has_tubes)
	_set_builder_row_visible(controls, "torp_count", has_tubes)
	_set_builder_row_visible(controls, "bay_count", has_bays)
	_set_builder_row_visible(controls, "ammo", has_tubes or has_bays)


func _set_builder_row_visible(controls: Dictionary, key: String, is_visible: bool) -> void:
	if controls.has(key + "_label"):
		(controls[key + "_label"] as Control).visible = is_visible
	if controls.has(key):
		(controls[key] as Control).visible = is_visible


func _on_builder_apply_pressed() -> void:
	_running = false
	simulation_result_label.text = ""
	simulation_result_label.visible = false
	simulation_overlay.visible = false
	current_vcr = _create_builder_vcr()
	_battle_builder_mode = true
	_reset_battle()
	vcr_index_label.text = "BattleSimulator"
	battle_setup_overlay.visible = false
	_on_simulate_button_pressed()


func _on_builder_swap_sides_pressed() -> void:
	var right: Dictionary = _builder_controls["right"]
	if right.has("is_planet") and (right["is_planet"] as CheckBox).button_pressed:
		return

	var left_settings: Dictionary = _capture_builder_side_settings("left")
	var right_settings: Dictionary = _capture_builder_side_settings("right")
	_apply_builder_side_settings("left", right_settings)
	_apply_builder_side_settings("right", left_settings)


func _capture_builder_side_settings(side_key: String) -> Dictionary:
	var controls: Dictionary = _builder_controls[side_key]
	var settings: Dictionary = {}

	for key in controls.keys():
		var key_text: String = String(key)
		if key_text.ends_with("_label"):
			continue

		var control: Variant = controls[key]
		if control is SpinBox:
			settings[key_text] = {"type": "spin", "value": (control as SpinBox).value}
		elif control is LineEdit:
			settings[key_text] = {"type": "line", "value": (control as LineEdit).text}
		elif control is OptionButton:
			settings[key_text] = {"type": "option", "value": (control as OptionButton).get_selected_id()}
		elif control is CheckBox:
			settings[key_text] = {"type": "check", "value": (control as CheckBox).button_pressed}

	return settings


func _apply_builder_side_settings(side_key: String, settings: Dictionary) -> void:
	var controls: Dictionary = _builder_controls[side_key]
	var blocked_controls: Array[Control] = []

	for key in controls.keys():
		var control: Variant = controls[key]
		if control is Control:
			(control as Control).set_block_signals(true)
			blocked_controls.append(control as Control)

	if controls.has("is_planet") and settings.has("is_planet"):
		(controls["is_planet"] as CheckBox).button_pressed = bool(settings["is_planet"]["value"])
	if settings.has("race"):
		_select_option_by_id(controls["race"] as OptionButton, int(settings["race"]["value"]))
	(controls["owner"] as SpinBox).value = _option_id(controls, "race")

	var race_id: int = _option_id(controls, "race")
	var hull_id: int = int(settings["hull"]["value"]) if settings.has("hull") else 0
	_fill_hull_option(controls["hull"] as OptionButton, race_id, hull_id)
	_select_option_by_id(controls["hull"] as OptionButton, hull_id)

	for key in settings.keys():
		if key in ["is_planet", "owner", "race", "hull"]:
			continue
		if not controls.has(key):
			continue

		var data: Dictionary = settings[key]
		var control: Variant = controls[key]
		match String(data.get("type", "")):
			"spin":
				(control as SpinBox).value = float(data["value"])
			"line":
				(control as LineEdit).text = String(data["value"])
			"option":
				_select_option_by_id(control as OptionButton, int(data["value"]))
			"check":
				(control as CheckBox).button_pressed = bool(data["value"])

	for control: Control in blocked_controls:
		control.set_block_signals(false)

	if controls.has("is_planet") and (controls["is_planet"] as CheckBox).button_pressed:
		_on_builder_planet_toggled(true, side_key)
	else:
		_update_builder_hull_defaults(side_key, false)

	if settings.has("name"):
		_sync_builder_name_to_hull(side_key)


func _create_builder_vcr() -> ClassicVcr:
	var vcr: ClassicVcr = ClassicVcr.new()
	vcr.battle_seed = 1
	vcr.set_single_combatants(_create_builder_object("left"), _create_builder_object("right"))

	if vcr.right.is_planet:
		vcr.battle_type = CombatConstants.SHIP_TO_PLANET
	else:
		vcr.battle_type = CombatConstants.SHIP_TO_SHIP

	return vcr


func _create_builder_object(side_key: String) -> CombatObject:
	var controls: Dictionary = _builder_controls[side_key]
	var obj: CombatObject = CombatObject.new()
	var is_planet: bool = controls.has("is_planet") and (controls["is_planet"] as CheckBox).button_pressed

	obj.object_id = _spin_value(controls, "object_id")
	obj.race_id = _option_id(controls, "race")
	obj.owner_id = obj.race_id
	(controls["owner"] as SpinBox).value = obj.race_id
	obj.hull_id = 0 if is_planet else _option_id(controls, "hull")
	obj.is_planet = is_planet
	obj.object_name = "Planet" if is_planet else String(ShipData.get_hull(obj.hull_id).get("name", "Ship"))
	_apply_builder_hull_abilities(obj)

	if is_planet:
		_apply_builder_planet_values(obj, controls)
		return obj

	if _is_horwasp_hull(obj.hull_id):
		_apply_builder_horwasp_ship_values(obj, controls)
		return obj

	obj.beam_type = _option_id(controls, "beam_type")
	obj.beam_count = _spin_value(controls, "beam_count")
	obj.torp_type = _option_id(controls, "torp_type")
	obj.torp_launcher_count = _spin_value(controls, "torp_count")
	obj.bay_count = _spin_value(controls, "bay_count")
	obj.shield = _spin_value(controls, "shield")
	obj.damage = _spin_value(controls, "damage")
	obj.crew = _spin_value(controls, "crew")
	obj.crew_max = obj.crew
	obj.mass = max(1, _spin_value(controls, "mass"))
	_apply_builder_ssg_support(obj, controls)

	var hull: Dictionary = ShipData.get_hull(obj.hull_id)
	var cargo_capacity: int = int(hull.get("cargo", 0))
	var ammo: int = min(_spin_value(controls, "ammo"), cargo_capacity)
	if obj.bay_count > 0:
		obj.fighter_count = ammo
		obj.torp_count = 0
	elif obj.torp_launcher_count > 0:
		obj.torp_count = ammo
		obj.fighter_count = 0
	else:
		obj.torp_count = 0
		obj.fighter_count = 0

	if obj.beam_type <= 0:
		obj.beam_count = 0
	if obj.torp_type <= 0:
		obj.torp_launcher_count = 0
	if not obj.is_planet and obj.beam_count <= 0 and not ShipData.keeps_shields_without_beams(obj.hull_id):
		obj.shield = 0

	obj.beam_kill_rate = 1
	obj.beam_charge_rate = 1
	obj.torp_charge_rate = 1
	obj.torp_miss_rate = 35
	obj.crew_defense_rate = 0
	obj.torp_range = ShipData.get_torp_range(obj.torp_type)
	obj.damage_limit = 150 if obj.race_id == 2 else 100

	if _builder_uses_fast_beams(controls):
		obj.beam_charge_rate = 2

	_apply_builder_damage_weapon_limits(obj)
	_apply_builder_fed_bay_bonus(obj)
	_apply_builder_red_wind_support(obj, controls)
	if not obj.is_planet and obj.beam_count <= 0 and not ShipData.keeps_shields_without_beams(obj.hull_id):
		obj.shield = 0
	return obj


func _apply_builder_horwasp_ship_values(obj: CombatObject, controls: Dictionary) -> void:
	var hull: Dictionary = ShipData.get_hull(obj.hull_id)
	var cargo_capacity: int = max(1, int(hull.get("cargo", 0)))
	var clans: int = clamp(_spin_value(controls, "ammo"), 0, cargo_capacity)
	var weapon_slot: int = clamp(int(floor(float(clans) * 9.0 / float(cargo_capacity))) + 1, 1, 10)
	var hull_mass: int = int(hull.get("mass", 0))

	obj.beam_type = weapon_slot
	obj.beam_count = int(hull.get("beams", 0))
	obj.torp_type = weapon_slot
	obj.torp_launcher_count = int(hull.get("launchers", 0))
	obj.bay_count = int(hull.get("bays", 0))
	obj.shield = 0
	obj.damage = 0
	obj.crew = max(1, int(hull.get("crew", 1)))
	obj.crew_max = obj.crew
	obj.mass = hull_mass + int(floor(float(hull_mass) * float(clans) / float(cargo_capacity)))
	obj.torp_count = 10000 if obj.torp_launcher_count > 0 else 0
	obj.fighter_count = _horwasp_fighter_count(obj.hull_id, clans, cargo_capacity) if obj.bay_count > 0 else 0

	obj.beam_kill_rate = 1
	obj.beam_charge_rate = 2 if _builder_uses_fast_beams(controls) else 1
	obj.torp_charge_rate = 1
	obj.torp_miss_rate = 35
	obj.crew_defense_rate = 175 if ShipData.is_jacker_hull(obj.hull_id) else 100
	obj.torp_range = ShipData.get_torp_range(obj.torp_type)
	obj.damage_limit = 100


func _apply_builder_hull_abilities(obj: CombatObject) -> void:
	obj.component_hull_ids = ShipData.get_stacked_component_ids(obj.hull_id)
	obj.is_squadron = ShipData.is_squadron_hull(obj.hull_id)
	obj.is_elusive = ShipData.is_elusive_hull(obj.hull_id)
	obj.has_gravitonic_accelerator = ShipData.has_gravitonic_accelerator(obj.hull_id)


func _horwasp_fighter_count(hull_id: int, clans: int, cargo_capacity: int) -> int:
	var hull_name: String = String(ShipData.get_hull(hull_id).get("name", "")).to_lower()
	var max_fighters: int = 0
	var base_fighters: int = 0

	if hull_name == "hive":
		max_fighters = 70
		base_fighters = 10
	elif hull_name == "brood":
		max_fighters = 70
		base_fighters = 10
	elif hull_name == "soldier":
		max_fighters = 40
		base_fighters = 10
	else:
		return 0

	return clamp(int(floor(float(clans) * float(max_fighters - base_fighters) / float(max(1, cargo_capacity)))) + base_fighters, 0, max_fighters)


func _apply_builder_planet_values(obj: CombatObject, controls: Dictionary) -> void:
	var has_starbase: bool = controls.has("starbase") and (controls["starbase"] as CheckBox).button_pressed
	var starbase_type: int = _option_id(controls, "starbase_type") if controls.has("starbase_type") else 0
	var planet_defense_posts: int = min(_spin_value(controls, "planet_defense_posts") if controls.has("planet_defense_posts") else 0, 200)
	var starbase_defense_posts: int = min(_spin_value(controls, "starbase_defense_posts") if controls.has("starbase_defense_posts") else 0, _starbase_max_defense(starbase_type)) if has_starbase else 0
	var fighters: int = min(_spin_value(controls, "starbase_fighters") if controls.has("starbase_fighters") else 0, _starbase_max_fighters(starbase_type)) if has_starbase else 0
	var beam_tech: int = clamp(_spin_value(controls, "starbase_beam_tech") if controls.has("starbase_beam_tech") else 0, 0, 10)
	var starbase_mass_bonus: int = _starbase_mass_bonus(starbase_type) if has_starbase else 0
	var beam_defense_value: int = planet_defense_posts + starbase_defense_posts + starbase_mass_bonus
	var planet_fighters: int = _planet_defense_fighters(planet_defense_posts)
	var planet_bays: int = _planet_defense_bays(planet_defense_posts)
	var planet_beam_type: int = _planet_defense_beam_type(planet_defense_posts)

	obj.hull_id = 0
	obj.shield = 100
	obj.damage = 0
	obj.crew = 10000
	obj.crew_max = obj.crew
	obj.mass = 100 + planet_defense_posts + starbase_defense_posts + starbase_mass_bonus
	obj.torp_type = 0
	obj.torp_launcher_count = 0
	obj.torp_count = 0
	obj.planet_img = "planet.png"
	obj.has_starbase = has_starbase
	obj.starbase_style = _spin_value(controls, "starbase_style") if controls.has("starbase_style") else 1
	obj.damage_limit = 100
	obj.beam_kill_rate = 1
	obj.beam_charge_rate = 2 if _builder_uses_fast_beams(controls) else 1
	obj.torp_charge_rate = 1
	obj.torp_miss_rate = 35
	obj.crew_defense_rate = 0
	obj.torp_range = 300
	obj.beam_type = planet_beam_type
	obj.beam_count = _planet_defense_beam_count(beam_defense_value)
	obj.bay_count = planet_bays + (5 if has_starbase else 0)
	obj.fighter_count = planet_fighters + fighters

	if has_starbase:
		obj.beam_type = max(planet_beam_type, beam_tech)
		obj.beam_charge_rate = 2 if _builder_uses_fast_beams(controls) else 1


func _planet_defense_fighters(defense_posts: int) -> int:
	return int(round(sqrt(max(0.0, float(defense_posts) - 0.75))))


func _planet_defense_bays(defense_posts: int) -> int:
	return int(floor(sqrt(float(max(0, defense_posts)))))


func _planet_defense_beam_count(defense_value: int) -> int:
	if defense_value <= 0:
		return 0
	return min(10, int(round(sqrt(float(defense_value) / 3.0))))


func _planet_defense_beam_type(defense_posts: int) -> int:
	if defense_posts <= 0:
		return 0
	return min(10, int(floor(sqrt(float(defense_posts) / 2.0))) + 1)


func _builder_uses_fast_beams(controls: Dictionary) -> bool:
	return controls.has("fast_beams") and (controls["fast_beams"] as CheckBox).button_pressed


func _apply_builder_ssg_support(obj: CombatObject, controls: Dictionary) -> void:
	if obj.is_planet or _is_horwasp_hull(obj.hull_id):
		return

	var ssg_count: int = clamp(_spin_value(controls, "ssg_count") if controls.has("ssg_count") else 0, 0, 2)
	if ssg_count <= 0:
		return

	var engine_type: int = _option_id(controls, "engine_type") if controls.has("engine_type") else 0
	obj.shield = min(150, obj.shield + 25 * ssg_count)
	obj.mass += _ssg_engine_mass_bonus(engine_type) * ssg_count


func _apply_builder_red_wind_support(obj: CombatObject, controls: Dictionary) -> void:
	if obj.is_planet or _is_horwasp_hull(obj.hull_id):
		return
	if obj.bay_count <= 0:
		return
	if not controls.has("red_wind_support") or not (controls["red_wind_support"] as CheckBox).button_pressed:
		return

	obj.bay_count += 2
	obj.bay_bonus_count += 2
	obj.bay_bonus_parts.append(2)
	obj.fighter_count += clamp(_spin_value(controls, "red_wind_fighters"), 0, _red_wind_max_fighters())


func _apply_builder_fed_bay_bonus(obj: CombatObject) -> void:
	if obj.race_id != 1 or obj.bay_count <= 0:
		return
	obj.bay_count += 3
	obj.bay_bonus_count += 3
	obj.bay_bonus_parts.append(3)


func _red_wind_max_fighters() -> int:
	for hull_id: int in [1047, 47]:
		var hull: Dictionary = ShipData.get_hull(hull_id)
		if not hull.is_empty():
			return max(0, int(hull.get("cargo", 60)))
	return 60


func _ssg_engine_mass_bonus(engine_type: int) -> int:
	match engine_type:
		1: return 1
		2: return 1
		3: return 2
		4: return 2
		5: return 13
		6: return 27
		7: return 85
		8: return 100
		9: return 150
		_: return 0


func _apply_builder_damage_weapon_limits(obj: CombatObject) -> void:
	if obj.race_id == 1 or obj.damage <= 0:
		return

	var max_weapons: int = int(ceil((100.0 - float(obj.damage)) / 10.0))
	if obj.race_id == 2:
		max_weapons = int(ceil((150.0 - float(obj.damage)) / 10.0))
	if max_weapons < 0:
		max_weapons = 0

	obj.bay_count = min(obj.bay_count, max_weapons)
	obj.torp_launcher_count = min(obj.torp_launcher_count, max_weapons)
	obj.beam_count = min(obj.beam_count, max_weapons)
		
func battle_x_to_screen_x_unclamped(v: float) -> float:
	return lerpf(_visual_track_left_bound, _visual_track_right_bound, _battle_x_ratio(v))
	
func _find_target_fighter_pos(target_side: int, battle_x: float) -> Vector2:
	var best_dist: float = 999999.0
	var best_pos: Vector2 = Vector2(battle_x_to_screen_x(battle_x), 270.0)

	if target_side == CombatTypes.Side.LEFT:
		for i: int in range(CombatConstants.MAX_FIGHTERS):
			if engine.state.left.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
				var fx: float = engine.state.left.fighter_x[i]
				var dist: float = abs(fx - battle_x)
				if dist < best_dist:
					best_dist = dist
					best_pos = Vector2(
						battle_x_to_screen_x(fx),
						_fighter_lane_y_left(i)
					)
	else:
		for i: int in range(CombatConstants.MAX_FIGHTERS):
			if engine.state.right.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
				var fx: float = engine.state.right.fighter_x[i]
				var dist: float = abs(fx - battle_x)
				if dist < best_dist:
					best_dist = dist
					best_pos = Vector2(
						battle_x_to_screen_x(fx),
						_fighter_lane_y_right(i)
					)

	return best_pos

func _find_target_fighter_view(target_side: int, battle_x: float) -> FighterView:
	var best_dist: float = 999999.0
	var best_view: FighterView = null

	if target_side == CombatTypes.Side.LEFT:
		for i: int in range(CombatConstants.MAX_FIGHTERS):
			if engine.state.left.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
				var fx: float = engine.state.left.fighter_x[i]
				var dist: float = abs(fx - battle_x)
				if dist < best_dist:
					best_dist = dist
					best_view = _fighter_views_left[i]
	else:
		for i: int in range(CombatConstants.MAX_FIGHTERS):
			if engine.state.right.fighter_active[i] != CombatConstants.FIGHTER_IDLE:
				var fx: float = engine.state.right.fighter_x[i]
				var dist: float = abs(fx - battle_x)
				if dist < best_dist:
					best_dist = dist
					best_view = _fighter_views_right[i]

	return best_view
	
func _get_fighter_tip_pos(view: FighterView) -> Vector2:
	if view == null:
		return Vector2.ZERO

	var local_tip: Vector2 = Vector2(5.0, 0.0)
	if view.is_returning:
		local_tip = Vector2(-5.0, 0.0)

	return view.global_position + local_tip
	
func _on_beam_hit_fighter(_attacker_side: int, from_x: int, target_side: int, target_index: int) -> void:
	var from_pos: Vector2 = Vector2(battle_x_to_screen_x(from_x), SHIP_Y)
	var to_pos: Vector2

	if target_side == CombatTypes.Side.LEFT:
		to_pos = Vector2(
			battle_x_to_screen_x(engine.state.left.fighter_x[target_index]),
			_fighter_lane_y_left(target_index)
		)
	else:
		to_pos = Vector2(
			battle_x_to_screen_x(engine.state.right.fighter_x[target_index]),
			_fighter_lane_y_right(target_index)
		)

	var p: CombatProjectileView = CombatProjectileView.new()
	p.color = Color(0.5, 0.9, 1.0, 0.95)
	p.width = 3.0
	p.projectile_radius = 2.0
	p.draw_trail = true
	p.use_constant_speed = false
	p.lifetime = 0.10
	effects_layer.add_child(p)
	p.setup(from_pos, to_pos)
	_spawn_impact(to_pos)

func _build_beam_title(obj: CombatObject) -> String:
	if obj.beam_count <= 0 or obj.beam_type <= 0:
		return "No Beams"
	return "%d %s" % [obj.beam_count, ShipData.get_beam_name(obj.beam_type)]


func _build_torp_title(obj: CombatObject) -> String:
	if obj.torp_launcher_count <= 0 or obj.torp_type <= 0:
		return "No Torpedo Tubes"
	return "%d %s" % [obj.torp_launcher_count, ShipData.get_torp_name(obj.torp_type)]


func _build_bay_title(obj: CombatObject) -> String:
	if obj.bay_count <= 0:
		return "No Fighter Bays"
	var bonus_count: int = clamp(obj.bay_bonus_count, 0, obj.bay_count)
	var base_count: int = obj.bay_count - bonus_count
	if bonus_count > 0:
		var parts: Array[String] = []
		for part: int in obj.bay_bonus_parts:
			if part > 0:
				parts.append("+%d" % part)
		if parts.is_empty():
			parts.append("+%d" % bonus_count)
		return "%d %s Fighter Bays" % [base_count, " ".join(parts)]
	if obj.bay_count == 1:
		return "1 Fighter Bay"
	return "%d Fighter Bays" % obj.bay_count
	
func _apply_weapon_titles() -> void:
	var left_obj: CombatObject = engine.state.left.obj
	var right_obj: CombatObject = engine.state.right.obj

	left_beam_title.text = _build_beam_title(left_obj)
	left_torp_title.text = _build_torp_title(left_obj)
	left_bay_title.text = _build_bay_title(left_obj)

	right_beam_title.text = _build_beam_title(right_obj)
	right_torp_title.text = _build_torp_title(right_obj)
	right_bay_title.text = _build_bay_title(right_obj)

	left_beam_title.visible = left_obj.beam_count > 0
	left_torp_title.visible = left_obj.torp_launcher_count > 0
	left_bay_title.visible = left_obj.bay_count > 0

	right_beam_title.visible = right_obj.beam_count > 0
	right_torp_title.visible = right_obj.torp_launcher_count > 0
	right_bay_title.visible = right_obj.bay_count > 0

func _get_race_short(race_id: int) -> String:
	match race_id:
		1: return "FED"
		2: return "LIZ"
		3: return "BIRD"
		4: return "FURY"
		5: return "PRIV"
		6: return "CYBORG"
		7: return "CRYSTAL"
		8: return "EE"
		9: return "ROBOT"
		10: return "REBEL"
		11: return "CoM"
		12: return "HORWASP"
		_: return "?"

func _apply_planet_visual_data_from_turn(_entry: Dictionary) -> void:
	if not _turn_data.has("rst"):
		return

	var rst: Dictionary = _turn_data["rst"]
	if not rst.has("planets"):
		return

	var planets: Array = rst["planets"]

	_apply_planet_visual_to_side(current_vcr.left, planets)
	_apply_planet_visual_to_side(current_vcr.right, planets)


func _apply_planet_visual_to_side(obj: CombatObject, planets: Array) -> void:
	if not obj.is_planet:
		return

	for p_var in planets:
		if typeof(p_var) != TYPE_DICTIONARY:
			continue
		var p: Dictionary = p_var

		if int(p.get("id", -1)) == obj.object_id:
			var img_path: String = String(p.get("img", ""))
			obj.planet_img = img_path.get_file()
			obj.has_starbase = obj.has_starbase or bool(p.get("buildingstarbase", false))
			return

func _spawn_impact(pos: Vector2) -> void:
	var fx: CombatEffectView = CombatEffectView.new()
	effects_layer.add_child(fx)
	fx.setup_impact(pos)

func _spawn_explosion(pos: Vector2) -> void:
	var fx: CombatEffectView = CombatEffectView.new()
	effects_layer.add_child(fx)
	fx.setup_explosion(pos)
	
func _spawn_shield_hit(target_side: int) -> void:
	var pos: Vector2
	var ship_view: ShipView

	if target_side == CombatTypes.Side.LEFT:
		pos = Vector2(
			battle_x_to_screen_x(engine.state.left.cur_x),
			SHIP_Y
		)
		ship_view = left_ship
	else:
		pos = Vector2(
			battle_x_to_screen_x(engine.state.right.cur_x),
			SHIP_Y
		)
		ship_view = right_ship

	var ship_height: float = ship_view.get_visual_height()

	var fx: CombatEffectView = CombatEffectView.new()
	effects_layer.add_child(fx)
	fx.setup_shield_hit(pos, target_side, ship_height)
	
func _apply_background() -> void:
	var tex := load("res://Assets/Backgrounds/background.png")
	if tex != null:
		background_sprite.texture = tex
		background_sprite.centered = false
		background_sprite.position = Vector2(0.0, BATTLE_TOP)

		var tex_size: Vector2 = tex.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			background_sprite.scale = Vector2(
				get_viewport_rect().size.x / tex_size.x,
				BATTLE_HEIGHT / tex_size.y
			)
			
func _on_hit_resolved(target_side: int, shield: int, _damage: int, _crew: int) -> void:
	var torp_projectile: CombatProjectileView = _take_torp_hit_projectile(target_side)
	if torp_projectile != null:
		torp_projectile.projectile_finished.connect(func() -> void:
			_spawn_hit_effect(target_side, shield)
		)
		return

	_spawn_hit_effect(target_side, shield)


func _spawn_hit_effect(target_side: int, shield: int) -> void:
	if shield > 0:
		_spawn_shield_hit(target_side)
	else:
		var pos: Vector2
		if target_side == CombatTypes.Side.LEFT:
			pos = Vector2(battle_x_to_screen_x(engine.state.left.cur_x), SHIP_Y)
		else:
			pos = Vector2(battle_x_to_screen_x(engine.state.right.cur_x), SHIP_Y)

		_spawn_explosion(pos)

func _spawn_big_explosion(pos: Vector2, visual_size: float) -> void:
	var fx: CombatEffectView = CombatEffectView.new()
	effects_layer.add_child(fx)
	fx.setup_big_explosion(pos, visual_size)
	
func _is_visually_destroyed(obj: CombatObject) -> bool:
	if obj == null:
		return true

	if obj.is_planet:
		return obj.damage >= 100

	if obj.damage >= obj.damage_limit:
		return true

	if obj.crew <= 0:
		return true
	
	return false
