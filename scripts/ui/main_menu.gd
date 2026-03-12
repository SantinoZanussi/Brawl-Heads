extends Control

@onready var btn_play     = $Screen/MarginContainer/VBoxContainer/Buttons/BtnPlay
@onready var btn_settings = $Screen/MarginContainer/VBoxContainer/Buttons/BtnSettings
@onready var btn_credits  = $Screen/MarginContainer/VBoxContainer/Buttons/BtnCredits
@onready var press_start  = $Screen/MarginContainer/VBoxContainer/PressStart
@onready var title_label  = $Screen/MarginContainer/VBoxContainer/TitleArea/Title
@onready var anim         = $AnimationPlayer

func _ready():
	btn_play.pressed.connect(_on_play_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_credits.pressed.connect(_on_credits_pressed)
	
	# Animación de entrada
	anim.play("intro")
	
	# Parpadeo de PressStart
	_blink_press_start()

func _blink_press_start():
	while true:
		press_start.visible = !press_start.visible
		await get_tree().create_timer(0.5).timeout

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/LobbyMenu.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/SettingsMenu.tscn")

func _on_credits_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/CreditsMenu.tscn")
