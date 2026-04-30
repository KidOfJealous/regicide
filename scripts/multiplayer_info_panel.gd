extends Control
class_name MultiplayerInfoPanel

# UI节点
@onready var current_player_label: Label = $VBoxContainer/CurrentPlayerLabel
@onready var player_list_container: VBoxContainer = $VBoxContainer/PlayerListContainer
@onready var network_status_label: Label = $VBoxContainer/NetworkStatusLabel

# 网络管理器引用
var network_mgr: NetworkManager = null
var play_ground: Node = null

# 玩家信息条目缓存
var player_info_labels: Dictionary = {}

func _ready() -> void:
	# 获取引用
	network_mgr = get_node_or_null("/root/NetworkManager")
	play_ground = get_node_or_null("../PlayGround")
	
	if network_mgr and network_mgr.is_connected:
		_init_player_list()
		visible = true
	else:
		visible = false

func _process(delta: float) -> void:
	if network_mgr and network_mgr.is_connected:
		_update_display()
	else:
		visible = false

func _init_player_list() -> void:
	# 清空现有列表
	for child in player_list_container.get_children():
		child.queue_free()
	player_info_labels.clear()
	
	# 创建各玩家信息显示
	var players = network_mgr.get_all_players()
	for peer_id in players:
		var name = players[peer_id]
		var label = Label.new()
		label.name = str(peer_id)
		player_list_container.add_child(label)
		player_info_labels[peer_id] = label

func _update_display() -> void:
	# 更新当前玩家指示
	if play_ground and play_ground.is_multiplayer:
		var current_peer = play_ground.player_peer_ids[play_ground.current_player_index]
		var current_name = network_mgr.get_player_name(current_peer)
		if play_ground.is_my_turn:
			current_player_label.text = "当前回合：你"
			current_player_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			current_player_label.text = "当前回合：" + current_name
			current_player_label.add_theme_color_override("font_color", Color.YELLOW)
		
		# 更新玩家手牌数量
		for peer_id in player_info_labels:
			var label = player_info_labels[peer_id]
			var name = network_mgr.get_player_name(peer_id)
			var hand_count = play_ground.player_hand_counts.get(peer_id, 0)
			var prefix = ""
			if peer_id == current_peer:
				prefix = "▶ "
			if peer_id == play_ground.my_peer_id:
				prefix += "[你] "
			if peer_id == network_mgr.host_peer_id:
				prefix += "[主机] "
			label.text = prefix + name + " - 手牌: " + str(hand_count)
	
	# 更新网络状态
	if network_mgr.is_host:
		network_status_label.text = "你是主机 | 玩家: " + str(network_mgr.get_player_count())
	else:
		network_status_label.text = "已连接主机 | 玩家: " + str(network_mgr.get_player_count())