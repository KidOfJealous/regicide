extends Node2D
enum CardNum{
	ACE ,
	TWO,
	THREE,
	FOUR ,
	FIVE ,
	SIX ,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
}
enum Suit{
	SPADE,
	DIAMOND,
	HEART,
	CLUB
}
enum Boss{
	JACK,
	QUEEN,
	KING,
}
enum Joker{
	LITTE_JOKER,
	BIG_JOKER,
}
enum CardPosition{
	DECK,
	HAND,
	FIELD,
	BOSS,
	DISCARD,
}
enum TurnStation{
	PLAYER,
	DEFEND,
}
const CARD_WIDTH = 73.2
const CARD_LENGTH = 102.4
const HOVER_SCALE = Vector2(1.05,1.05)
const ORIGIN_SCALE = Vector2(1,1)

const CardNumNames = [ "ace", "two","three","four","five","six", "seven","eight","nine","ten"]
const BossNames = ["jack","queen","king"]
const SuitNames = ["spade","diamond","heart","club"]
const BossValues = [10,15,20]
const CARD_COLLISION_MASK = 1
const CARD_SLOT_COLLISION_MASK = 2
const DECK_COLLISION_MASK = 4
const BOSS_COLLISION_MASK = 5
const FIELD_COLLISION_MASK = 6
const DISCARD_COLLISION_MASK = 7
const MAX_HAND_CARD_NUM = 7
const CARD_SUM_MAX = 10
func sum(x:int,y:Card):
	return x+y.value
func isValidCards(cards:Array[Card],extra:Card)->bool:
	cards = cards.duplicate()
	cards.push_back(extra)
	
	# 如果只有一张牌，则检查其数值是否不超过最大值
	if cards.size() == 1:
		return cards[0].value <= CARD_SUM_MAX
	
	# 检查是否符合出牌规则
	# 规则1: 一张牌（已处理）
	# 规则2: 一张非A牌和若干A（无数值上限）
	# 规则3: 多张相同数值的牌（不包含A）且有数值上限
	
	# 统计不同数值的牌的数量
	var value_counts = {}
	for card in cards:
		if card.value in value_counts:
			value_counts[card.value] += 1
		else:
			value_counts[card.value] = 1
	
	# 获取所有不同的数值
	var values = value_counts.keys()
	
	# 如果有两种数值，其中一种是A（值为1），且非A的牌只有一张，则合法（规则2）
	if values.size() == 2 and 1 in values:
		# 检查非A的牌是否只有一张
		for value in values:
			if value != 1 and value_counts[value] == 1:
				return true
	
	# 如果只有一种数值，且这种数值不是A，则合法（规则3），但需要检查数值上限
	if values.size() == 1 and values[0] != 1:
		var total_sum = cards.reduce(CardData.sum, 0)
		return total_sum <= CARD_SUM_MAX
	
	# 其他情况不合法
	return false
func smooth_move(card:Card,pos:Vector2):
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position",pos,0.1)