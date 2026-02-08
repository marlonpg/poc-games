extends Node2D
class_name Spawner

@export var game_path: NodePath
@export var car_path: NodePath
@export var spawn_distance := 1200.0

var _game: Node
var _car: Node2D
var _hazard_timer := 0.0
var _fuel_timer := 0.0

var _obstacle_scene := preload("res://scenes/Obstacle.tscn")
var _fuel_scene := preload("res://scenes/FuelPickup.tscn")
var _enemy_scene := preload("res://scenes/EnemyCar.tscn")

func _ready() -> void:
	_game = get_node(game_path)
	_car = get_node(car_path)
	set_process(true)
	randomize()

func reset() -> void:
	_hazard_timer = 0.0
	_fuel_timer = 0.0
	for child in get_children():
		child.queue_free()

func _process(delta: float) -> void:
	if _game == null or _car == null:
		return
	if not _game.call("is_run_active"):
		return
	_hazard_timer += delta
	_fuel_timer += delta
	var difficulty: float = float(_game.call("get_difficulty"))
	var hazard_interval: float = lerp(1.2, 0.5, difficulty)
	var fuel_interval: float = lerp(2.6, 1.4, difficulty)

	if _hazard_timer >= hazard_interval:
		_hazard_timer = 0.0
		_spawn_hazard(difficulty)
	if _fuel_timer >= fuel_interval:
		_fuel_timer = 0.0
		_spawn_fuel()

	_cleanup()

func _spawn_hazard(difficulty: float) -> void:
	var use_enemy: bool = randf() < lerp(0.25, 0.6, difficulty)
	var scene: PackedScene = _enemy_scene if use_enemy else _obstacle_scene
	var hazard: Node2D = scene.instantiate()
	var road_center: float = float(_game.get("road_center_x"))
	var road_width: float = float(_game.get("road_width"))
	var x: float = road_center + randf_range(-road_width * 0.45, road_width * 0.45)
	var y: float = _car.position.y - spawn_distance
	hazard.position = Vector2(x, y)
	if use_enemy and hazard.has_method("set_speed"):
		hazard.call("set_speed", lerp(120.0, 220.0, difficulty))
	add_child(hazard)

func _spawn_fuel() -> void:
	var fuel: Node2D = _fuel_scene.instantiate()
	var road_center: float = float(_game.get("road_center_x"))
	var road_width: float = float(_game.get("road_width"))
	var x: float = road_center + randf_range(-road_width * 0.4, road_width * 0.4)
	var y: float = _car.position.y - spawn_distance * 0.9
	fuel.position = Vector2(x, y)
	add_child(fuel)

func _cleanup() -> void:
	var cutoff: float = _car.position.y + 1400.0
	for child in get_children():
		if child is Node2D and child.position.y > cutoff:
			child.queue_free()
