extends Node2D
@onready var player_hand:Hand = $"../Hand"
@onready var end_turn_button_ref:EndTurnButton = $"../Button"
@onready var boss_dec:BossDeck = $"../BossDeck"
@onready var deck:Deck = $"../Deck"
@onready var discard:Discard = $"../Discard"
@onready var field:CardField = $"../CardField"
func _ready():
	end_turn_button_ref.pressed.connect(_end_turn)

func _end_turn()->void:
	var selected = player_hand.get_selected()

func card_effect(cards:Array[Card])->void:
	var boss = boss_dec.current_boss();
	var value = 0
	var suits:Array[CardData.Suit] =[]
	for card in cards:
		if not (card.suit==boss.suit or suits.has(card.suit)):
			suits.push_back(card.suit)
		value+=card.value
	var damage = value
	var draw_card = false
	var restore = false
	for suit in suits:
		match suit:
			CardData.Suit.SPADE:
				boss_dec.current_boss_attack-=value
			CardData.Suit.HEART:
				restore = true
			CardData.Suit.DIAMOND:
				draw_card = true
			CardData.Suit.CLUB:
				damage*=2
	if restore:
		_restore_deck(value)
	if draw_card:
		deck.draw_card(value)
	field.cards+=cards
	field.fresh_pos()

	boss_dec.current_boss_health-=damage
	
	if boss_dec.current_boss_health<=0:
		boss_to_deck(boss,boss_dec.current_boss_health==0)
		discard.cards+=field.cards
		field.cards = []
		discard.fresh_pos()
func _restore_deck(num:int):
	deck.put_cards_back(discard.getCards(num))
func boss_to_deck(boss:Card,mercy:bool = false):
	if mercy:
		deck.put_boss_top(boss)
	else:
		discard.cards.push_back(boss)
		
		
