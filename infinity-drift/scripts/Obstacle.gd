extends Area2D
class_name Obstacle

@export var damage := 12.0

func _ready() -> void:
	add_to_group("hazard")

func get_damage() -> float:
	return damage

func on_hit() -> void:
	queue_free()
