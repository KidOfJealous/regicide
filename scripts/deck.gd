class_name Deck extends Node2D
var _cards:Array[Card] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_hand_cards() # Replace with function body.
@onready var hand_ref:Hand=$"../Hand"
@onready var card_manager_ref:CardManager=$"../CardManager"
func _init_hand_cards()->void:
	for i in range(Hand.max_cards):
		var card = Card.init_card_scene()
		card.position = self.position
		_cards.push_back(card)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_card(num:int=1)->void:
	if(num>_cards.size()):
		pass
	else:
		while num>0:
			var card = _cards.pop_back()
			card_manager_ref.add_child(card)
			hand_ref.add_to_hand(card)
			num-=1
		if _cards.size()==0:
			$Panel2.visible=true
			$Sprite2D.visible = false
