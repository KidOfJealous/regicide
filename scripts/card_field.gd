class_name CardField extends Node2D
var cards:Array[Card] = []
func fresh_pos()->void:
    for card in cards:
        card.role=CardData.CardPosition.FIELD