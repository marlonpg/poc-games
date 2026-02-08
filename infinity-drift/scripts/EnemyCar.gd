extends Area2D
class_name EnemyCar

@export var speed := 160.0
@export var damage := 18.0

func _ready() -> void:
	add_to_group("hazard")

func _physics_process(delta: float) -> void:
	position.y += speed * delta

func set_speed(value: float) -> void:
	speed = value

func get_damage() -> float:
	return damage

func on_hit() -> void:
	queue_free()
