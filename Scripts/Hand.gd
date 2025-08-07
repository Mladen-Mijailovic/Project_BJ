extends Node2D

var cards_in_hand = []
@export var card_scene: PackedScene

func add_card(card_data, is_hidden = false):
	if card_data:
		cards_in_hand.append({"data": card_data, "hidden": is_hidden})
		spawn_card(card_data, is_hidden)
		return update_hand_value()
	return {"total": 0, "cards": [], "has_aces": false}

func spawn_card(card_data, is_hidden):
	var new_card = card_scene.instantiate()
	new_card.card_data = card_data
	new_card.position = Vector2(cards_in_hand.size() * 50, 0)
	add_child(new_card)
	
	if is_hidden:
		new_card.get_node("Sprite2D").texture = load("res://Assets/Cards/card_back.png")
	else:
		new_card.update_card()

func update_hand_value():
	var total = 0
	var aces = 0
	var card_values = []
	var is_blackjack = false
	
	for card in cards_in_hand:
		var value = card["data"]["value"]
		var numeric_value = 0
		
		match value:
			"A":
				numeric_value = 11
				aces += 1
			"J", "Q", "K":
				numeric_value = 10
			_:
				numeric_value = int(value)
		
		total += numeric_value
		card_values.append(numeric_value)
	
	var i = card_values.size() - 1
	while total > 21 and aces > 0 and i >= 0:
		if card_values[i] == 11:
			total -= 10
			aces -= 1
			card_values[i] = 1
		i -= 1
	
	if cards_in_hand.size() == 2 and total == 21:
		is_blackjack = true
	
	return {
		"total": total,
		"cards": card_values,
		"has_aces": aces > 0,
		"is_blackjack" : is_blackjack
	}

func split_hand():
	if cards_in_hand.size() != 2:
		return null
	
	for child in get_children():
		if child is Card:
			child.queue_free()
	
	var split_card = cards_in_hand.pop_back()
	cards_in_hand = []
	
	return split_card["data"]

func get_card_values():
	var values = []
	for card in cards_in_hand:
		values.append(card["data"]["value"])
	return values

func reveal_hidden_cards():
	for i in range(cards_in_hand.size()):
		if cards_in_hand[i]["hidden"]:
			cards_in_hand[i]["hidden"] = false
			get_child(i).update_card()
