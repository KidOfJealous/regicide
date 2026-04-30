extends Control
class_name Lobby

# UI节点引用
@onready var player_name_edit:LineEdit = $VBoxContainer/PlayerNameEdit
@onready var room_list:ItemList = $VBoxContainer/HBoxContainer/RoomListContainer/RoomList
@onready var refresh_btn:Button = $VBoxContainer/HBoxContainer/RoomListContainer/RefreshBtn
@onready var join_btn:Button = $VBoxContainer/HBoxContainer/RoomListContainer/JoinBtn
@onready var direct_join_container:HBoxContainer = $VBoxContainer/HBoxContainer/DirectJoinContainer
@onready var ip_edit:LineEdit = $VBoxContainer/HBoxContainer/DirectJoinContainer/IpEdit
@onready var direct_join_btn:Button = $VBoxContainer/HBoxContainer/DirectJoinContainer/DirectJoinBtn

@onready var create_btn:Button = $VBoxContainer/CreateBtn
@onready var start_single_btn:Button = $VBoxContainer/StartSingleBtn

# 创建房间面板
@onready var create_panel:Control = $CreateRoomPanel
@onready var create_room_name:LineEdit = $CreateRoomPanel/VBoxContainer/RoomNameEdit
@onready var create_max_players:OptionButton = $CreateRoomPanel/VBoxContainer/MaxPlayersOption
@onready var create_port:SpinBox = $CreateRoomPanel/VBoxContainer/PortSpinBox
@onready var create_confirm_btn:Button = $CreateRoomPanel/VBoxContainer/ConfirmBtn
@onready var create_cancel_btn:Button = $CreateRoomPanel/VBoxContainer/CancelBtn

# 等待房间面板
@onready var waiting_panel:Control = $WaitingRoomPanel
@onready var waiting_room_name:Label = $WaitingRoomPanel/VBoxContainer/RoomNameLabel
@onready var waiting_player_list:ItemList = $WaitingRoomPanel/VBoxContainer/PlayerList
@onready var waiting_status:Label = $WaitingRoomPanel/VBoxContainer/StatusLabel
@onready var waiting_start_btn:Button = $WaitingRoomPanel/VBoxContainer/StartGameBtn
@onready var waiting_leave_btn:Button = $WaitingRoomPanel/VBoxContainer/LeaveBtn

# 网络管理器
var network_mgr: NetworkManager = null

# 状态
var current_state: String = "main"  # main, create, waiting
var selected_room_index: int = -1

func _ready() -> void:
	# 获取网络管理器
	network_mgr = get_node_or_null("/root/NetworkManager")
	if not network_mgr:
		network_mgr = preload("res://scenes/network_manager.tscn").instantiate()
		get_tree().root.add_child(network_mgr)
	
	# 连接信号
	network_mgr.room_discovered.connect(_on_room_discovered)
	network_mgr.player_connected.connect(_on_player_connected)
	network_mgr.player_disconnected.connect(_on_player_disconnected)
	network_mgr.connection_failed.connect(_on_connection_failed)
	network_mgr.game_started.connect(_on_game_started)
	
	# 初始化UI
	_init_ui()
	_show_main_panel()
	
	# 设置默认玩家名
	player_name_edit.text = "Player" + str(randi() % 1000)
	
	# 开始房间发现
	network_mgr.start_room_discovery()

func _init_ui() -> void:
	# 初始化最大玩家数选项
	create_max_players.clear()
	for i in range(2, 5):
		create_max_players.add_item(str(i) + "人", i)
	create_max_players.selected = 2  # 默认4人
	
	# 默认端口
	create_port.value = NetworkManager.DEFAULT_PORT
	
	# 默认IP提示
	ip_edit.placeholder_text = "输入主机IP地址"

func _process(delta: float) -> void:
	# 更新等待面板玩家列表
	if current_state == "waiting" and network_mgr.is_connected:
		_update_waiting_player_list()

# ==================== 面板切换 ====================

func _show_main_panel() -> void:
	current_state = "main"
	create_panel.visible = false
	waiting_panel.visible = false
	
func _show_create_panel() -> void:
	current_state = "create"
	create_panel.visible = true
	waiting_panel.visible = false
	create_room_name.text = player_name_edit.text + "的房间"

func _show_waiting_panel() -> void:
	current_state = "waiting"
	create_panel.visible = false
	waiting_panel.visible = true
	_update_waiting_panel()

# ==================== 主面板按钮 ====================

func _on_refresh_btn_pressed() -> void:
	# 清空列表重新发现
	room_list.clear()
	network_mgr.discovered_rooms.clear()
	network_mgr.start_room_discovery()

func _on_join_btn_pressed() -> void:
	if selected_room_index < 0 or selected_room_index >= network_mgr.discovered_rooms.size():
		return
	
	var room_info = network_mgr.discovered_rooms[selected_room_index]
	var player_name = player_name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	
	network_mgr.set_player_name(player_name)
	var success = network_mgr.join_room(room_info["ip"], room_info["port"])
	if success:
		waiting_status.text = "正在连接..."
		_show_waiting_panel()

func _on_direct_join_btn_pressed() -> void:
	var ip = ip_edit.text.strip_edges()
	if ip.is_empty():
		return
	
	var player_name = player_name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	
	network_mgr.set_player_name(player_name)
	var success = network_mgr.join_room(ip, int(create_port.value))
	if success:
		waiting_status.text = "正在连接..."
		_show_waiting_panel()

func _on_create_btn_pressed() -> void:
	_show_create_panel()

func _on_start_single_btn_pressed() -> void:
	# 单人模式直接开始游戏
	network_mgr.player_count = 1
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")

# ==================== 房间列表 ====================

func _on_room_discovered(room_info: Dictionary) -> void:
	# 添加到列表
	var display_text = room_info["name"] + " (" + str(room_info["current_players"]) + "/" + str(room_info["max_players"]) + ")"
	room_list.add_item(display_text)

func _on_room_list_item_selected(index: int) -> void:
	selected_room_index = index
	join_btn.disabled = false

func _on_room_list_empty_clicked() -> void:
	selected_room_index = -1
	join_btn.disabled = true

# ==================== 创建房间面板 ====================

func _on_create_confirm_btn_pressed() -> void:
	var room_name_arg = create_room_name.text.strip_edges()
	if room_name_arg.is_empty():
		room_name_arg = player_name_edit.text + "的房间"
	
	var max_players = create_max_players.get_selected_id()
	var port = int(create_port.value)
	
	# 设置玩家名并创建房间
	var player_name = player_name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	network_mgr.set_player_name(player_name)
	
	var success = network_mgr.create_room(room_name_arg, max_players, port)
	if success:
		_show_waiting_panel()
	else:
		waiting_status.text = "创建房间失败"

func _on_create_cancel_btn_pressed() -> void:
	_show_main_panel()

# ==================== 等待房间面板 ====================

func _update_waiting_panel() -> void:
	if network_mgr.is_host:
		waiting_room_name.text = network_mgr.room_name
	else:
		waiting_room_name.text = "已加入房间"
	
	_update_waiting_player_list()
	_update_start_button()

func _update_waiting_player_list() -> void:
	waiting_player_list.clear()
	var players = network_mgr.get_all_players()
	for peer_id in players:
		var name = players[peer_id]
		var prefix = ""
		if peer_id == network_mgr.host_peer_id:
			prefix = "[主机] "
		if peer_id == network_mgr.my_peer_id:
			prefix += "[你] "
		waiting_player_list.add_item(prefix + name)
	
	if network_mgr.is_connected:
		waiting_status.text = "已连接，等待玩家加入..."
	else:
		waiting_status.text = "正在连接..."

func _update_start_button() -> void:
	# 只有主机可以开始游戏
	waiting_start_btn.visible = network_mgr.is_host
	if network_mgr.is_host:
		waiting_start_btn.disabled = not network_mgr.can_start_game()
		if network_mgr.can_start_game():
			waiting_status.text = "可以开始游戏！"
		else:
			waiting_status.text = "需要至少2名玩家才能开始"

func _on_player_connected(peer_id: int, player_name: String) -> void:
	if current_state == "waiting":
		_update_waiting_panel()

func _on_player_disconnected(peer_id: int) -> void:
	if current_state == "waiting":
		_update_waiting_panel()

func _on_start_game_btn_pressed() -> void:
	if network_mgr.can_start_game():
		network_mgr.start_game()

func _on_leave_btn_pressed() -> void:
	if network_mgr.is_host:
		network_mgr.close_room()
	else:
		network_mgr.disconnect_from_room()
	network_mgr.start_room_discovery()
	_show_main_panel()

func _on_connection_failed() -> void:
	waiting_status.text = "连接失败！"
	# 3秒后返回主面板
	await get_tree().create_timer(3.0).timeout
	_show_main_panel()
	network_mgr.start_room_discovery()

func _on_game_started() -> void:
	# 设置玩家数量
	network_mgr.player_count = network_mgr.get_player_count()
	# 切换到游戏场景
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")