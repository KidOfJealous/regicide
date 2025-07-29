class_name Card extends Node2D
signal hover
const card_scene = preload("res://scenes/card.tscn")
var value:int
var suit:CardData.Suit
var rank:String
var back:bool = false:
	set(value):
		back = value
		$back.visible =back
		$front.visible = !back
		
var hand_position:Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.get_parent().connect_card(self)
	z_index=1

static func init_card_scene(suit:CardData.Suit=CardData.Suit.SPADE,num:CardData.CardNum=CardData.CardNum.ACE,back:bool = false)->Card:
	var card:Card = card_scene.instantiate()
	card.rank =CardData.CardNumNames[num]
	card.suit =suit
	card.value = num+1
	card.back = back
	var image_path = str("res://images/"+CardData.SuitNames[suit]+"_"+card.rank+".png")
	print(image_path)
	(card.get_node("front") as Sprite2D).texture = load(image_path)
	return card
static func init_boss_scene(suit:CardData.Suit=CardData.Suit.SPADE,num:CardData.Boss=CardData.Boss.JACK,back = false)->Card:
	var card:Card = card_scene.instantiate()
	card.rank = CardData.BossNames[num]
	card.suit =suit
	card.value = CardData.BossValues[num]
	(card.get_node("front") as Sprite2D).texture = load(str("res://images/"+CardData.SuitNames[suit]+card.rank+".png"))
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
		self.scale = CardData.HOVER_SCALE
		self.z_index=2
	else:
		self.scale = CardData.ORIGIN_SCALE
		self.z_index=1

func _on_area_2d_mouse_exited() -> void:
	self.hover.emit(self,false)
