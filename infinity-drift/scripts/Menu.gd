extends Control
class_name Menu

@onready var best_label: Label = $Panel/BestLabel
@onready var start_button: Button = $Panel/StartButton
@onready var settings_button: Button = $Panel/SettingsButton
@onready var quit_button: Button = $Panel/QuitButton
@onready var settings_panel: Control = $SettingsPanel

func _ready() -> void:
	var stats := SaveManager.load_stats()
	best_label.text = "Best: %.1f km / %.1f s" % [float(stats.get("best_distance", 0.0)) / 1000.0, float(stats.get("best_time", 0.0))]
	settings_panel.hide()
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	if settings_panel.has_signal("settings_closed"):
		settings_panel.connect("settings_closed", Callable(self, "_on_settings_close"))

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_pressed() -> void:
	settings_panel.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_close() -> void:
	settings_panel.hide()
