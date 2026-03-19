extends HBoxContainer

signal rebind_requested(action: String, row: Node)

var action_name: String = ""
var listening: bool = false

@onready var label: Label   = $Label
@onready var btn:   Button  = $Button

func setup(action: String, display_name: String) -> void:
	action_name = action
	label.text  = display_name
	_refresh_key()

func _refresh_key() -> void:
	btn.text = SettingsManager.get_action_key(action_name)

func _on_button_pressed() -> void:
	if listening:
		return
	listening = true
	btn.text = "..."
	rebind_requested.emit(action_name, self)

func set_listening(on: bool) -> void:
	listening = on
	if not on:
		_refresh_key()
