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

const RESOLUTIONS := [
	Vector2i(1920, 1080),
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(800, 600),
]
const FPS_OPTIONS := [30, 60, 120, 0]  # 0 = sin límite
const FPS_LABELS  := ["30", "60", "120", "Sin límite"]

func _ready() -> void:
	_build_option_lists()
	_load_into_ui()
	_connect_signals()

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
