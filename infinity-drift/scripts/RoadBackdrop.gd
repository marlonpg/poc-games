extends Node2D
class_name RoadBackdrop

var _road_center_x := 0.0
var _road_center_future_x := 0.0
var _road_width := 520.0
var _distance_m := 0.0
var _lane_width := 260.0
var _shoulder_width := 80.0
var _fence_offset := 120.0
var _track_points: PackedVector2Array = PackedVector2Array()
var _track_width := 520.0
var _curb_width := 10.0
var _use_track := false

func set_road(center_x: float, future_center_x: float, width: float, distance_m: float, lane_width: float, shoulder_width: float, fence_offset: float) -> void:
	_use_track = false
	_road_center_x = center_x
	_road_center_future_x = future_center_x
	_road_width = width
	_distance_m = distance_m
	_lane_width = lane_width
	_shoulder_width = shoulder_width
	_fence_offset = fence_offset
	queue_redraw()

func set_track(points: PackedVector2Array, track_width: float, curb_width: float) -> void:
	_use_track = true
	_track_points = points
	_track_width = track_width
	_curb_width = curb_width
	queue_redraw()

func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var cam_pos: Vector2 = cam.global_position
	var top_left: Vector2 = cam_pos - viewport_size * 0.5
	if _use_track and _track_points.size() >= 2:
		_draw_track(top_left, viewport_size)
		return

	var grass_color := Color(0.1, 0.35, 0.18, 1.0)
	var road_color := Color(0.16, 0.16, 0.18, 1.0)
	var line_color := Color(0.9, 0.9, 0.9, 0.7)
	var edge_color := Color(0.95, 0.95, 0.95, 0.8)
	var shoulder_color := Color(0.95, 0.95, 0.95, 0.55)
	var fence_color := Color(0.12, 0.12, 0.12, 0.9)
	draw_rect(Rect2(top_left, viewport_size), grass_color)

	var road_center_bottom: float = _road_center_x
	var road_center_top: float = _road_center_future_x
	var road_left_bottom: float = road_center_bottom - _road_width * 0.5
	var road_right_bottom: float = road_center_bottom + _road_width * 0.5
	var road_left_top: float = road_center_top - _road_width * 0.5
	var road_right_top: float = road_center_top + _road_width * 0.5
	var bottom_y: float = top_left.y + viewport_size.y
	var poly := PackedVector2Array([
		Vector2(road_left_bottom, bottom_y),
		Vector2(road_right_bottom, bottom_y),
		Vector2(road_right_top, top_left.y),
		Vector2(road_left_top, top_left.y)
	])
	draw_polygon(poly, PackedColorArray([road_color, road_color, road_color, road_color]))

	var edge_width: float = 6.0
	draw_line(Vector2(road_left_bottom - edge_width, bottom_y), Vector2(road_left_top - edge_width, top_left.y), edge_color, edge_width)
	draw_line(Vector2(road_right_bottom + edge_width, bottom_y), Vector2(road_right_top + edge_width, top_left.y), edge_color, edge_width)

	var shoulder_line_width: float = 3.0
	var left_shoulder_bottom: float = road_left_bottom + _shoulder_width
	var left_shoulder_top: float = road_left_top + _shoulder_width
	var right_shoulder_bottom: float = road_right_bottom - _shoulder_width - shoulder_line_width
	var right_shoulder_top: float = road_right_top - _shoulder_width - shoulder_line_width
	draw_line(Vector2(left_shoulder_bottom, bottom_y), Vector2(left_shoulder_top, top_left.y), shoulder_color, shoulder_line_width)
	draw_line(Vector2(right_shoulder_bottom, bottom_y), Vector2(right_shoulder_top, top_left.y), shoulder_color, shoulder_line_width)

	var fence_width: float = 5.0
	var left_fence_bottom: float = road_left_bottom - _fence_offset - fence_width
	var left_fence_top: float = road_left_top - _fence_offset - fence_width
	var right_fence_bottom: float = road_right_bottom + _fence_offset
	var right_fence_top: float = road_right_top + _fence_offset
	draw_line(Vector2(left_fence_bottom, bottom_y), Vector2(left_fence_top, top_left.y), fence_color, fence_width)
	draw_line(Vector2(right_fence_bottom, bottom_y), Vector2(right_fence_top, top_left.y), fence_color, fence_width)

	var dash_spacing: float = 120.0
	var dash_length: float = 60.0
	var offset: float = fmod(-cam_pos.y, dash_spacing)
	var y: float = top_left.y - dash_length + offset
	while y < top_left.y + viewport_size.y + dash_length:
		var t: float = clamp((y - top_left.y) / viewport_size.y, 0.0, 1.0)
		var center_x: float = lerp(road_center_top, road_center_bottom, t)
		var dash_rect := Rect2(Vector2(center_x - 6.0, y), Vector2(12.0, dash_length))
		draw_rect(dash_rect, line_color)
		y += dash_spacing

func _draw_track(top_left: Vector2, viewport_size: Vector2) -> void:
	var grass_color := Color(0.1, 0.35, 0.18, 1.0)
	var road_color := Color(0.16, 0.16, 0.18, 1.0)
	var curb_red := Color(0.85, 0.15, 0.15, 1.0)
	var curb_white := Color(0.95, 0.95, 0.95, 1.0)
	draw_rect(Rect2(top_left, viewport_size), grass_color)

	var half_width: float = _track_width * 0.5
	var left := _build_offset_poly(_track_points, half_width)
	var right := _build_offset_poly(_track_points, -half_width)
	var poly := PackedVector2Array()
	for p in left:
		poly.append(p)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	var colors := PackedColorArray()
	for i in range(poly.size()):
		colors.append(road_color)
	draw_polygon(poly, colors)

	var curb_outer := _build_offset_poly(_track_points, half_width + _curb_width)
	var curb_inner: PackedVector2Array = _build_offset_poly(_track_points, half_width)
	_draw_curb(curb_inner, curb_outer, curb_red, curb_white)
	var curb_outer_r: PackedVector2Array = _build_offset_poly(_track_points, -half_width - _curb_width)
	var curb_inner_r: PackedVector2Array = _build_offset_poly(_track_points, -half_width)
	_draw_curb(curb_inner_r, curb_outer_r, curb_red, curb_white)

func _build_offset_poly(points: PackedVector2Array, offset: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var count := points.size()
	for i in range(count):
		var prev: Vector2 = points[(i - 1 + count) % count]
		var cur: Vector2 = points[i]
		var next: Vector2 = points[(i + 1) % count]
		var dir_a: Vector2 = (cur - prev).normalized()
		var dir_b: Vector2 = (next - cur).normalized()
		var normal_a: Vector2 = Vector2(-dir_a.y, dir_a.x)
		var normal_b: Vector2 = Vector2(-dir_b.y, dir_b.x)
		var normal: Vector2 = (normal_a + normal_b).normalized()
		if normal.length() < 0.01:
			normal = normal_a
		out.append(cur + normal * offset)
	return out

func _draw_curb(inner: PackedVector2Array, outer: PackedVector2Array, red: Color, white: Color) -> void:
	var count: int = min(inner.size(), outer.size())
	if count < 2:
		return
	for i in range(count):
		var a_in: Vector2 = inner[i]
		var b_in: Vector2 = inner[(i + 1) % count]
		var a_out: Vector2 = outer[i]
		var b_out: Vector2 = outer[(i + 1) % count]
		var quad: PackedVector2Array = PackedVector2Array([a_in, b_in, b_out, a_out])
		var use_red: bool = i % 2 == 0
		var color: Color = red if use_red else white
		draw_polygon(quad, PackedColorArray([color, color, color, color]))
