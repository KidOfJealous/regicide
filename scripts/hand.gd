class_name Hand extends Node2D


var cards:Array[Card] = []

@onready var HAND_Y = self.get_viewport_rect().size.y-CardData.CARD_LENGTH
@onready var screen_center_x = self.get_viewport_rect().size.x/2

const card_scene = preload("res://scenes/card.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
var card_size:
	get:
		return cards.size()
func add_to_hand(card:Card):
	if card not in cards:
		cards.push_back(card)
		update_position()
		card.role = CardData.CardPosition.HAND
	else:
		smooth_move(card,card.hand_position)
func remove_from_hand(card:Card):
	if card in cards:
		cards.erase(card)
		update_position()
func update_position()->void:
	var size = cards.size()
	for i in range(size):
		var pos = Vector2(calc_pos(i,size),HAND_Y)
		cards[i].hand_position = pos;
		smooth_move(cards[i],pos)
		
		
func calc_pos(i:int,size:int):
	var total_width = (size-1)*CardData.CARD_WIDTH
	var x_offset = screen_center_x+i*CardData.CARD_WIDTH-total_width/2
	return x_offset
	
func smooth_move(card:Card,position:Vector2):
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position",position,0.1)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
