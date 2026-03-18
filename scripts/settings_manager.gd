extends Node

const SAVE_PATH := "user://settings.cfg"
const SETTINGS_VERSION := 2
var config := ConfigFile.new()

var settings := {
	"display": {
		"fullscreen": true,
		"resolution": Vector2i(1280, 720),
		"vsync": true,
		"fps_limit": 60,
	},
	"audio": {
		"master": 1.0,
		"music":  1.0,
		"sfx":    1.0,
	},
}

func _ready() -> void:
	load_settings()
	apply_all()

func apply_all() -> void:
	apply_display()
	apply_audio()

func apply_display() -> void:
	var d: Dictionary = settings["display"]
	print("=== apply_display ===")
	print("fullscreen: ", d["fullscreen"])
	print("resolution: ", d["resolution"])
	print("vsync: ", d["vsync"])
	print("fps_limit: ", d["fps_limit"])
	if d["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(d["resolution"])
	if d["vsync"]:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = d["fps_limit"]
	print("Modo ventana actual: ", DisplayServer.window_get_mode())

func apply_audio() -> void:
	var a: Dictionary = settings["audio"]
	print("=== apply_audio ===")
	print("master: ", a["master"], " bus index: ", AudioServer.get_bus_index("Master"))
	print("music:  ", a["music"],  " bus index: ", AudioServer.get_bus_index("Music"))
	print("sfx:    ", a["sfx"],    " bus index: ", AudioServer.get_bus_index("SFX"))
	_set_bus_volume("Master", a["master"])
	_set_bus_volume("Music",  a["music"])
	_set_bus_volume("SFX",    a["sfx"])

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("Bus de audio no encontrado: " + bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func save_settings() -> void:
	config.set_value("meta", "version", SETTINGS_VERSION)
	for section in settings.keys():
		for key in settings[section].keys():
			config.set_value(section, key, settings[section][key])
	config.save(SAVE_PATH)

func load_settings() -> void:
	if config.load(SAVE_PATH) != OK:
		return
	var version: int = config.get_value("meta", "version", 0)
	if version != SETTINGS_VERSION:
		push_warning("Settings desactualizados (v%d), usando defaults." % version)
		return
	for section in settings.keys():
		for key in settings[section].keys():
			if config.has_section_key(section, key):
				settings[section][key] = config.get_value(section, key)
