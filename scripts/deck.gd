class_name Deck extends Node2D
var _cards:Array[Card] = []

# 使用普通变量而非@onready，避免加载顺序问题
var card_manager_ref  # 动态类型
var count_label: Label

func _ready() -> void:
	# 手动初始化节点引用（在调用其他函数之前）
	card_manager_ref = get_node_or_null("../CardManager")
	count_label = get_node_or_null("CountLabel")
	_init_hand_cards()

func _init_hand_cards()->void:
	# 多人模式下客户端不需要初始化牌堆（由主机同步）
	var network_mgr = get_node_or_null("/root/NetworkManager")
	if network_mgr and network_mgr.is_connected and not network_mgr.is_host:
		return  # 客户端跳过初始化，等待主机同步
	
	# 正常初始化牌堆
	for i in range(4):
		for j in range(10):
			var card = Card.init_card_scene(i,j)
			card.role = CardData.CardPosition.DECK
			card.position = self.position
			_cards.push_back(card)
	_cards.shuffle()
	updateStatus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 抽牌方法 - 返回指定数量的卡牌，不直接添加到手牌
func get_cards(num:int=1)->Array[Card]:
	var result: Array[Card] = []
	var count = min(num, _cards.size())
	for i in range(count):
		if not _cards.is_empty():
			var card = _cards.pop_back() as Card
			result.push_back(card)
	updateStatus()
	return result

# 旧的draw_card方法保留以保持兼容，但现在需要传入player引用和可选的手牌上限
func draw_card(num:int=1, player = null, hand_limit: int = CardData.MAX_HAND_CARD_NUM)->void:
	if player == null:
		# 如果没有传入player，直接返回，这是为了防止错误
		push_error("Deck.draw_card() requires a player parameter. Use get_cards() instead.")
		return
	
	if not player.can_add_card(hand_limit):
		return
	else:
		while num>0 and player.can_add_card(hand_limit) and not _cards.is_empty():
			var card = _cards.pop_back() as Card
			if card_manager_ref:
				card_manager_ref.add_child(card)
			player.add_card_to_hand(card)
			if card._is_ready:
				card.flip()
			else:
				card.call_deferred("flip")
			num-=1
			await  get_tree().create_timer(0.2).timeout
	updateStatus()

func put_boss_top(card:Card)->void:
	_cards.push_back(card)
	updateStatus()

# 将牌放回牌堆顶部（原有方法）
func put_cards_back(cards:Array[Card])->void:
	_cards=cards+_cards
	updateStatus()

# 将牌放回牌堆底部（红心效果使用）
func put_cards_bottom(cards:Array[Card])->void:
	_cards = _cards + cards
	updateStatus()

func updateStatus():
	$empty.visible=_cards.is_empty()
	$card_back.visible = !_cards.is_empty()
	
	# 更新计数显示，没有卡牌时不显示
	if count_label:
		if _cards.size() > 0:
			count_label.text = str(_cards.size())
			count_label.show()
		else:
			count_label.hide()
