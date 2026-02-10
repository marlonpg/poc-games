extends Area2D
class_name CarController

signal hazard_hit(damage: float)
signal fuel_collected(amount: float)
signal drift_state_changed(is_drifting: bool)

@export var accel := 320.0
@export var max_speed := 240.0
@export var turn_speed := 2.9
@export var drift_factor := 6.0
@export var drift_alignment := 0.32
@export var drift_push := 0.75
@export var drift_lateral_damp := 1.2
@export var drift_steer_boost := 1.25
@export var drift_lateral_boost := 0.35
@export var drift_inertia := 1.0
@export var base_hazard_damage := 15.0
@export var base_fuel_pickup := 35.0
@export var surface_speed_multiplier := 1.0
@export var surface_drift_multiplier := 1.0

var speed := 0.0
var steering_input := 0.0
var velocity := Vector2.ZERO
var is_drifting := false
var _smokes: Array[CPUParticles2D] = []

func _ready() -> void:
	_smokes.clear()
	for name in ["DriftSmokeFL", "DriftSmokeFR", "DriftSmokeRL", "DriftSmokeRR"]:
		var node := get_node_or_null(name)
		if node != null:
			_smokes.append(node)
	area_entered.connect(_on_area_entered)

func set_steering(value: float) -> void:
	steering_input = clamp(value, -1.0, 1.0)

func reset() -> void:
	speed = 0.0
	velocity = Vector2.ZERO
	rotation = 0.0

func _physics_process(delta: float) -> void:
	speed = min(max_speed, speed + accel * delta)
	var forward := Vector2(0, -1).rotated(rotation)
	var right := forward.orthogonal()
	var target_speed: float = speed * surface_speed_multiplier
	var desired_dir: Vector2 = forward
	var vel_dir: Vector2 = velocity.normalized() if velocity.length() > 0.01 else desired_dir
	var drift_strength: float = clamp(abs(steering_input), 0.0, 1.0)
	var align: float = drift_factor * delta
	if drift_strength > 0.1:
		align *= drift_alignment
	align *= (1.0 - drift_strength * drift_inertia)
	var dir: Vector2 = vel_dir.lerp(desired_dir, clamp(align, 0.0, 1.0)).normalized()
	velocity = dir * target_speed
	if abs(steering_input) > 0.1:
		var lateral: Vector2 = right * steering_input * speed * drift_push * surface_drift_multiplier
		velocity += lateral * delta
		var drift_boost: float = speed * drift_lateral_boost * abs(steering_input)
		velocity += right * drift_boost * delta
	var lateral_speed: float = velocity.dot(right)
	velocity -= right * lateral_speed * drift_lateral_damp * delta
	position += velocity * delta
	var speed_ratio: float = clamp(speed / max_speed, 0.0, 1.0)
	var steer_scale: float = lerp(0.0, drift_steer_boost, speed_ratio)
	rotation += steering_input * turn_speed * delta * steer_scale
	var drifting: bool = abs(steering_input) > 0.35
	if drifting != is_drifting:
		is_drifting = drifting
		for smoke in _smokes:
			if smoke != null:
				smoke.emitting = is_drifting
		emit_signal("drift_state_changed", is_drifting)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("hazard"):
		var damage := base_hazard_damage
		if area.has_method("get_damage"):
			damage = float(area.call("get_damage"))
		emit_signal("hazard_hit", damage)
		if area.has_method("on_hit"):
			area.call_deferred("on_hit")
	elif area.is_in_group("fuel"):
		var amount := base_fuel_pickup
		if area.has_method("get_amount"):
			amount = float(area.call("get_amount"))
		emit_signal("fuel_collected", amount)
		area.queue_free()
