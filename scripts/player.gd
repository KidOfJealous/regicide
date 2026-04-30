class_name Player extends Node2D

signal finish_play
signal finish_defend
signal cards_played(cards: Array[Card])
signal cards_discarded(cards: Array[Card])
signal hand_changed(card_count: int)

# 使用普通变量而非@onready，避免加载顺序问题
var button: Button
var hand: Hand
var status_label: Label

func _ready() -> void:
	# 手动初始化节点引用
	button = get_node_or_null("Button")
	hand = get_node_or_null("Hand")
	status_label = get_node_or_null("StatusLabel")

func play_cards()->void:
	if hand:
		hand.station = CardData.TurnStation.PLAYER
	_update_status_label()
	if button:
		await button.pressed
	finish_play.emit()

# ========== 卡牌操作接口 ==========

# 添加卡牌到手牌
func add_card_to_hand(card: Card) -> void:
	if hand:
		hand.add_to_hand(card)
		hand_changed.emit(hand.card_size)

# 等待玩家出牌
func wait_for_play() -> Array[Card]:
	if hand:
		hand.station = CardData.TurnStation.PLAYER
		_update_status_label()
		var selected = await hand.wait_for_user_play()
		cards_played.emit(selected)
		return selected
	return [] as Array[Card]

# 等待玩家弃牌
func wait_for_discard(target: int) -> Array[Card]:
	if hand:
		hand.station = CardData.TurnStation.DEFEND
		_update_status_label(target)
		var selected = await hand.wait_for_user_discard(target)
		cards_discarded.emit(selected)
		return selected
	return [] as Array[Card]

# 移除已选中的卡牌
func remove_selected_cards() -> void:
	if hand:
		hand.remove_selected()
		hand_changed.emit(hand.card_size)

# 选择指定卡牌
func select_card(card: Card) -> void:
	if hand:
		hand.select_card(card)

# ========== 状态查询接口 ==========

# 获取手牌数量
func get_hand_card_count() -> int:
	if hand:
		return hand.card_size
	return 0

# 获取手牌点数总和
func get_hand_card_sum() -> int:
	if hand:
		return hand.card_sum
	return 0

# 检查是否可以添加卡牌（手牌上限检查）
# limit参数可选，默认使用单人模式上限8张
func can_add_card(limit: int = CardData.MAX_HAND_CARD_NUM) -> bool:
	if hand:
		return hand.card_size < limit
	return false

# 更新状态标签文本
func _update_status_label(discard_target: int = 0) -> void:
	if not hand or not status_label:
		return
	if hand.station == CardData.TurnStation.PLAYER:
		status_label.text = "请选择要出的牌（或不选择直接确认跳过）"
	elif hand.station == CardData.TurnStation.DEFEND:
		if discard_target > 0:
			status_label.text = "请弃掉至少 " + str(discard_target) + " 点数的牌"
		else:
			status_label.text = "可选择弃牌或直接确认"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
