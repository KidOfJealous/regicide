class_name Card extends Node2D
signal hover
static var CARD_WIDTH = 73.2
static var CARD_LENGTH = 102.4
static var hover_scale = Vector2(1.05,1.05)
static var origin_scale = Vector2(1,1)
enum CardNum{
	ACE = 1,
	TWO,
	TREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
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
