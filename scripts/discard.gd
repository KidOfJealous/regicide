class_name Discard extends CardField
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass
@onready var hand_ref:Hand=$"../Hand"
@onready var card_manager_ref:CardManager=$"../CardManager"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func getCards(num:int = 1)->Array[Card]:
    cards.shuffle()
    var count = min(cards.size(),num)
    var result = cards.slice(0,count)
    cards = cards.slice(count)
    return result
func fresh_pos()->void:
    for card in cards:
        card.role=CardData.CardPosition.DISCARD