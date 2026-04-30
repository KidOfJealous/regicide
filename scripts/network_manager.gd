extends Node
# NetworkManager - 网络管理器（自动加载单例，无需class_name）

# 信号
signal player_connected(peer_id: int, player_name: String)
signal player_disconnected(peer_id: int)
signal room_discovered(room_info: Dictionary)
signal connection_failed()
signal game_started()
signal host_disconnected()  # 主机断开通知

# 常量
const DEFAULT_PORT: int = 8920
const BROADCAST_PORT: int = 8921
const MAX_PLAYERS: int = 4
const DISCOVERY_INTERVAL: float = 1.0  # 广播间隔

# 状态
var is_host: bool = false
var is_connected: bool = false
var my_peer_id: int = 0
var my_player_name: String = "Player"
var host_peer_id: int = 0
# 用于游戏配置的玩家数量（由lobby设置）
var player_count: int = 1

# 房间信息
var room_name: String = ""
var room_max_players: int = 4
var current_player_count: int = 0

# 玩家列表（peer_id -> player_name）
var players: Dictionary = {}

# UDP广播发现
var discovery_socket: PacketPeerUDP = null
var discovery_timer: float = 0.0
var discovered_rooms: Array[Dictionary] = []

# ENet peer
var peer: ENetMultiplayerPeer = null

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _process(delta: float) -> void:
	# 处理UDP广播发现
	if discovery_socket and not is_host:
		_update_room_discovery(delta)
	
	# 处理网络连接状态
	if peer:
		_poll_network()

# ==================== 房间创建（主机） ====================

func create_room(room_name_arg: String, max_players: int = 4, port: int = DEFAULT_PORT) -> bool:
	if is_connected:
		push_error("Already connected to a room")
		return false
	
	if max_players < 2 or max_players > MAX_PLAYERS:
		push_error("Invalid max players: " + str(max_players))
		return false
	
	# 创建ENet服务器
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, max_players)
	if err != OK:
		push_error("Failed to create server: " + str(err))
		return false
	
	multiplayer.multiplayer_peer = peer
	is_host = true
	is_connected = true
	host_peer_id = 1
	my_peer_id = 1
	
	# 设置房间信息
	room_name = room_name_arg
	room_max_players = max_players
	current_player_count = 1
	
	# 注册自己
	players[my_peer_id] = my_player_name
	
	# 启动广播
	_start_broadcast()
	
	print("Room created: " + room_name + " (max: " + str(max_players) + ")")
	return true

func close_room() -> void:
	if not is_host:
		return
	
	_stop_broadcast()
	
	if peer:
		peer.close()
		peer = null
	
	is_host = false
	is_connected = false
	players.clear()
	current_player_count = 0
	print("Room closed")

# ==================== 房间连接（客户端） ====================

func join_room(ip: String, port: int = DEFAULT_PORT) -> bool:
	if is_connected:
		push_error("Already connected to a room")
		return false
	
	# 创建ENet客户端
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Failed to create client: " + str(err))
		return false
	
	multiplayer.multiplayer_peer = peer
	is_host = false
	is_connected = false  # 等待连接成功信号
	
	print("Connecting to " + ip + ":" + str(port))
	return true

func disconnect_from_room() -> void:
	if peer:
		peer.close()
		peer = null
	
	is_host = false
	is_connected = false
	players.clear()
	my_peer_id = 0
	host_peer_id = 0
	print("Disconnected from room")

# ==================== 局域网房间发现 ====================

func start_room_discovery() -> void:
	if is_host:
		return  # 主机不需要发现
	
	if discovery_socket:
		discovery_socket.close()
	
	discovery_socket = PacketPeerUDP.new()
	var err = discovery_socket.bind(BROADCAST_PORT)
	if err != OK:
		push_error("Failed to bind discovery socket: " + str(err))
		discovery_socket = null
		return
	
	discovered_rooms.clear()
	discovery_timer = 0.0
	print("Started room discovery on port " + str(BROADCAST_PORT))

func stop_room_discovery() -> void:
	if discovery_socket:
		discovery_socket.close()
		discovery_socket = null
	discovered_rooms.clear()

func _update_room_discovery(delta: float) -> void:
	discovery_timer += delta
	
	# 定期检查接收到的广播
	if discovery_socket.get_available_packet_count() > 0:
		var packet = discovery_socket.get_packet()
		var room_info = _parse_broadcast_packet(packet)
		if room_info.size() > 0:
			# 检查是否已存在
			var existing = false
			for room in discovered_rooms:
				if room["ip"] == room_info["ip"] and room["name"] == room_info["name"]:
					existing = true
					break
			if not existing:
				discovered_rooms.append(room_info)
				room_discovered.emit(room_info)
				print("Discovered room: " + room_info["name"] + " at " + room_info["ip"])

func _start_broadcast() -> void:
	# 主机广播房间信息
	discovery_socket = PacketPeerUDP.new()
	discovery_socket.set_broadcast_enabled(true)
	var err = discovery_socket.bind(BROADCAST_PORT + 1)
	if err != OK:
		push_error("Failed to bind broadcast socket: " + str(err))
		return
	print("Started broadcasting room info")

func _stop_broadcast() -> void:
	if discovery_socket:
		discovery_socket.close()
		discovery_socket = null

func _poll_network() -> void:
	# 主机定时广播
	if is_host and discovery_socket:
		discovery_timer += 0.016  # 约60fps
		if discovery_timer >= DISCOVERY_INTERVAL:
			discovery_timer = 0.0
			_broadcast_room_info()
	
	# 检查连接状态
	var status = peer.get_connection_status()
	if status == ENetMultiplayerPeer.CONNECTION_CONNECTED:
		if not is_connected and not is_host:
			# 客户端刚连接成功，会收到connected_to_server信号
			pass
	elif status == ENetMultiplayerPeer.CONNECTION_DISCONNECTED:
		if is_connected:
			# 连接断开
			if not is_host:
				# 客户端：主机断开
				host_disconnected.emit()
			disconnect_from_room()

func _broadcast_room_info() -> void:
	var info = {
		"name": room_name,
		"max_players": room_max_players,
		"current_players": current_player_count,
		"ip": _get_local_ip(),
		"port": DEFAULT_PORT
	}
	var packet = JSON.stringify(info).to_utf8_buffer()
	# 广播到局域网所有地址
	var broadcast_ip = "255.255.255.255"
	discovery_socket.set_dest_address(broadcast_ip, BROADCAST_PORT)
	discovery_socket.put_packet(packet)

func _parse_broadcast_packet(packet: PackedByteArray) -> Dictionary:
	var text = packet.get_string_from_utf8()
	if text.is_empty():
		return {}
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		return {}
	
	var data = json.data
	if not data is Dictionary:
		return {}
	
	# 验证必需字段存在且类型正确
	if not data.has("name") or not data["name"] is String:
		return {}
	if not data.has("ip") or not data["ip"] is String:
		return {}
	if not data.has("port") or not data["port"] is int:
		return {}
	if not data.has("max_players") or not data["max_players"] is int:
		return {}
	if not data.has("current_players") or not data["current_players"] is int:
		return {}
	
	# 验证数值范围
	if data["max_players"] < 2 or data["max_players"] > MAX_PLAYERS:
		return {}
	if data["current_players"] < 1 or data["current_players"] > data["max_players"]:
		return {}
	if data["port"] < 1 or data["port"] > 65535:
		return {}
	
	return data

func _get_local_ip() -> String:
	# 获取本机局域网IP
	var addresses = IP.get_local_addresses()
	for addr in addresses:
		# 过滤掉回环地址和不可用地址
		if not addr.begins_with("127.") and not addr.begins_with("0.") and not addr.begins_with("169.254."):
			return addr
	return "127.0.0.1"

# ==================== 玩家管理 ====================

func set_player_name(name_arg: String) -> void:
	my_player_name = name_arg
	if is_connected:
		_sync_player_name.rpc(my_player_name)

@rpc("any_peer", "call_local")
func _sync_player_name(name_arg: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = my_peer_id  # 本地调用（主机自己）
	
	# 安全验证：只能修改自己的名字，主机可以修改所有
	if sender_id != my_peer_id and not is_host:
		return  # 拒绝修改他人名字
	
	players[sender_id] = name_arg
	player_connected.emit(sender_id, name_arg)
	print("Player registered: " + name_arg + " (id: " + str(sender_id) + ")")

func get_player_name(peer_id_arg: int) -> String:
	if peer_id_arg in players:
		return players[peer_id_arg]
	return "Unknown"

func get_all_players() -> Dictionary:
	return players

func get_player_count() -> int:
	return players.size()

# ==================== 网络事件回调 ====================

func _on_peer_connected(peer_id_arg: int) -> void:
	if is_host:
		current_player_count += 1
		# 发送当前玩家列表给新玩家
		_send_player_list.rpc_id(peer_id_arg, players)
	print("Peer connected: " + str(peer_id_arg))

@rpc("authority", "call_local")
func _send_player_list(player_list: Dictionary) -> void:
	players = player_list
	print("Received player list: " + str(players.size()) + " players")

func _on_peer_disconnected(peer_id_arg: int) -> void:
	if peer_id_arg in players:
		var name = players[peer_id_arg]
		players.erase(peer_id_arg)
		player_disconnected.emit(peer_id_arg)
		print("Player disconnected: " + name)
	
	if is_host:
		current_player_count -= 1

func _on_connected_to_server() -> void:
	is_connected = true
	my_peer_id = multiplayer.get_unique_id()
	host_peer_id = 1
	print("Connected to server as peer " + str(my_peer_id))
	# 发送自己的名字给主机
	_sync_player_name.rpc(my_player_name)

func _on_connection_failed() -> void:
	is_connected = false
	peer = null
	connection_failed.emit()
	print("Connection failed")

# ==================== 游戏开始 ====================

func can_start_game() -> bool:
	return is_host and players.size() >= 2 and players.size() <= room_max_players

func start_game() -> void:
	if not can_start_game():
		return
	# 广播开始游戏
	_broadcast_start_game.rpc()
	game_started.emit()

@rpc("authority", "call_local")
func _broadcast_start_game() -> void:
	game_started.emit()
	print("Game starting!")