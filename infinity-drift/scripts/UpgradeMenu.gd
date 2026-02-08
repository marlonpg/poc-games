extends Control
class_name UpgradeMenu

signal upgrade_selected(upgrade_id: String)

@onready var option_1: Button = $Panel/VBox/Option1
@onready var option_2: Button = $Panel/VBox/Option2
@onready var option_3: Button = $Panel/VBox/Option3

var _choices := []

func _ready() -> void:
	option_1.pressed.connect(func(): _emit_choice(0))
	option_2.pressed.connect(func(): _emit_choice(1))
	option_3.pressed.connect(func(): _emit_choice(2))

func show_choices(choices: Array) -> void:
	_choices = choices
	if _choices.size() >= 3:
		option_1.text = "%s\n%s" % [_choices[0]["title"], _choices[0]["desc"]]
		option_2.text = "%s\n%s" % [_choices[1]["title"], _choices[1]["desc"]]
		option_3.text = "%s\n%s" % [_choices[2]["title"], _choices[2]["desc"]]

func _emit_choice(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return
	emit_signal("upgrade_selected", _choices[index]["id"])
