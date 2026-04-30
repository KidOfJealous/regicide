extends Node2D
@onready var player: Player = $"../Players/Player"
@onready var end_turn_button_ref: EndTurnButton = $"../Button"
@onready var boss_dec: BossDeck = $"../BossDeck"
@onready var deck: Deck = $"../Deck"
@onready var discard: Discard = $"../Discard"
@onready var field: CardField = $"../CardField"
@onready var card_manager_ref: CardManager = $"../CardManager"

var end:bool = false
var station: CardData.TurnStation = CardData.TurnStation.PLAYER
var is_initialized: bool = false
# 单人模式重抽次数（最多2次）
var refill_count: int = 0
const MAX_REFILL_COUNT: int = 2
# Mulligan状态：是否可用、是否已经使用
var mulligan_available: bool = false
var mulligan_used: bool = false

# 多人模式配置
var player_count: int = 1  # 当前玩家数量（默认单人模式）
var current_player_index: int = 0  # 当前活动玩家索引
var hand_size_limit: int  # 当前模式的手牌上限
var joker_count: int  # 当前模式的Joker数量

# ========== 多人网络相关 ========== 
var network_mgr: NetworkManager = null
var is_multiplayer: bool = false
var my_peer_id: int = 1
var is_my_turn: bool = true
# 玩家手牌数量映射（peer_id -> count）
var player_hand_counts: Dictionary = {}
# 玩家peer_id列表（按加入顺序）
var player_peer_ids: Array[int] = []

func _ready():
	# 在_ready中不直接调用_start，而是标记需要初始化
	pass

func _input(event: InputEvent) -> void:
	# 处理重抽快捷键（R键）
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		# 只在玩家回合可以重抽
		if station == CardData.TurnStation.PLAYER and not end:
			if can_refill():
				refill_hand()
	
	# 处理Mulligan快捷键（M键）
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		# 只在Mulligan可用且未使用时
		if mulligan_available and not mulligan_used and not end:
			do_mulligan()
			mulligan_used = true
			mulligan_available = false

func _process(delta):
	# 在_process中检查是否所有依赖都已准备好
	if not is_initialized:
		_try_initialize()

func _try_initialize():
	# 检查Player和其Hand是否都已初始化
	if player != null and player.hand != null:
		is_initialized = true
		set_process(false)  # 停止_process调用
		# 初始化网络管理器
		_init_network()
		_start()

func take_turns()->void:
	if is_multiplayer:
		await multiplayer_player_play()
	else:
		await player_play()

# 单人模式玩家出牌
func player_play():
	station = CardData.TurnStation.PLAYER
	# 检查玩家是否还有手牌，如果没有则判负
	if player.get_hand_card_count() == 0:
		lose()
		return
	var selected =  await player.wait_for_play()
	player.remove_selected_cards()
	await card_effect(selected)

# 多人模式玩家出牌（轮换机制）
func multiplayer_player_play():
	station = CardData.TurnStation.PLAYER
	# 主机广播当前回合玩家
	if network_mgr and network_mgr.is_host:
		var current_peer = player_peer_ids[current_player_index]
		sync_current_turn.rpc(current_peer, CardData.TurnStation.PLAYER)
	
	# 检查当前玩家是否还有手牌
	if is_my_turn:
		if player.get_hand_card_count() == 0:
			# 当前玩家没牌了，切换到下一个玩家
			_next_player()
			return
		
		# 等待当前玩家出牌
		var selected = await player.wait_for_play()
		player.remove_selected_cards()
		
		# 广播出牌结果
		if network_mgr and network_mgr.is_host:
			var cards_data = _serialize_cards(selected)
			sync_cards_played.rpc(my_peer_id, cards_data)
			sync_hand_count.rpc(my_peer_id, player.get_hand_card_count())
		
		await card_effect(selected)
	else:
		# 不是我的回合，等待主机广播
		await _wait_for_turn_change()

# 等待回合切换
func _wait_for_turn_change() -> void:
	while not is_my_turn and not end:
		await get_tree().create_timer(0.1).timeout

# 切换到下一个玩家
func _next_player() -> void:
	current_player_index = (current_player_index + 1) % player_peer_ids.size()
	var next_peer = player_peer_ids[current_player_index]
	is_my_turn = (next_peer == my_peer_id)
	
	if network_mgr and network_mgr.is_host:
		sync_current_turn.rpc(next_peer, station)

func _start():
	# 应用多人模式配置
	_apply_multiplayer_config()
	boss_dec.draw_card()
	
	# 多人模式：主机分发手牌
	if is_multiplayer and network_mgr.is_host:
		_distribute_initial_hands()
	elif not is_multiplayer:
		deck.draw_card(hand_size_limit, player, hand_size_limit)
	
	# Mulligan检查：如果初始手牌没有方块，提示可以重抽
	if not is_multiplayer:
		_check_mulligan()
	
	while not end:
		await take_turns()

# 多人模式分发初始手牌
func _distribute_initial_hands() -> void:
	for i in range(player_peer_ids.size()):
		var peer_id = player_peer_ids[i]
		var cards_to_send: Array[Card] = []
		for j in range(hand_size_limit):
			if not deck._cards.is_empty():
				var card = deck._cards.pop_back()
				cards_to_send.append(card)
		
		var cards_data = _serialize_cards(cards_to_send)
		
		if peer_id == my_peer_id:
			# 主机自己的牌直接添加
			for card in cards_to_send:
				card_manager_ref.add_child(card)
				player.add_card_to_hand(card)
				card.flip()
			player_hand_counts[peer_id] = cards_to_send.size()
		else:
			# 发给其他玩家
			rpc_receive_hand.rpc_id(peer_id, cards_data)
			sync_hand_count.rpc(peer_id, cards_data.size())
	
	deck.updateStatus()
	# 广播牌堆数量
	sync_deck_counts.rpc(deck._cards.size(), discard.cards.size())

# 应用多人模式配置
func _apply_multiplayer_config() -> void:
	# 边界检查：确保player_count是有效值
	if player_count not in CardData.MULTIPLAYER_CONFIG:
		push_error("无效的玩家数量: " + str(player_count) + "，回退到单人模式")
		player_count = 1
	
	var config = CardData.MULTIPLAYER_CONFIG[player_count]
	hand_size_limit = config["hand_size"]
	joker_count = config["jokers"]
	print("游戏模式：" + str(player_count) + "人，手牌上限：" + str(hand_size_limit) + "，Joker数量：" + str(joker_count))
	
	# 如果需要Joker，添加到牌堆
	for i in range(joker_count):
		var joker_type = CardData.Joker.LITTE_JOKER if i % 2 == 0 else CardData.Joker.BIG_JOKER
		var joker_card = Card.init_joker_scene(joker_type, true)
		joker_card.role = CardData.CardPosition.DECK
		deck._cards.push_back(joker_card)
	deck._cards.shuffle()
	deck.updateStatus()

# ========== 网络初始化 ==========
func _init_network() -> void:
	network_mgr = get_node_or_null("/root/NetworkManager")
	if network_mgr and network_mgr.is_connected:
		is_multiplayer = true
		my_peer_id = network_mgr.my_peer_id
		player_count = network_mgr.player_count
		# 初始化玩家列表
		var players = network_mgr.get_all_players()
		player_peer_ids.clear()
		for peer_id in players.keys():
			player_peer_ids.append(peer_id)
			player_hand_counts[peer_id] = 0
		# 设置当前玩家索引
		current_player_index = 0
		is_my_turn = (player_peer_ids[current_player_index] == my_peer_id)
		print("多人模式已启用，当前玩家：" + str(player_peer_ids[current_player_index]))
	else:
		is_multiplayer = false
		is_my_turn = true

# ========== RPC同步函数（多人模式）==========

# 同步Boss状态
@rpc("authority", "call_local")
func sync_boss_state(health: int, attack: int, immune: bool) -> void:
	boss_dec.current_boss_health = health
	boss_dec.current_boss_attack = attack
	boss_dec.immune_cancelled = immune
	boss_dec.refresh_status()

# 同步牌堆和弃牌堆数量
@rpc("authority", "call_local")
func sync_deck_counts(deck_count: int, discard_count: int) -> void:
	deck._cards.resize(deck_count)  # 仅同步数量
	deck.updateStatus()
	# discard.cards数量在主机会准确，客户端仅显示
	discard.update_count()

# 同步当前回合玩家
@rpc("authority", "call_local")
func sync_current_turn(peer_id: int, turn_station: int) -> void:
	var idx = player_peer_ids.find(peer_id)
	if idx >= 0:
		current_player_index = idx
	is_my_turn = (peer_id == my_peer_id)
	station = turn_station as CardData.TurnStation
	# 更新玩家操作权限
	_update_turn_permission()

# 同步防御目标（多人模式下防御轮换使用）
@rpc("authority", "call_local")
func sync_defend_target(peer_id: int, remaining_attack: int) -> void:
	var idx = player_peer_ids.find(peer_id)
	if idx >= 0:
		current_player_index = idx
	is_my_turn = (peer_id == my_peer_id)
	# 设置防御目标值
	if is_my_turn and station == CardData.TurnStation.DEFEND:
		player.hand.discard_target = remaining_attack
		player._update_status_label(remaining_attack)
		player.hand.update_button_state()
	_update_turn_permission()

# 同步出牌结果（广播给所有客户端）
@rpc("authority", "call_local")
func sync_cards_played(peer_id: int, cards_data: Array) -> void:
	# 解析卡牌数据并显示在处理区
	for card_data in cards_data:
		var card = _deserialize_card(card_data)
		if card:
			add_to_field([card])
	# 更新该玩家的手牌数量
	if peer_id in player_hand_counts:
		player_hand_counts[peer_id] -= cards_data.size()

# 同步游戏结果
@rpc("authority", "call_local")
func sync_game_result(is_win: bool) -> void:
	if is_win:
		win()
	else:
		lose()

# 发送手牌给指定玩家（仅主机调用，单独发给各玩家）
@rpc("authority")
func rpc_receive_hand(cards_data: Array) -> void:
	# 客户端接收手牌
	var cards: Array[Card] = []
	for card_data in cards_data:
		var card = _deserialize_card(card_data)
		if card:
			cards.append(card)
			player.hand.add_to_hand(card)
	player_hand_counts[my_peer_id] = cards.size()
	player.hand.update_position()

# 同步玩家手牌数量（用于显示其他玩家手牌）
@rpc("authority", "call_local")
func sync_hand_count(peer_id: int, count: int) -> void:
	player_hand_counts[peer_id] = count

# 更新回合操作权限
func _update_turn_permission() -> void:
	if is_multiplayer:
		# 非当前玩家的界面锁定
		player.hand.update_button_state()
		if not is_my_turn:
			# 锁定所有卡牌
			for card in player.hand.cards:
				card.disabled = true
		else:
			# 解锁卡牌
			for card in player.hand.cards:
				card.disabled = false
			player.hand.update_position()

# Mulligan机制：检查初始手牌是否有方块，没有则可重抽
func _check_mulligan() -> void:
	# 检查手牌是否有方块
	var has_diamond = false
	for card in player.hand.cards:
		if card.suit == CardData.Suit.DIAMOND:
			has_diamond = true
			break
	
	if not has_diamond:
		mulligan_available = true
		print("初始手牌没有方块，可以按M键进行Mulligan重抽")
		# 更新状态提示
		player._update_status_label()
		# 在状态标签上显示Mulligan提示
		player.status_label.text = "按M键进行Mulligan重抽，或选择牌开始游戏"

# Mulligan重抽：弃掉全部手牌重新抽取
func do_mulligan() -> bool:
	# 弃掉所有手牌
	var all_cards = player.hand.get_all_cards()
	for card in all_cards:
		card.selected = false
		card.disabled = false
		discard.cards.push_back(card)
	player.hand.clear_hand()
	discard.fresh_pos()
	
	# 重新抽取
	deck.draw_card(hand_size_limit, player, hand_size_limit)
	print("Mulligan重抽完成")
	return true

func card_effect(cards: Array[Card]) -> void:
	# Yield功能：玩家选择不出牌（空数组）
	if cards.size() == 0:
		print("玩家选择Yield，不出牌")
		await boss_attack()
		return
	
	# 检查是否打出Joker牌
	var joker_played = false
	for card in cards:
		if CardData.is_joker(card):
			joker_played = true
			break
	
	# Joker特殊处理：取消Boss免疫，跳过攻击回合
	if joker_played:
		boss_dec.immune_cancelled = true
		boss_dec.refresh_status()
		add_to_discard(cards)
		# Joker不造成伤害，直接进入下一回合
		return
	
	var boss = boss_dec.current_boss
	var value = 0
	# 记录打出过的花色（用于触发效果）
	var suits_played: Array[bool] = [false, false, false, false]
	# Boss免疫状态（后续Joker可取消）
	var immune_cancelled = boss_dec.immune_cancelled
	
	for card in cards:
		# 记录所有打出过的花色
		if not suits_played[card.suit]:
			suits_played[card.suit] = true
		value += card.value
	
	var damage = value
	
	# 应用花色效果（Boss免疫检查：如果Boss花色匹配且免疫未取消，则不触发效果）
	# 梅花：伤害翻倍
	if suits_played[CardData.Suit.CLUB]:
		if immune_cancelled or boss.suit != CardData.Suit.CLUB:
			damage *= 2
	
	# 红心：恢复牌堆
	if suits_played[CardData.Suit.HEART]:
		if immune_cancelled or boss.suit != CardData.Suit.HEART:
			_restore_deck(value)
	
	# 方块：抽牌
	if suits_played[CardData.Suit.DIAMOND]:
		if immune_cancelled or boss.suit != CardData.Suit.DIAMOND:
			deck.draw_card(value, player, hand_size_limit)
			# 多人模式下同步抽牌结果
			if is_multiplayer and network_mgr and network_mgr.is_host:
				sync_hand_count.rpc(my_peer_id, player.get_hand_card_count())
				sync_deck_counts.rpc(deck._cards.size(), discard.cards.size())
	
	# 黑桃：降低Boss攻击力
	if suits_played[CardData.Suit.SPADE]:
		if immune_cancelled or boss.suit != CardData.Suit.SPADE:
			boss_dec.current_boss_attack -= value
	add_to_field(cards)
	boss_dec.current_boss_health -= damage
	boss_dec.refresh_status()
	if boss_dec.current_boss_health <= 0:
		boss_to_deck(boss, boss_dec.current_boss_health == 0)
		add_to_discard(field.cards)
		field.cards = []
		field.fresh_pos()
		if boss_dec._cards.size() > 0:  # 还有Boss牌
			boss_dec.draw_card()  # 抽取下一个Boss
		else:
			win()
	else:
		await boss_attack()
		
func add_to_discard(cards: Array[Card]):
	discard.cards += cards
	discard.fresh_pos()

func add_to_field(cards: Array[Card]) -> void:
	field.cards += cards
	field.fresh_pos()

func boss_attack() -> void:
	station = CardData.TurnStation.DEFEND
	if is_multiplayer:
		await multiplayer_defend()
	else:
		await single_defend()

# 单人模式防御
func single_defend() -> void:
	if player.get_hand_card_sum() < boss_dec.current_boss_attack:
		lose()
	else:
		var cards: Array[Card] = await player.wait_for_discard(boss_dec.current_boss_attack)
		player.remove_selected_cards()
		add_to_discard(cards)

# 多人模式防御轮换
func multiplayer_defend() -> void:
	var total_attack = boss_dec.current_boss_attack
	var defending_index = current_player_index  # 从出牌玩家开始防御
	var all_defended = false
	
	# 广播防御状态
	if network_mgr and network_mgr.is_host:
		sync_current_turn.rpc(player_peer_ids[defending_index], CardData.TurnStation.DEFEND)
	
	while not all_defended and not end:
		var current_defender = player_peer_ids[defending_index]
		is_my_turn = (current_defender == my_peer_id)
		
		if is_my_turn:
			# 我的防御回合
			var my_hand_sum = player.get_hand_card_sum()
			if my_hand_sum >= total_attack:
				# 可以防御足够伤害
				var cards: Array[Card] = await player.wait_for_discard(total_attack)
				player.remove_selected_cards()
				add_to_discard(cards)
				
				# 广播防御结果
				if network_mgr and network_mgr.is_host:
					var cards_data = _serialize_cards(cards)
					sync_cards_played.rpc(my_peer_id, cards_data)
					sync_hand_count.rpc(my_peer_id, player.get_hand_card_count())
					sync_deck_counts.rpc(deck._cards.size(), discard.cards.size())
				
				all_defended = true
			else:
				# 手牌不够防御，弃掉所有牌，切换到下一个玩家
				var remaining_attack = total_attack - my_hand_sum
				var all_cards = player.hand.get_all_cards()
				for card in all_cards:
					card.selected = true
				player.remove_selected_cards()
				add_to_discard(all_cards)
				total_attack = remaining_attack
				
				# 广播防御结果
				if network_mgr and network_mgr.is_host:
					var cards_data = _serialize_cards(all_cards)
					sync_cards_played.rpc(my_peer_id, cards_data)
					sync_hand_count.rpc(my_peer_id, 0)
				
				# 切换到下一个防御者
				defending_index = (defending_index + 1) % player_peer_ids.size()
							
				# 检查是否所有玩家都没牌了
				if _check_all_players_empty():
					lose()
					return
							
				# 广播下一个防御者和剩余攻击值
				if network_mgr and network_mgr.is_host:
					sync_defend_target.rpc(player_peer_ids[defending_index], total_attack)
		else:
			# 等待其他玩家防御
			await get_tree().create_timer(0.1).timeout
	
	# 防御完成，切换回合
	_next_player()

# 检查所有玩家是否都没牌了
func _check_all_players_empty() -> bool:
	for peer_id in player_peer_ids:
		if player_hand_counts[peer_id] > 0:
			return false
	return true

func win():
	end = true
	print("You win")
	# 显示胜利界面
	show_game_over(true)

func lose():
	end = true
	print("You lose")
	# 显示失败界面
	show_game_over(false)

func show_game_over(is_win: bool) -> void:
	# 加载并显示游戏结束界面
	var game_over_scene = preload("res://scenes/game_over.tscn")
	var game_over = game_over_scene.instantiate()
	add_child(game_over)
	
	if is_win:
		game_over.show_win()
	else:
		game_over.show_lose()
		
	# 连接重新开始游戏的信号
	game_over.connect("restart_game", Callable(self, "_restart_game"))

func _restart_game() -> void:
	# 重新开始游戏的逻辑
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")

# 红心效果：从洗好的弃牌堆随机抽取牌，放回牌堆底部
func _restore_deck(num: int):
	# 弃牌堆已经在getCards中shuffle了
	var cards_from_discard = discard.getCards(num)
	deck.put_cards_bottom(cards_from_discard)
	
func boss_to_deck(boss: Card, mercy: bool = false):
	# 重置Boss牌状态
	boss.role = CardData.CardPosition.DECK
	boss.card_type = CardData.CardType.BOSS  # 保持Boss类型标识
	boss.back = true  # 显示背面
	boss.disabled = false
	boss.selected = false
	
	if mercy:
		# 恰好击败Boss，放回牌堆顶部
		deck.put_boss_top(boss)
	else:
		# 超额伤害，放入弃牌堆
		discard.cards.push_back(boss)
		discard.fresh_pos()

# 单人模式重抽功能：弃掉全部手牌，重新抽取
func refill_hand() -> bool:
	# 检查是否还有重抽次数（仅单人模式可用）
	if player_count != 1:
		print("多人模式不支持重抽")
		return false
	if refill_count >= MAX_REFILL_COUNT:
		print("重抽次数已用完")
		return false
	
	# 检查牌堆是否有足够的牌
	if deck._cards.size() < hand_size_limit:
		print("牌堆牌不足，无法重抽")
		return false
	
	# 弃掉所有手牌
	var all_cards = player.hand.get_all_cards()
	for card in all_cards:
		card.selected = false
		card.disabled = false
		discard.cards.push_back(card)
	player.hand.clear_hand()
	discard.fresh_pos()
	
	# 重新抽取
	deck.draw_card(hand_size_limit, player, hand_size_limit)
	
	# 增加重抽次数计数
	refill_count += 1
	print("重抽成功，已使用 " + str(refill_count) + " 次")
	return true

# 检查是否可以重抽
func can_refill() -> bool:
	return player_count == 1 and refill_count < MAX_REFILL_COUNT and deck._cards.size() >= hand_size_limit

# ========== 卡牌序列化/反序列化（用于网络传输）==========

# 序列化卡牌为字典
func _serialize_card(card: Card) -> Dictionary:
	var data = {
		"suit": card.suit,
		"value": card.value,
		"rank": card.rank,
		"card_type": card.card_type,
		"role": card.role,
		"back": card.back
	}
	# Joker类型信息
	if card.card_type == CardData.CardType.JOKER:
		data["joker_type"] = card.joker_type
	return data

# 反序列化字典为卡牌
func _deserialize_card(data: Dictionary) -> Card:
	var card: Card
	if data["card_type"] == CardData.CardType.JOKER:
		var joker_type = data.get("joker_type", CardData.Joker.LITTE_JOKER)
		card = Card.init_joker_scene(joker_type, data["back"])
	elif data["card_type"] == CardData.CardType.BOSS:
		# Boss牌
		var boss_idx = 0
		if data["value"] == 15:
			boss_idx = 1
		elif data["value"] == 20:
			boss_idx = 2
		card = Card.init_boss_scene(data["suit"], boss_idx, data["back"])
	else:
		# 普通牌
		var num_idx = data["value"] - 1  # A=1对应索引0
		card = Card.init_card_scene(data["suit"], num_idx, data["back"])
	
	card.role = data["role"]
	card.value = data["value"]
	card.card_type = data["card_type"]
	return card

# 序列化卡牌数组
func _serialize_cards(cards: Array[Card]) -> Array:
	var result = []
	for card in cards:
		result.append(_serialize_card(card))
	return result
