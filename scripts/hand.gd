class_name Hand extends Node2D

var cards: Array[Card] = []
var selected_cards: Array[Card] = []
var discard_target: int = 0
var station:CardData.TurnStation:
	set(st):
		if not st==station:
			station=st
			update_button_state()

@onready var HAND_Y = self.get_viewport_rect().size.y - CardData.CARD_LENGTH
@onready var SELECTED_Y = HAND_Y - CardData.CARD_LENGTH / 5
@onready var screen_center_x = self.get_viewport_rect().size.x / 2
@onready var confirm_button: Button = $"../Button"

const card_scene = preload("res://scenes/card.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
var card_size:
	get:
		return cards.size()
var card_sum:
	get:
		return cards.reduce(CardData.sum, 0)

func add_to_hand(card: Card):
	if card not in cards:
		cards.push_back(card)
		update_position()
		card.role = CardData.CardPosition.HAND
	else:
		CardData.smooth_move(card, card.hand_position)
func remove_from_hand(card: Card):
	if card in cards:
		cards.erase(card)
		update_position()

func update_position() -> void:
	var size = cards.size()
	for i in range(size):
		var card = cards[i]
		var pos = Vector2(calc_pos(i, size), HAND_Y if not cards[i].selected else SELECTED_Y)
		card.hand_position = pos;
		if station == CardData.TurnStation.PLAYER && not selected_cards.has(card) && not cards[i].selected:
			card.disabled = not CardData.isValidCards(selected_cards, card)
		else:
			card.disabled = false
		CardData.smooth_move(card, pos)

func select_card(card: Card) -> void:
	if station==CardData.TurnStation.DEFEND or card.selected or CardData.isValidCards(selected_cards, card):
		card.selected = not card.selected
		selected_cards = cards.filter(func(c: Card): return c.selected)
		update_position()
		update_button_state()

func calc_pos(i: int, size: int):
	var total_width = (size - 1) * CardData.CARD_WIDTH
	var x_offset = screen_center_x + i * CardData.CARD_WIDTH - total_width / 2
	return x_offset
func remove_selected() -> void:
	cards = cards.filter(func(c: Card): return not c.selected)
	selected_cards = []
	update_position()

func get_selected() -> Array[Card]:
	return selected_cards.duplicate()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 等待用户按照选中规则选中合适的牌并点击按钮打出
func wait_for_user_play() -> Array[Card]:
	station = CardData.TurnStation.PLAYER
	await confirm_button.pressed
	return get_selected()

# 等待用户选中value综合不小于target的牌并点击按钮确定
func wait_for_user_discard(target: int) -> Array[Card]:
	station = CardData.TurnStation.DEFEND
	discard_target = target
	update_button_state()
	update_position()
	await confirm_button.pressed
	discard_target = 0
	update_button_state()
	return get_selected()

# 更新按钮状态
func update_button_state() -> void:
	if not confirm_button:
		return
	if station == CardData.TurnStation.DEFEND:
		# 当处于防御阶段时
		if discard_target > 0:
			# 如果需要弃牌（目标值大于0），则检查选中牌的总和是否满足要求
			var current_sum = selected_cards.reduce(CardData.sum, 0)
			confirm_button.disabled = current_sum < discard_target
		else:
			# 如果不需要弃牌（目标值为0），按钮应始终可用
			confirm_button.disabled = false
	else:
		confirm_button.disabled = selected_cards.size() == 0