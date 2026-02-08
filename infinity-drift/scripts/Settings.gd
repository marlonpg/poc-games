extends Control
class_name Settings

signal settings_closed

@onready var audio_toggle: CheckButton = $Panel/VBox/AudioToggle
@onready var sfx_toggle: CheckButton = $Panel/VBox/SfxToggle
@onready var close_button: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	var settings := SaveManager.load_settings()
	audio_toggle.button_pressed = bool(settings.get("audio_enabled", true))
	sfx_toggle.button_pressed = bool(settings.get("sfx_enabled", true))
	audio_toggle.toggled.connect(_on_toggle)
	sfx_toggle.toggled.connect(_on_toggle)
	close_button.pressed.connect(_on_close_pressed)

func _on_toggle(pressed: bool) -> void:
	SaveManager.save_settings(audio_toggle.button_pressed, sfx_toggle.button_pressed)

func _on_close_pressed() -> void:
	emit_signal("settings_closed")
