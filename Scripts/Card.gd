extends Node2D
class_name Card

@export var card_data: Dictionary 
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var deal_sound = $DealSoundPlayer

func _ready():
	if card_data:
		update_card()
		play_deal_animation()

func update_card():
	if card_data:
		var textute_path = "res://Assets/Cards/card_%s_%s.png" % [card_data["suit"], card_data["value"]]
		sprite.texture = load(textute_path)

func play_deal_animation():
	scale = Vector2.ZERO
	rotation = deg_to_rad(-180)
	deal_sound.play()
	#Kreiranje animacije
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", Vector2(1,1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(self, "rotation", 0.0, 0.5).set_ease(Tween.EASE_OUT)

func is_card() -> bool:
	return true
