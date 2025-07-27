class_name Deck extends Node2D

var _cards:Array[Card] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _init_hand_cards()->void:
	for i in range(Hand.max_cards):
		var c = card_scene.instantiate()
		cards.add_child(c)
		_add_to_hand(c)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_card(num:int=1)->void:
	if(num>_cards.size()):
		return
	
