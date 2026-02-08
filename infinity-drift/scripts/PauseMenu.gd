extends Control
class_name PauseMenu

signal request_resume
signal request_restart
signal request_menu

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_resume_pressed() -> void:
	emit_signal("request_resume")

func _on_restart_pressed() -> void:
	emit_signal("request_restart")

func _on_menu_pressed() -> void:
	emit_signal("request_menu")
