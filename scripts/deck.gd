class_name Deck extends Node2D
var _cards:Array[Card] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_hand_cards() # Replace with function body.
@onready var hand_ref:Hand=$"../Hand"
@onready var card_manager_ref:CardManager=$"../CardManager"
func _init_hand_cards()->void:
	for i in range(4):
		for j in range(10):
			var card = Card.init_card_scene(i,j)
			card.role = CardData.CardPosition.DECK
			card.position = self.position
			_cards.push_back(card)
	_cards.shuffle()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_card(num:int=1)->void:
	if hand_ref.card_size>=CardData.MAX_HAND_CARD_NUM:
		return
	else:
		while num>0 and not _cards.is_empty():
			var card = _cards.pop_back() as Card
			card_manager_ref.add_child(card)
			hand_ref.add_to_hand(card)
			card.flip()
			num-=1
	updateStatus()
func put_boss_top(card:Card)->void:
	_cards.push_back(card)
	updateStatus()
func put_cards_back(cards:Array[Card])->void:
	_cards=cards+_cards
func updateStatus():
	$empty.visible=_cards.is_empty()
	$card_back.visible = !_cards.is_empty()
