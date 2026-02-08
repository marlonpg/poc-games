extends Area2D
class_name FuelPickup

@export var amount := 32.0

func _ready() -> void:
	add_to_group("fuel")

func get_amount() -> float:
	return amount
