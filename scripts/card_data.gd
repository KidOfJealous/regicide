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
const CARD_OVERLAP_RATIO = 0.1  # 10%的重叠比例

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
	
	# 如果只有一张牌，则合法（规则1）
	if cards.size() == 1:
		return true
	
	# 检查是否符合出牌规则
	# 规则2: 一张牌（可以是A）和若干A
	# 规则3: 一些相同数值的牌且总数值和不能超过上界
	
	# 统计不同数值的牌的数量
	var value_counts = {}
	var ace_count = 0
	for card in cards:
		if card.value == 1:  # A的值为1
			ace_count += 1
		if card.value in value_counts:
			value_counts[card.value] += 1
		else:
			value_counts[card.value] = 1
	
	# 获取所有不同的数值
	var values = value_counts.keys()
	
	# 规则2: 一张牌（可以是A）和若干A
	# 如果有A，且除了A之外只有一种其他数值，且这种数值的牌只有一张
	if ace_count > 0 and values.size() == 2:  # 有两种数值：A和其他一种
		# 检查非A的牌是否只有一张
		for value in values:
			if value != 1 and value_counts[value] == 1:
				return true
	
	# 规则3: 一些相同数值的牌且总数值和不能超过上界
	# 如果只有一种数值（可以是A或非A），则检查总和是否超过上限
	if values.size() == 1:
		var total_sum = cards.reduce(CardData.sum, 0)
		return total_sum <= CARD_SUM_MAX
	
	# 其他情况不合法
	return false
func smooth_move(card:Card,pos:Vector2):
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position",pos,0.1)
