extends Node2D
class_name RoadBackdrop

var _road_center_x := 0.0
var _road_width := 520.0
var _distance_m := 0.0
var _lane_width := 260.0
var _shoulder_width := 80.0

func set_road(center_x: float, width: float, distance_m: float, lane_width: float, shoulder_width: float) -> void:
	_road_center_x = center_x
	_road_width = width
	_distance_m = distance_m
	_lane_width = lane_width
	_shoulder_width = shoulder_width
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var cam_pos: Vector2 = cam.global_position
	var top_left: Vector2 = cam_pos - viewport_size * 0.5

	var grass_color := Color(0.1, 0.35, 0.18, 1.0)
	var road_color := Color(0.16, 0.16, 0.18, 1.0)
	var line_color := Color(0.9, 0.9, 0.9, 0.7)
	var edge_color := Color(0.95, 0.95, 0.95, 0.8)
	var shoulder_color := Color(0.95, 0.95, 0.95, 0.55)
	draw_rect(Rect2(top_left, viewport_size), grass_color)

	var road_center_world: float = _road_center_x
	var road_left: float = road_center_world - _road_width * 0.5
	var road_right: float = road_center_world + _road_width * 0.5
	var road_rect := Rect2(Vector2(road_left, top_left.y), Vector2(_road_width, viewport_size.y))
	draw_rect(road_rect, road_color)

	var edge_width: float = 6.0
	draw_rect(Rect2(Vector2(road_left - edge_width, top_left.y), Vector2(edge_width, viewport_size.y)), edge_color)
	draw_rect(Rect2(Vector2(road_right, top_left.y), Vector2(edge_width, viewport_size.y)), edge_color)

	var shoulder_line_width: float = 3.0
	var left_shoulder_x: float = road_left + _shoulder_width
	var right_shoulder_x: float = road_right - _shoulder_width - shoulder_line_width
	draw_rect(Rect2(Vector2(left_shoulder_x, top_left.y), Vector2(shoulder_line_width, viewport_size.y)), shoulder_color)
	draw_rect(Rect2(Vector2(right_shoulder_x, top_left.y), Vector2(shoulder_line_width, viewport_size.y)), shoulder_color)

	var dash_spacing: float = 120.0
	var dash_length: float = 60.0
	var offset: float = fmod(-cam_pos.y, dash_spacing)
	var y: float = top_left.y - dash_length + offset
	while y < top_left.y + viewport_size.y + dash_length:
		var dash_rect := Rect2(Vector2(road_center_world - 6.0, y), Vector2(12.0, dash_length))
		draw_rect(dash_rect, line_color)
		y += dash_spacing
