extends Node2D
@onready var player_hand: Hand = $"../Hand"
@onready var end_turn_button_ref: EndTurnButton = $"../Button"
@onready var boss_dec: BossDeck = $"../BossDeck"
@onready var deck: Deck = $"../Deck"
@onready var discard: Discard = $"../Discard"
@onready var field: CardField = $"../CardField"

var end:bool = false
var station: CardData.TurnStation = CardData.TurnStation.PLAYER
func _ready():
	_start()
	while not end:

func take_turns()->void:
	await player_hand

func _on_card_play() -> void:
	if station == CardData.TurnStation.PLAYER:
		_player_action()

func _start():
	boss_dec.draw_card()
	deck.draw_card(CardData.MAX_HAND_CARD_NUM)

func _player_action() -> void:
	var selected = player_hand.get_selected()
	player_hand.remove_selected()
	card_effect(selected)

func card_effect(cards: Array[Card]) -> void:
	var boss = boss_dec.current_boss();
	var value = 0
	var suits: Array[int] = [false, false, false, false]
	for card in cards:
		if not (card.suit == boss.suit or suits[card.suit]):
			suits[card.suit] = true
		value += card.value
	var damage = value
	if suits[CardData.Suit.CLUB]:
		damage *= 2
	if suits[CardData.Suit.HEART]:
		_restore_deck(value)
	if suits[CardData.Suit.DIAMOND]:
		deck.draw_card(value)
	if suits[CardData.Suit.SPADE]:
		boss_dec.current_boss_attack -= value
	add_to_field(cards)
	boss_dec.current_boss_health -= damage
	boss_dec.refresh_status()
	if boss_dec.current_boss_health <= 0:
		boss_to_deck(boss, boss_dec.current_boss_health == 0)
		add_to_discard(field.cards)
		field.cards = []

		if boss_dec._cards.size():
			boss_dec.draw_card()
		else:
			win()
	else:
		boss_attack()
func add_to_discard(cards: Array[Card]):
	discard.cards += field.cards
	discard.fresh_pos()

func add_to_field(cards: Array[Card]) -> void:
	field.cards += cards
	field.fresh_pos()

func boss_attack() -> void:
	station = CardData.TurnStation.DEFEND
	if player_hand.card_sum < boss_dec.current_boss_attack:
		lose()
	else:
		var enough = false
		var cards: Array[Card] = []
		while not enough:
			await end_turn_button_ref.pressed
			cards = player_hand.get_selected()
			enough = cards.reduce(CardData.sum, 0) >= boss_dec.current_boss_attack
		player_hand.remove_selected()
		add_to_discard(cards)

func win():
	end = true
	print("You win")
func lose():
	end = true
	print("You lose")
func _restore_deck(num: int):
	deck.put_cards_back(discard.getCards(num))
func boss_to_deck(boss: Card, mercy: bool = false):
	if mercy:
		deck.put_boss_top(boss)
	else:
		discard.cards.push_back(boss)
