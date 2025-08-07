extends Node2D

const MAX_CARDS = 52

var cards = []
var suits = ["hearts", "clubs", "diamonds", "spades"]
var values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

func _ready():
	generate_deck()
	shuffle_deck()

func generate_deck():
	for suit in suits:
		for value in values:
			var card_data = {"suit": suit, "value": value}
			cards.append(card_data)
	

func shuffle_deck():
	cards.shuffle()

func draw_card():
	if cards.size() > 0:
		return cards.pop_front()
	else:
		print("Deck is empty! Reshuffling...")
		generate_deck()
		shuffle_deck()
		return cards.pop_front() if cards.size() > 0 else null
