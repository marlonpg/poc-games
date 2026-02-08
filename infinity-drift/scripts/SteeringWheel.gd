extends Control
class_name SteeringWheel

signal steering_changed(value: float)

@export var max_angle_deg := 60.0
@export var return_speed := 5.0

var _angle := 0.0
var _dragging := false

func _ready() -> void:
	set_process(true)
	set_process_input(true)

func _process(delta: float) -> void:
	if not _dragging:
		_angle = lerp(_angle, 0.0, return_speed * delta)
		_emit_value()
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if not _dragging:
			_emit_value()
		queue_redraw()
	elif event is InputEventMouseMotion and _dragging:
		_update_from_position(event.position)
	elif event is InputEventScreenTouch:
		_dragging = event.pressed
		if not _dragging:
			_emit_value()
		queue_redraw()
	elif event is InputEventScreenDrag and _dragging:
		_update_from_position(event.position)

func _update_from_position(pos: Vector2) -> void:
	var center: Vector2 = size * 0.5
	var angle: float = (pos - center).angle()
	_angle = clamp(angle, deg_to_rad(-max_angle_deg), deg_to_rad(max_angle_deg))
	_emit_value()
	queue_redraw()

func _emit_value() -> void:
	var value: float = clamp(_angle / deg_to_rad(max_angle_deg), -1.0, 1.0)
	emit_signal("steering_changed", value)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = min(size.x, size.y) * 0.45
	draw_circle(center, radius, Color(0.08, 0.08, 0.08, 0.9))
	draw_circle(center, radius * 0.85, Color(0.18, 0.18, 0.18, 0.9))	
	var knob: Vector2 = center + Vector2(0, -radius * 0.75).rotated(_angle)
	draw_circle(knob, radius * 0.12, Color(0.95, 0.85, 0.3, 0.95))
	draw_line(center, knob, Color(1.0, 1.0, 1.0, 0.6), 3.0)
