extends Area2D
class_name CarController

signal hazard_hit(damage: float)
signal fuel_collected(amount: float)
signal drift_state_changed(is_drifting: bool)

@export var accel := 220.0
@export var max_speed := 480.0
@export var turn_speed := 2.9
@export var drift_factor := 6.0
@export var drift_alignment := 0.6
@export var drift_push := 0.12
@export var base_hazard_damage := 15.0
@export var base_fuel_pickup := 35.0

var speed := 0.0
var steering_input := 0.0
var velocity := Vector2.ZERO
var is_drifting := false
var _smoke: CPUParticles2D

func _ready() -> void:
	_smoke = get_node_or_null("DriftSmoke")
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
	var desired := forward * speed
	var align := drift_factor * delta
	if abs(steering_input) > 0.1:
		align *= drift_alignment
	velocity = velocity.lerp(desired, clamp(align, 0.0, 1.0))
	if abs(steering_input) > 0.1:
		var lateral: Vector2 = forward.orthogonal() * steering_input * speed * drift_push
		velocity += lateral * delta
	position += velocity * delta
	rotation += steering_input * turn_speed * delta * (speed / max_speed + 0.2)
	var drifting: bool = abs(steering_input) > 0.35
	if drifting != is_drifting:
		is_drifting = drifting
		if _smoke != null:
			_smoke.emitting = is_drifting
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
