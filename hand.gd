class_name Hand extends Node2D

var max_cards = 7
var cards = []

@onready var screen_center_x = self.get_viewport_rect().size.x/2

const card_scene = preload("res://card.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cards = $"../Cards"
	for i in range(max_cards):
		var c = card_scene.instantiate()
		cards.add_child(c)
		_add_to_hand(c)

func _add_to_hand(card:Card):
	cards.push_back(card)

func update_position()->void:
	var size = cards.size()
	for i in range(size):
		var pos = calc_pos(i,size)
		
func calc_pos(i:int,size:int):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
