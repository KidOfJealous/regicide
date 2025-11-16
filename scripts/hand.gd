class_name Hand extends Node2D

var cards: Array[Card] = []
var selected_cards: Array[Card] = []
var station:CardData.TurnStation:
	set(st):
		if not st==station:
			station=st

@onready var HAND_Y = self.get_viewport_rect().size.y - CardData.CARD_LENGTH
@onready var SELECTED_Y = HAND_Y - CardData.CARD_LENGTH / 5
@onready var screen_center_x = self.get_viewport_rect().size.x / 2

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

func calc_pos(i: int, size: int):
	var total_width = (size - 1) * CardData.CARD_WIDTH
	var x_offset = screen_center_x + i * CardData.CARD_WIDTH - total_width / 2
	return x_offset
func remove_selected() -> void:
	cards = cards.filter(func(c: Card): return not c.selected)
	update_position()

func get_selected() -> Array[Card]:
	return selected_cards.duplicate()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
