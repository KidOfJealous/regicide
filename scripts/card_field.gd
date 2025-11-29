class_name CardField extends Node2D
var cards: Array[Card] = []

@onready var count_label: Label = $CountLabel

func fresh_pos() -> void:
	# 计算层叠偏移量，每张牌露出一部分
	var overlap_offset = CardData.CARD_LENGTH * 0.3  # 30%的重叠
	
	for i in range(cards.size()):
		var card = cards[i]
		card.role = CardData.CardPosition.FIELD
		# 每张牌向下偏移，形成层叠效果
		var card_position = Vector2(self.position.x, self.position.y + i * overlap_offset)
		card.position = card_position
		card.disabled = false
		# 设置z_index，确保后面的牌在上面
		card.z_index = i
		CardData.smooth_move(card, card_position)
	
	update_count()

func update_count():
	# 更新计数显示
	if count_label:
		count_label.text = str(cards.size())