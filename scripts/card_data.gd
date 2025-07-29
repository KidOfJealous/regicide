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
const COLLISION_MASK_DECK = 4
