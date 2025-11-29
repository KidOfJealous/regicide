class_name Discard extends Node2D
var cards:Array[Card] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@onready var count_label: Label = $CountLabel

func getCards(num:int = 1)->Array[Card]:
	cards.shuffle()
	var count = min(cards.size(),num)
	var result = cards.slice(0,count)
	cards = cards.slice(count)
	update_count()
	return result

func fresh_pos()->void:
	# 计算层叠偏移量，每张牌露出一部分
	var overlap_offset = CardData.CARD_LENGTH * 0.3  # 30%的重叠
	
	for i in range(cards.size()):
		var card = cards[i]
		card.role=CardData.CardPosition.DISCARD
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