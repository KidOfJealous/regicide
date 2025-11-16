extends Node2D
enum CardNum{
	ACE ,
	TWO,
	TREE,
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
	if cards.size()<=1:
		return true
	var val = cards[0].value
	for card in cards:
		if not (card.value==1 or card.value==val):
			return false
	return cards.reduce(CardData.sum,0)<=CARD_SUM_MAX
func smooth_move(card:Card,pos:Vector2):
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position",pos,0.1)
