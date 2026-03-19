extends Control

# ── PANTALLA ──────────────────────────────────────────────────
@onready var opt_resolution:   OptionButton = $Screen/MarginContainer/VBoxContainer/TabContainer/Pantalla/MarginContainer/resolution_label/resolution
@onready var check_fullscreen: CheckButton  = $Screen/MarginContainer/VBoxContainer/TabContainer/Pantalla/MarginContainer2/fullscreen
@onready var check_vsync:      CheckButton  = $Screen/MarginContainer/VBoxContainer/TabContainer/Pantalla/MarginContainer3/vsync
@onready var opt_fps:          OptionButton = $Screen/MarginContainer/VBoxContainer/TabContainer/Pantalla/MarginContainer4/fps_limit_label/fps_limit

# ── AUDIO ─────────────────────────────────────────────────────
@onready var slider_master: HSlider = $Screen/MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer/vol_master_label/vol_master
@onready var slider_music:  HSlider = $Screen/MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer2/vol_music_label/vol_music
@onready var slider_sfx:    HSlider = $Screen/MarginContainer/VBoxContainer/TabContainer/Audio/MarginContainer3/vol_sfx_label/vol_sfx

# ── BOTONES ───────────────────────────────────────────────────
@onready var btn_aplicar: Button = $Screen/MarginContainer/VBoxContainer/Buttons/BtnApply
@onready var btn_volver:  Button = $Screen/MarginContainer/VBoxContainer/Buttons/BtnBack

# ── CONTROLES ───────────────────────────────────────────────────
@onready var bindings_container: Node = $Screen/MarginContainer/VBoxContainer/TabContainer/Controles

const RESOLUTIONS := [
	Vector2i(1920, 1080),
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(800, 600),
]

const ACTIONS := {
	"Mover a la izquierda": "p1_left",
	"Mover a la derecha":   "p1_right",
	"Saltar":          "p1_jump",
	"Agacharse":       "p1_duck",
	"Disparar":        "p1_shoot",
	"Agarrar":         "p1_pickup",
	"Apuntar arriba":  "p1_aim_up",
}

var _active_btn: Button = null
var _active_action: String = ""

const FPS_OPTIONS := [30, 60]  # 0 = sin límite
const FPS_LABELS  := ["30", "60"]

func _ready() -> void:
	_build_option_lists()
	_load_into_ui()
	_build_bindings()
	_connect_signals()
	set_process_unhandled_input(false)

func _build_bindings() -> void:
	for child in bindings_container.get_children():
		child.queue_free()

	# Cargás la fuente que ya usás en el resto del juego
	var font: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

	for display_name in ACTIONS.keys():
		var action: String = ACTIONS[display_name]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# ── LABEL ──────────────────────────────────────
		var lbl := Label.new()
		lbl.text = display_name
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 12)

		lbl.add_theme_color_override("font_color", Color("#FFFFFF"))

		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		# ── BUTTON ─────────────────────────────────────
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(90, 30)
		btn.text = SettingsManager.get_action_key(action)	

		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 12)

		btn.add_theme_color_override("font_color",         Color("#FFD700"))
		btn.add_theme_color_override("font_hover_color",   Color("#FFFFFF"))
		btn.add_theme_color_override("font_pressed_color", Color("#AAAAAA"))

		var style := StyleBoxFlat.new()
		style.bg_color          = Color("#1a2a4a")
		style.border_color      = Color("#FFD700")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)

		var style_hover := StyleBoxFlat.new()
		style_hover.bg_color     = Color("#2a3a6a")
		style_hover.border_color = Color("#FFD700")
		style_hover.set_border_width_all(1)
		style_hover.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", style_hover)

		btn.pressed.connect(_on_bind_btn_pressed.bind(action, btn))

		row.add_child(lbl)
		row.add_child(btn)
		bindings_container.add_child(row)

func _on_bind_btn_pressed(action: String, btn: Button) -> void:
	if _active_btn != null:
		_active_btn.text = SettingsManager.get_action_key(_active_action)
	_active_btn    = btn
	_active_action = action
	btn.text       = "..."
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if _active_btn == null:
		return
	if not event is InputEventKey or not event.pressed:
		return
	if event.physical_keycode == KEY_ESCAPE:
		_active_btn.text = SettingsManager.get_action_key(_active_action)
	else:
		SettingsManager.rebind_action(_active_action, event as InputEventKey)
		_active_btn.text = SettingsManager.get_action_key(_active_action)
	_active_btn    = null
	_active_action = ""
	set_process_unhandled_input(false)
	get_viewport().set_input_as_handled()
func _build_option_lists() -> void:
	opt_resolution.clear()
	for r in RESOLUTIONS:
		opt_resolution.add_item("%d × %d" % [r.x, r.y])

	opt_fps.clear()
	for label in FPS_LABELS:
		opt_fps.add_item(label)

func _load_into_ui() -> void:
	var s: Dictionary = SettingsManager.settings

	# Bloquear señales para que asignar valores no dispare los callbacks
	opt_resolution.set_block_signals(true)
	check_fullscreen.set_block_signals(true)
	check_vsync.set_block_signals(true)
	opt_fps.set_block_signals(true)
	slider_master.set_block_signals(true)
	slider_music.set_block_signals(true)
	slider_sfx.set_block_signals(true)

	var res_idx := RESOLUTIONS.find(s["display"]["resolution"])
	opt_resolution.selected         = max(res_idx, 0)
	check_fullscreen.button_pressed = s["display"]["fullscreen"]
	check_vsync.button_pressed      = s["display"]["vsync"]
	var fps_idx := FPS_OPTIONS.find(s["display"]["fps_limit"])
	opt_fps.selected = max(fps_idx, 0)

	slider_master.value = s["audio"]["master"] * 100.0
	slider_music.value  = s["audio"]["music"]  * 100.0
	slider_sfx.value    = s["audio"]["sfx"]    * 100.0

	# Desbloquear
	opt_resolution.set_block_signals(false)
	check_fullscreen.set_block_signals(false)
	check_vsync.set_block_signals(false)
	opt_fps.set_block_signals(false)
	slider_master.set_block_signals(false)
	slider_music.set_block_signals(false)
	slider_sfx.set_block_signals(false)

func _connect_signals() -> void:
	# Pantalla
	opt_resolution.item_selected.connect(_on_resolution_selected)
	check_fullscreen.toggled.connect(_on_fullscreen_toggled)
	check_vsync.toggled.connect(_on_vsync_toggled)
	opt_fps.item_selected.connect(_on_fps_selected)

	# Audio
	slider_master.value_changed.connect(_on_master_changed)
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)

	# Botones
	btn_aplicar.pressed.connect(_on_aplicar)
	btn_volver.pressed.connect(_on_volver)

# ── SEÑALES PANTALLA ──────────────────────────────────────────

func _on_resolution_selected(idx: int) -> void:
	SettingsManager.settings["display"]["resolution"] = RESOLUTIONS[idx]

func _on_fullscreen_toggled(on: bool) -> void:
	SettingsManager.settings["display"]["fullscreen"] = on

func _on_vsync_toggled(on: bool) -> void:
	SettingsManager.settings["display"]["vsync"] = on

func _on_fps_selected(idx: int) -> void:
	SettingsManager.settings["display"]["fps_limit"] = FPS_OPTIONS[idx]

# ── SEÑALES AUDIO ─────────────────────────────────────────────

func _on_master_changed(value: float) -> void:
	SettingsManager.settings["audio"]["master"] = value / 100.0
	SettingsManager.apply_audio()  # preview inmediato

func _on_music_changed(value: float) -> void:
	SettingsManager.settings["audio"]["music"] = value / 100.0
	SettingsManager.apply_audio()

func _on_sfx_changed(value: float) -> void:
	SettingsManager.settings["audio"]["sfx"] = value / 100.0
	SettingsManager.apply_audio()

# ── BOTONES ───────────────────────────────────────────────────

func _on_aplicar() -> void:
	SettingsManager.apply_all()
	SettingsManager.save_settings()

func _on_volver() -> void:
	SettingsManager.load_settings()
	SettingsManager.apply_all()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
