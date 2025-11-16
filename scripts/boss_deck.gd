class_name BossDeck extends Node2D
var _cards: Array[Card] = []
var current_boss_health: int
var current_boss_attack: int:
	set(value):
		current_boss_attack = max(0, value)
# Called when the node enters the scene tree for the first time.
@onready var health_text: Label = $"./Health"
@onready var attach_text: Label = $"./Attack"
const health_template = "生命值：{0}/{1}"
const attack_template = "攻击力：{0}/{1}"
func _ready() -> void:
	_init_boss_cards() # Replace with function body.
@onready var hand_ref: Hand = $"../Hand"
@onready var card_manager_ref: CardManager = $"../CardManager"
func _init_boss_cards() -> void:
	for i in range(2, -1, -1):
		var _temp: Array[Card] = []
		for j in range(4):
			var card = Card.init_boss_scene(j, i)
			card.role = CardData.CardPosition.BOSS
			card.position = self.position
			_temp.push_back(card)
		_cards += _temp
	draw_card()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func refresh_status() -> void:
	var attack = current_boss().value
	health_text.text=health_template.format([self.current_boss_health,attack*2])
	attach_text.text=attack_template.format([self.current_boss_attack,attack])
	
func draw_card() -> void:
	if _cards.is_empty():
		return
	var card = _cards[-1] as Card
	current_boss_health = card.value * 2
	current_boss_attack = card.value
	card.flip()
	card_manager_ref.add_child(card)
	refresh_status()
	
func current_boss() -> Card:
	return _cards[-1]
