class_name Card extends Node2D
signal hover
static var CARD_WIDTH = 73.2
static var CARD_LENGTH = 102.4
static var hover_scale = Vector2(1.05,1.05)
static var origin_scale = Vector2(1,1)
static var card_scene = preload("res://scenes/card.tscn")
static var nums = [ "ace", "two","three","four","five","six", "seven","eight","nine","ten"]
static var boss_nums = ["jack","queen","king"]
static var boss_values = [10,15,20]
var value:int
var suit:Suit
var num:String
var back:bool = false:
	set(value):
		back = value
		$back.visible =back
		$front.visible = !back
		
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
var hand_position:Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.get_parent().connect_card(self)
	z_index=1

static func init_card_scene(suit:Suit=Suit.SPADE,num:CardNum=CardNum.ACE,back:bool = false)->Card:
	var card:Card = card_scene.instantiate()
	card.num =nums[num]
	card.suit =suit
	card.value = num+1
	card.back = back
	return card
static func init_boss_scene(suit:Suit=Suit.SPADE,num:Boss=Boss.JACK,back = false)->Card:
	var card:Card = card_scene.instantiate()
	card.num = boss_nums[num]
	card.suit =suit
	card.value = boss_values[num]
	card.back = back
	return card
# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	self.hover.emit(self,true)
	
func set_hover(b:bool):
	if b :
		self.scale = hover_scale
		self.z_index=2
	else:
		self.scale = origin_scale
		self.z_index=1

func _on_area_2d_mouse_exited() -> void:
	self.hover.emit(self,false)
