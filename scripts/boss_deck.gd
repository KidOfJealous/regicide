class_name BossDeck extends Node2D
var _cards:Array[Card] = []
var current_boss_health:int


var current_boss_attack:int:
	set(value):
		current_boss_attack = max(0,current_boss_attack)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_boss_cards() # Replace with function body.
@onready var hand_ref:Hand=$"../Hand"
@onready var card_manager_ref:CardManager=$"../CardManager"
func _init_boss_cards()->void:
	for i in range(3,0,-1):
		var _temp:Array[Card] = []
		for j in range(3,0,-1):
			var card = Card.init_boss_scene(i,j)
			card.role = CardData.CardPosition.DECK
			card.position = self.position
			_temp.push_back(card)
		_cards.push_back(_temp)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_card()->void:
	if _cards.is_empty():
		print("You win")
		return
	var card = _cards[-1] as Card
	current_boss_health = card.value*2
	current_boss_attack = card.value
	card.flip()
func current_boss()->Card:
	return _cards[-1]
func updateStatus():
	var is_empty =  _cards.size()
	$empty.visible=!is_empty
	$card_back.visible = is_empty
		
	