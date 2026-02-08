extends Control
class_name HUD

signal request_restart
signal request_menu

@onready var fuel_label: Label = $Stats/FuelLabel
@onready var durability_label: Label = $Stats/DurabilityLabel
@onready var distance_label: Label = $Stats/DistanceLabel
@onready var time_label: Label = $Stats/TimeLabel
@onready var speed_label: Label = $Stats/SpeedLabel
@onready var best_label: Label = $Stats/BestLabel
@onready var game_over_panel: Control = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton
@onready var menu_button: Button = $GameOverPanel/VBox/MenuButton

func _ready() -> void:
	restart_button.pressed.connect(func(): emit_signal("request_restart"))
	menu_button.pressed.connect(func(): emit_signal("request_menu"))

func update_stats(fuel: float, fuel_max: float, durability: float, durability_max: float, distance_m: float, time_s: float, speed_kmh: float, best_distance: float, best_time: float) -> void:
	fuel_label.text = "Fuel: %d/%d" % [int(round(fuel)), int(round(fuel_max))]
	durability_label.text = "Durability: %d/%d" % [int(round(durability)), int(round(durability_max))]
	distance_label.text = "Distance: %.1f km" % [distance_m / 1000.0]
	time_label.text = "Time: %.1f s" % [time_s]
	speed_label.text = "Speed: %d km/h" % [int(round(speed_kmh))]
	best_label.text = "Best: %.1f km / %.1f s" % [best_distance / 1000.0, best_time]

func show_game_over(show: bool) -> void:
	game_over_panel.visible = show
