extends Control

# ── VISTAS ────────────────────────────────────────────────────
@onready var view_main:   Control = $Screen/MarginContainer/VBoxContainer/ViewMain
@onready var view_create: Control = $Screen/MarginContainer/VBoxContainer/ViewCreate
@onready var view_browse: Control = $Screen/MarginContainer/VBoxContainer/ViewBrowse

# ── CREAR SALA ────────────────────────────────────────────────
@onready var input_room_name: LineEdit    = $Screen/MarginContainer/VBoxContainer/ViewCreate/RoomName
@onready var input_password:  LineEdit    = $Screen/MarginContainer/VBoxContainer/ViewCreate/Password
@onready var opt_max_players: OptionButton = $Screen/MarginContainer/VBoxContainer/ViewCreate/MarginContainer/Label/MaxPlayers
@onready var btn_host:        Button      = $Screen/MarginContainer/VBoxContainer/ViewCreate/BtnHost
@onready var btn_back_create: Button      = $Screen/MarginContainer/VBoxContainer/ViewCreate/BtnBack

# ── BUSCAR SALA ───────────────────────────────────────────────
@onready var room_list:        VBoxContainer = $Screen/MarginContainer/VBoxContainer/ViewBrowse/RoomList
@onready var input_join_pass:  LineEdit      = $Screen/MarginContainer/VBoxContainer/ViewBrowse/JoinPassword
@onready var btn_join:         Button        = $Screen/MarginContainer/VBoxContainer/ViewBrowse/BtnJoin
@onready var btn_refresh:      Button        = $Screen/MarginContainer/VBoxContainer/ViewBrowse/BtnRefresh
@onready var btn_back_browse:  Button        = $Screen/MarginContainer/VBoxContainer/ViewBrowse/BtnBack
@onready var lbl_no_rooms:     Label         = $Screen/MarginContainer/VBoxContainer/ViewBrowse/LblNoRooms

# ── MENÚ PRINCIPAL ────────────────────────────────────────────
@onready var btn_create: Button = $Screen/MarginContainer/VBoxContainer/ViewMain/BtnCreate
@onready var btn_browse: Button = $Screen/MarginContainer/VBoxContainer/ViewMain/BtnBrowse
@onready var btn_back:   Button = $Screen/MarginContainer/VBoxContainer/ViewMain/BtnBack

var _found_rooms:   Dictionary = {}  # ip → info
var _selected_room: Dictionary = {}

func _ready() -> void:
	_show_view("main")
	_connect_signals()

	opt_max_players.clear()
	for n in [2, 3, 4]:
		opt_max_players.add_item("%d jugadores" % n, n)
	opt_max_players.selected = 1  # default: 3 jugadores

	NetworkManager.server_found.connect(_on_server_found)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _connect_signals() -> void:
	btn_create.pressed.connect(func(): _show_view("create"))
	btn_browse.pressed.connect(_on_browse_pressed)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))

	btn_host.pressed.connect(_on_host_pressed)
	btn_back_create.pressed.connect(func(): _show_view("main"))

	btn_join.pressed.connect(_on_join_pressed)
	btn_refresh.pressed.connect(_on_refresh_pressed)
	btn_back_browse.pressed.connect(func():
		NetworkManager._stop_discovery()
		_show_view("main")
	)

# ── VISTAS ────────────────────────────────────────────────────

func _show_view(which: String) -> void:
	view_main.visible   = which == "main"
	view_create.visible = which == "create"
	view_browse.visible = which == "browse"

# ── CREAR ─────────────────────────────────────────────────────

func _on_host_pressed() -> void:
	var name_val := input_room_name.text.strip_edges()
	if name_val.is_empty():
		name_val = "Sala de %s" % OS.get_environment("USERNAME")

	var pass_val := input_password.text
	var max_p:  int = opt_max_players.get_item_id(opt_max_players.selected)

	NetworkManager.create_room(name_val, pass_val, max_p)
	get_tree().change_scene_to_file("res://scenes/ui/LobbyMenu.tscn")

# ── BUSCAR ────────────────────────────────────────────────────

func _on_browse_pressed() -> void:
	_show_view("browse")
	_clear_room_list()
	NetworkManager.start_discovery()

func _on_refresh_pressed() -> void:
	_clear_room_list()
	NetworkManager._stop_discovery()
	NetworkManager.start_discovery()

func _on_server_found(info: Dictionary) -> void:
	var ip: String = info.get("host", "")
	if ip.is_empty() or _found_rooms.has(ip):
		return
	_found_rooms[ip] = info
	_add_room_to_list(ip, info)
	lbl_no_rooms.visible = false

func _add_room_to_list(ip: String, info: Dictionary) -> void:
	var btn := Button.new()
	var has_pass: bool = not (info.get("password", "") as String).is_empty()
	btn.text = "%s  [%s]  %s" % [
		info.get("name", "???"),
		ip,
		"🔒" if has_pass else "🔓"
	]
	btn.pressed.connect(func(): _select_room(ip, info))
	room_list.add_child(btn)

func _select_room(ip: String, info: Dictionary) -> void:
	_selected_room = info
	_selected_room["host"] = ip
	# Mostrar / ocultar campo de contraseña
	var has_pass: bool = not (info.get("password", "") as String).is_empty()
	input_join_pass.visible = has_pass
	btn_join.disabled = false

func _on_join_pressed() -> void:
	if _selected_room.is_empty():
		return
	var ip: String    = _selected_room.get("host", "")
	var password: String = input_join_pass.text
	# Pasamos la contraseña al room_info antes de conectar para la validación
	NetworkManager.room_info = _selected_room
	NetworkManager.join_room(ip, password)
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")

func _on_connection_failed() -> void:
	btn_join.text = "Error — reintentá"

func _clear_room_list() -> void:
	_found_rooms.clear()
	_selected_room.clear()
	for child in room_list.get_children():
		child.queue_free()
	lbl_no_rooms.visible = true
	input_join_pass.visible = false
	btn_join.disabled = true
