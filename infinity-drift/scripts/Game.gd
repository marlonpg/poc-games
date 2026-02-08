extends Node2D

@export var road_width := 600.0
@export var road_margin := 50.0
@export var car_width_m := 1.8
@export var car_width_units := 70.0
@export var lane_width_m := 3.3
@export var shoulder_width_m := 2.0
@export var base_max_speed := 960.0
@export var speed_increase_per_km := 30.0
@export var accel := 440.0
@export var fuel_max := 100.0
@export var fuel_consumption_base := 3.0
@export var fuel_speed_factor := 0.004
@export var infinite_fuel := true
@export var distance_scale := 0.02
@export var durability_max := 100.0
@export var milestone_km := 1.0
@export var road_start_straight_m := 30.0
@export var road_segment_min_m := 50.0
@export var road_segment_max_m := 70.0
@export var road_curve_offset_min := 50.0
@export var road_curve_offset_max := 100.0
@export var road_center_limit := 340.0
@export var road_lookahead_m := 2000.0
@export var offroad_speed_multiplier := 0.7
@export var offroad_drift_multiplier := 2.0
@export var fence_offset_m := 5.0

@onready var car: CarController = $Car
@onready var spawner: Node = $World/Spawner
@onready var hud: Control = $CanvasLayer/HUD
@onready var wheel: SteeringWheel = $CanvasLayer/SteeringWheel
@onready var upgrade_menu: Control = $CanvasLayer/UpgradeMenu
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var road_backdrop: Node2D = $World/RoadBackdrop
@onready var audio: AudioManager = $AudioManager

var fuel := 0.0
var durability := 0.0
var distance_m := 0.0
var road_progress_m := 0.0
var time_s := 0.0
var road_center_x := 0.0
var _milestones := 0
var _run_active := false
var _paused := false
var _upgrades := {"speed": 0, "durability": 0, "fuel": 0}
var _best_distance := 0.0
var _best_time := 0.0
var _base_fuel_max := 0.0
var _base_durability_max := 0.0
var _base_max_speed := 0.0
var _road_segments: Array = []
var _road_end_m := 0.0
var _road_last_center := 0.0
var _road_segment_index := 0
var _last_curve_dir := 1
var _lane_width_units := 0.0
var _shoulder_width_units := 0.0
var _fence_offset_units := 0.0

func _ready() -> void:
	var stats: Dictionary = SaveManager.load_stats()
	_best_distance = float(stats.get("best_distance", 0.0))
	_best_time = float(stats.get("best_time", 0.0))
	var settings: Dictionary = SaveManager.load_settings()
	audio.set_audio_enabled(bool(settings.get("audio_enabled", true)))
	audio.set_sfx_enabled(bool(settings.get("sfx_enabled", true)))
	_base_fuel_max = fuel_max
	_base_durability_max = durability_max
	_base_max_speed = base_max_speed
	_update_road_metrics()
	randomize()

	car.hazard_hit.connect(_on_hazard_hit)
	car.fuel_collected.connect(_on_fuel_collected)
	car.drift_state_changed.connect(_on_drift_state_changed)
	wheel.steering_changed.connect(car.set_steering)
	upgrade_menu.upgrade_selected.connect(_on_upgrade_selected)
	if hud.has_signal("request_restart"):
		hud.connect("request_restart", Callable(self, "_on_restart"))
	if hud.has_signal("request_menu"):
		hud.connect("request_menu", Callable(self, "_on_menu"))
	pause_menu.request_resume.connect(_on_resume)
	pause_menu.request_restart.connect(_on_restart)
	pause_menu.request_menu.connect(_on_menu)

	start_run()

func start_run() -> void:
	_run_active = true
	_paused = false
	_set_simulation_active(true)
	_upgrades = {"speed": 0, "durability": 0, "fuel": 0}
	fuel_max = _base_fuel_max
	durability_max = _base_durability_max
	fuel = fuel_max
	durability = durability_max
	distance_m = 0.0
	road_progress_m = 0.0
	time_s = 0.0
	_milestones = 0
	_update_road_metrics()
	_init_road()
	car.max_speed = _base_max_speed
	car.accel = accel
	car.reset()
	car.position = Vector2.ZERO
	upgrade_menu.hide()
	pause_menu.hide()
	if hud.has_method("show_game_over"):
		hud.call("show_game_over", false)
	if spawner.has_method("reset"):
		spawner.call("reset")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
	if event.is_action_pressed("restart") and not _run_active:
		start_run()

func _physics_process(delta: float) -> void:
	if not _run_active or _paused:
		return
	_update_road(delta)
	_update_stats(delta)
	_update_speed_cap()
	_update_offroad(delta)
	_update_milestones()
	_update_ui()
	audio.set_engine_speed(car.speed, car.max_speed)

func _update_road(delta: float) -> void:
	_ensure_road(road_progress_m + road_lookahead_m)
	road_center_x = _get_road_center(road_progress_m)
	if road_backdrop.has_method("set_road"):
		road_backdrop.call("set_road", road_center_x, road_width, road_progress_m, _lane_width_units, _shoulder_width_units, _fence_offset_units)

func _update_stats(delta: float) -> void:
	time_s += delta
	distance_m += car.speed * delta * distance_scale
	var meters_per_unit: float = car_width_m / car_width_units
	var speed_mps: float = car.velocity.length() * meters_per_unit
	road_progress_m += speed_mps * delta
	if not infinite_fuel:
		var consumption: float = fuel_consumption_base + car.speed * fuel_speed_factor
		fuel = max(fuel - consumption * delta, 0.0)
		if fuel <= 0.0:
			_end_run()

func _update_speed_cap() -> void:
	var growth: float = (distance_m / 1000.0) * speed_increase_per_km
	car.max_speed = _base_max_speed + _upgrades["speed"] * 60.0 + growth

func _update_offroad(delta: float) -> void:
	var offset: float = abs(car.position.x - road_center_x)
	var limit: float = road_width * 0.5 - road_margin
	if offset > limit:
		car.surface_speed_multiplier = offroad_speed_multiplier
		car.surface_drift_multiplier = offroad_drift_multiplier
	else:
		car.surface_speed_multiplier = 1.0
		car.surface_drift_multiplier = 1.0

func _update_milestones() -> void:
	var km: float = distance_m / 1000.0
	var reached: int = int(floor(km / milestone_km))
	if reached > _milestones:
		_milestones = reached
		_pause_for_upgrade()

func _update_ui() -> void:
	if hud.has_method("update_stats"):
		var meters_per_unit: float = car_width_m / car_width_units
		var speed_mps: float = car.velocity.length() * meters_per_unit
		var speed_kmh: float = speed_mps * 3.6
		hud.call("update_stats", fuel, fuel_max, durability, durability_max, distance_m, time_s, speed_kmh, _best_distance, _best_time)

func _pause_for_upgrade() -> void:
	_paused = true
	_set_simulation_active(false)
	upgrade_menu.call("show_choices", _build_upgrade_choices())
	upgrade_menu.show()

func _toggle_pause() -> void:
	if not _run_active:
		return
	_paused = not _paused
	_set_simulation_active(not _paused)
	pause_menu.visible = _paused

func _on_resume() -> void:
	_paused = false
	_set_simulation_active(true)
	pause_menu.hide()

func _on_restart() -> void:
	start_run()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_upgrade_selected(upgrade_id: String) -> void:
	_apply_upgrade(upgrade_id)
	upgrade_menu.hide()
	_paused = false
	_set_simulation_active(true)

func _apply_upgrade(upgrade_id: String) -> void:
	if upgrade_id == "speed":
		_upgrades["speed"] += 1
		car.max_speed = _base_max_speed + _upgrades["speed"] * 60.0
	elif upgrade_id == "durability":
		_upgrades["durability"] += 1
		durability_max = _base_durability_max + _upgrades["durability"] * 20.0
		durability = min(durability + 20.0, durability_max)
	elif upgrade_id == "fuel":
		_upgrades["fuel"] += 1
		fuel_max = _base_fuel_max + _upgrades["fuel"] * 20.0
		fuel = min(fuel + 20.0, fuel_max)

func _build_upgrade_choices() -> Array:
	return [
		{
			"id": "speed",
			"title": "Speed Upgrade",
			"desc": "+60 max speed"
		},
		{
			"id": "durability",
			"title": "Durability Upgrade",
			"desc": "+20 durability"
		},
		{
			"id": "fuel",
			"title": "Fuel Tank Upgrade",
			"desc": "+20 fuel capacity"
		}
	]

func _on_hazard_hit(damage: float) -> void:
	durability = max(durability - damage, 0.0)
	audio.play_collision()
	if durability <= 0.0:
		_end_run()

func _on_fuel_collected(amount: float) -> void:
	fuel = min(fuel + amount, fuel_max)
	audio.play_pickup()

func _on_drift_state_changed(is_drifting: bool) -> void:
	if is_drifting:
		audio.play_screech()

func _end_run() -> void:
	if not _run_active:
		return
	_run_active = false
	_paused = false
	_set_simulation_active(false)
	_update_records()
	if hud.has_method("show_game_over"):
		hud.call("show_game_over", true)

func _set_simulation_active(active: bool) -> void:
	car.set_physics_process(active)
	if spawner != null:
		spawner.set_process(active)

func _update_records() -> void:
	var updated: bool = false
	if distance_m > _best_distance:
		_best_distance = distance_m
		updated = true
	if time_s > _best_time:
		_best_time = time_s
		updated = true
	if updated:
		SaveManager.save_stats(_best_distance, _best_time)

func is_run_active() -> bool:
	return _run_active

func get_difficulty() -> float:
	return clamp(distance_m / 8000.0, 0.0, 1.0)

func _update_road_metrics() -> void:
	var units_per_meter: float = car_width_units / car_width_m
	_lane_width_units = lane_width_m * units_per_meter
	_shoulder_width_units = shoulder_width_m * units_per_meter
	_fence_offset_units = fence_offset_m * units_per_meter
	road_width = (_lane_width_units * 2.0) + (_shoulder_width_units * 2.0)
	road_margin = car_width_units * 0.5

func _init_road() -> void:
	_road_segments.clear()
	_road_end_m = 0.0
	_road_last_center = 0.0
	_road_segment_index = 0
	_last_curve_dir = 1
	_add_straight_segment(road_start_straight_m)
	_ensure_road(distance_m + road_lookahead_m)

func _ensure_road(target_m: float) -> void:
	while _road_end_m < target_m:
		_add_random_segment()

func _add_straight_segment(length_m: float) -> void:
	var start_m: float = _road_end_m
	var end_m: float = _road_end_m + length_m
	var seg: Dictionary = {
		"start_m": start_m,
		"end_m": end_m,
		"start_center": _road_last_center,
		"end_center": _road_last_center
	}
	_road_segments.append(seg)
	_road_end_m = end_m

func _add_curve_segment(length_m: float, dir: int) -> void:
	var start_m: float = _road_end_m
	var end_m: float = _road_end_m + length_m
	var offset: float = randf_range(road_curve_offset_min, road_curve_offset_max) * dir
	var end_center: float = clamp(_road_last_center + offset, -road_center_limit, road_center_limit)
	var seg: Dictionary = {
		"start_m": start_m,
		"end_m": end_m,
		"start_center": _road_last_center,
		"end_center": end_center
	}
	_road_segments.append(seg)
	_road_end_m = end_m
	_road_last_center = end_center

func _add_random_segment() -> void:
	if randf() < 0.03:
		_add_straight_segment(randf_range(60.0, 110.0))
		return
	var dir: int = -_last_curve_dir
	if randf() < 0.35:
		dir = _last_curve_dir
	_last_curve_dir = dir
	_add_curve_segment(randf_range(road_segment_min_m, road_segment_max_m), dir)

func _get_road_center(at_m: float) -> float:
	while _road_segment_index < _road_segments.size() - 1:
		var seg: Dictionary = _road_segments[_road_segment_index]
		if at_m <= float(seg["end_m"]):
			break
		_road_segment_index += 1
	var current: Dictionary = _road_segments[_road_segment_index]
	var start_m: float = float(current["start_m"])
	var end_m: float = float(current["end_m"])
	var start_center: float = float(current["start_center"])
	var end_center: float = float(current["end_center"])
	var length_m: float = max(end_m - start_m, 0.001)
	var t: float = clamp((at_m - start_m) / length_m, 0.0, 1.0)
	var smooth: float = t * t * (3.0 - 2.0 * t)
	return lerp(start_center, end_center, smooth)
