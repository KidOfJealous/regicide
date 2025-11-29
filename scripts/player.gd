class_name Player extends Node2D

signal finish_play
signal finish_defend
signal cards_played(cards: Array[Card])
signal cards_discarded(cards: Array[Card])
signal hand_changed(card_count: int)

@onready var button:Button = $Button
@onready var hand:Hand = $Hand
@onready var status_label:Label = $StatusLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func play_cards()->void:
	hand.station = CardData.TurnStation.PLAYER
	_update_status_label()
	await button.pressed
	finish_play.emit()

# ========== 卡牌操作接口 ==========

# 添加卡牌到手牌
func add_card_to_hand(card: Card) -> void:
	hand.add_to_hand(card)
	hand_changed.emit(hand.card_size)

# 等待玩家出牌
func wait_for_play() -> Array[Card]:
	hand.station = CardData.TurnStation.PLAYER
	_update_status_label()
	var selected = await hand.wait_for_user_play()
	cards_played.emit(selected)
	return selected

# 等待玩家弃牌
func wait_for_discard(target: int) -> Array[Card]:
	hand.station = CardData.TurnStation.DEFEND
	_update_status_label(target)
	var selected = await hand.wait_for_user_discard(target)
	cards_discarded.emit(selected)
	return selected

# 移除已选中的卡牌
func remove_selected_cards() -> void:
	hand.remove_selected()
	hand_changed.emit(hand.card_size)

# 选择指定卡牌
func select_card(card: Card) -> void:
	hand.select_card(card)

# ========== 状态查询接口 ==========

# 获取手牌数量
func get_hand_card_count() -> int:
	return hand.card_size

# 获取手牌点数总和
func get_hand_card_sum() -> int:
	return hand.card_sum

# 检查是否可以添加卡牌（手牌上限检查）
func can_add_card() -> bool:
	return hand.card_size < CardData.MAX_HAND_CARD_NUM

# 更新状态标签文本
func _update_status_label(discard_target: int = 0) -> void:
	if hand.station == CardData.TurnStation.PLAYER:
		status_label.text = "请选择要出的牌"
	elif hand.station == CardData.TurnStation.DEFEND:
		if discard_target > 0:
			status_label.text = "请弃掉至少 " + str(discard_target) + " 点数的牌"
		else:
			status_label.text = "可选择弃牌或直接确认"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass