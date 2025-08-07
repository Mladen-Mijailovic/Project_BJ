extends Node

#Globalne pormenljive
var split_count = 0
var max_splits = 4
var can_double_var = false
var game_started = false
var double_card_hidden = false
var current_bet = 0
var player_tokens = 100
var active_hands = []
var current_hand_index = 0
var next_hand_button = Button.new()

#Globalne reference
@onready var deck = $Deck
@onready var player_hand = $Player/Hand
@onready var dealer_hand = $Dealer/Hand
#Play/Restart
@onready var play_button = $UI/PlayButton
#Dugmici za igru
@onready var container_box = $UI/VBC_Buttons2
@onready var hit_button = $UI/VBC_Buttons2/HitButton
@onready var stand_button = $UI/VBC_Buttons2/StandButton
@onready var split_button = $UI/VBC_Buttons2/SplitButton
@onready var double_button = $UI/VBC_Buttons2/DoubleButton
#Labels
@onready var result_label = $UI/ResultLabel
#Betting
@onready var cb_bet = $UI/VBC_Betting
@onready var bet_label = $UI/VBC_Betting/BetLabel
@onready var bet_slider = $UI/VBC_Betting/BetSlider
@onready var tokens_label = $UI/VBC_Betting/TokenLabel
@onready var confirm_button = $UI/VBC_Betting/ConfirmBetButton

func _ready():
	container_box.visible = false
	setup_next_hand_button()
	show_controls()
	bet_setup()
	
	for button in [play_button, split_button, hit_button, stand_button, double_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_release_focus.bind(button))


func start_game():
	if game_started:
		#Brise sve karte
		for child in player_hand.get_children():
			child.queue_free()
		for child in dealer_hand.get_children():
			child.queue_free()
		
		#Resetuje spil
		deck.generate_deck()
		deck.shuffle_deck()
	
	if player_tokens <= 0:
		reset_game()
		return
	
	if not cb_bet.visible:
		#UI
		game_started = true
		ui_control()
		restart_next_hand_button()
		del_cards()
		update_bet_ui()
		
		split_count = 0
		can_double_var = true
		double_card_hidden = false
		
		#Resetuje ruke
		player_hand.cards_in_hand = []
		dealer_hand.cards_in_hand = []
		
		deal_initial_cards()
		current_hand_index = 0
		active_hands = [player_hand]
		
		update_double_button()

func setup_next_hand_button():
	next_hand_button.text = "Next Hand"
	next_hand_button.size = Vector2(150, 50)
	next_hand_button.position = Vector2(500, 50)
	next_hand_button.hide()
	next_hand_button.pressed.connect(_on_next_hand_button_pressed)
	add_child(next_hand_button)

func restart_next_hand_button():
	next_hand_button.hide()  # Sakrijte dugme na početku runde
	next_hand_button.disconnect("pressed", _on_next_hand_button_pressed)  # Bezbedno diskonektujte (opciono)
	next_hand_button.pressed.connect(_on_next_hand_button_pressed)  # Ponovo povežite (ako je potrebno)

func _on_next_hand_button_pressed():
	current_hand_index += 1
	
	if current_hand_index < active_hands.size():
		update_ui_for_current_hand()
	else:
		next_hand_button.hide()
		current_hand_index = 0
		stand_button.disabled = false

func update_ui_for_current_hand():
	var current_hand = active_hands[current_hand_index]
	var can_split_current = can_split_hand(current_hand)
	
	split_button.visible = can_split_current
	split_button.disabled = !can_split_current
	
	for i in range(active_hands.size()):
		if i == current_hand_index:
			active_hands[i].modulate = Color(1, 1, 1)
		else:
			active_hands[i].modulate = Color(0.7, 0.7, 0.7)
	
	if current_hand_index == active_hands.size() - 1:
		next_hand_button.text = "Last Split"
	else:
		next_hand_button.text = "Next Hand"

func can_split() -> bool:
	if split_count >= max_splits:
		return false
	var current_hand = active_hands[current_hand_index]
	return can_split_hand(current_hand)

func can_split_hand(hand) -> bool:
	print("--- Checking split conditions ---")
	print("Split count:", split_count, "/ Max splits:", max_splits)
	print("Double card hidden:", double_card_hidden)
	print("Cards in hand:", hand.cards_in_hand.size())
		
	if split_count >= max_splits:
		print("❌ Split count limit reached")
		return false
	if double_card_hidden:
		print("❌ Double card is hidden (cannot split after double)")
		return false
	if hand.cards_in_hand.size() != 2:
		print("❌ Hand does not have exactly 2 cards")
		return false
	# Ispravan pristup podacima karata
	var card1_data = hand.cards_in_hand[0]["data"]
	var card2_data = hand.cards_in_hand[1]["data"]
		
	var card1_value = card1_data["value"]
	var card2_value = card2_data["value"]
		
	print("Card 1:", card1_value, "| Card 2:", card2_value)
		
	if card1_value == card2_value:
		print("✅ Cards match - split allowed")
		return true
	else:
		print("❌ Cards do not match")
		return false
		
func deal_initial_cards():
	#Igrac - 1. karta
	await deal_card_to_player(false)
	#Diler - 1. karta
	await deal_card_to_dealer(false)
	#Igrac - 2. karta
	await deal_card_to_player(false)
	#Diler - 2. karta (okrenuta)
	await deal_card_to_dealer(true)
	
	update_split_button()
	update_double_button()
	
	check_blackjack()
	

func deal_card_to_player(is_hidden: bool):
	var card = deck.draw_card()
	if card:
		await get_tree().create_timer(0.1).timeout #Pauza izmedju karata
		player_hand.add_card(card, is_hidden)

func deal_card_to_dealer(is_hidden: bool):
	var card = deck.draw_card()
	if card:
		await get_tree().create_timer(0.1).timeout
		dealer_hand.add_card(card, is_hidden)

func check_blackjack():
	var player_values = player_hand.get_card_values()
	var dealer_values = dealer_hand.get_card_values()
	
	#Provera za Igraca
	var player_has_blackjack = player_values.has("A") and any_match(player_values, ["10", "J", "Q", "K"])
	
	if player_has_blackjack:
		#Provera za vidljivu kartu
		var dealers_upcard = dealer_values[0]
		var dealers_upcard_is_10 = dealers_upcard in ["10", "J", "Q", "K"]
		
		if dealers_upcard_is_10:
			dealer_hand.reveal_hidden_cards()
			if dealer_values.has("A") and dealer_values.size() == 2:
				game_over("Push! Both have BlackJack.")
			else:
				pass
		else:
			game_over("BlackJack! Player wins")
	else:
		pass
	#var player_cards = player_hand.get_card_values()
	#var dealer_cards = dealer_hand.get_card_values()
	#
	#if player_cards.has("A") and (player_cards.has("10") or player_cards.has("J") or player_cards.has("Q") or player_cards.has("K")):
		#if dealer_cards.has("A") or dealer_cards.has("10") or dealer_cards.has("J") or dealer_cards.has("Q") or dealer_cards.has("K"):
			#return
		#else:
			#game_over("Blackjack! Player wins!")

func any_match(values, targets):
	for value in values:
		if value in targets:
			return true
	return false

func game_over(message: String):
	player_hand.reveal_hidden_cards()
	dealer_hand.reveal_hidden_cards()
	
	for hand in active_hands:
		hand.modulate = Color.WHITE
		hand.reveal_hidden_cards()
	
	hit_button.disabled = true
	stand_button.disabled = true
	double_button.disabled = true
	split_button.disabled = true
	
	next_hand_button.hide()
	
	double_button.text = "DOUBLE"
	
	result_label.text = message
	result_label.visible = true
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	result_label.size = Vector2(400, 150)
	
	update_bet_ui()
	bet_setup()

func _on_hit_button_pressed():
	if current_bet <= 0:
		return
	
	var current_hand = active_hands[current_hand_index]
	var card = deck.draw_card()
	
	if card:
		var result = current_hand.add_card(card)
		if result["total"] > 21:
			if current_hand_index < active_hands.size() - 1:
				_on_next_hand_button_pressed()
			else:
				game_over("Player busts! Dealer wins.")
		else:
			update_split_button()
			update_double_button()

func _on_split_button_pressed():
	if current_bet <= 0:
		return
	
	if can_split():
		split_count += 1
		
		#Kreira novu instancu ruke
		var new_hand = load("res://Scenes/Hand.tscn").instantiate()
		get_node("Player").add_child(new_hand)
		new_hand.position = player_hand.position + Vector2(0, -80 * split_count)
		
		var split_card = active_hands[current_hand_index].cards_in_hand.pop_back()
		active_hands[current_hand_index].get_child(1).queue_free()
		
		new_hand.add_card(split_card["data"])
		active_hands.append(new_hand)
		
		active_hands[current_hand_index].add_card(deck.draw_card())
		new_hand.add_card(deck.draw_card())
		
		next_hand_button.show()
		update_split_button()
		update_double_button()
		
		if can_split_hand(new_hand):
			split_button.disabled = false
		else:
			split_button.disabled = true

func update_split_button():
	var can_split_now = can_split()
	split_button.visible = can_split_now
	split_button.disabled = !can_split_now
	
	print("Can split: ", can_split_now)
	print("Cards: ", player_hand.get_card_values())

func _on_double_button_pressed():
	if current_bet <= 0:
		return
	
	if !double_card_hidden:
		if can_double():
			current_bet *= 2
			player_hand.add_card(deck.draw_card(), true)
			double_card_hidden = true
			double_button.text = "FLIP"
			stand_button.disabled = true
			hit_button.disabled = true
			split_button.disabled = true
	else:
		player_hand.reveal_hidden_cards()
		double_button.visible = false
		stand_button.disabled = false
		dealer_turn()

func can_double() -> bool:
	var total = player_hand.update_hand_value()["total"]
	
	return (player_hand.get_card_values().size() == 2 and 
			(total == 9 or total == 10 or total == 11) and 
			split_count == 0)

func update_double_button():
	double_button.visible = can_double() or double_card_hidden
	double_button.disabled = !can_double() and !double_card_hidden

func _on_stand_button_pressed():
	dealer_turn()

func dealer_turn():
	dealer_hand.reveal_hidden_cards()
	
	while dealer_hand.update_hand_value()["total"] < 17:
		var new_card = deck.draw_card()
		if new_card:
			dealer_hand.add_card(new_card)
		else:
			break
	check_winner()

func check_winner():
	dealer_hand.reveal_hidden_cards()
	var dealer_total = dealer_hand.update_hand_value()["total"]
	var dealer_bust = dealer_total > 21
	
	var final_result = ""
	var all_results = []
	
	var total_payout = 0
	
	for i in range(active_hands.size()):
		var hand = active_hands[i]
		var hand_result = hand.update_hand_value()
		var hand_total = hand_result["total"]
		
		var result_text = "Ruka %d (%s): " % [i+1, hand_total]
		if hand_total > 21:
			result_text += "Bust!"
			hand.modulate = Color(1, 0.5, 0.5)
		elif dealer_bust or hand_total > dealer_total:
			var payout = current_bet * 1.5
			if hand_result["is_blackjack"]:
				payout = current_bet * 2.5
			total_payout += payout
			result_text += "Win! (Dealer bust: %d)" % dealer_total
			hand.modulate = Color(0.5, 1, 0.5)
		elif hand_total == dealer_total:
			total_payout += current_bet
			result_text += "Push. (Dealer hand: %d)" % dealer_total
			hand.modulate = Color(1, 1, 0.8)
		else:
			result_text += "Lost. (Dealer hand: %d)" % dealer_total
			hand.modulate = Color(1, 0.5, 0.5)
		
		all_results.append(result_text)
	player_tokens += total_payout
	update_bet_ui()	
	
	final_result = "\n".join(all_results)
	
	final_result = "Diler: %d\n%s" % [dealer_total, final_result]
	game_over(final_result)
	
	if player_tokens <= 0:
		await check_player_balance()
	else:
		game_over("Osvojeno: %d tokena" % (total_payout - current_bet * active_hands.size()))

func ui_control():
	#Reset UI
	#OFF
	container_box.visible = true
	result_label.visible = false
	cb_bet.visible = false
	#ON 
	#Reset func
	play_button.disabled = false
	hit_button.disabled = false
	stand_button.disabled = false
	double_button.disabled = true
	split_button.disabled = true
	
	play_button.text = "RESET"
	double_button.text = "DOUBLE"
	

func _release_focus(button):
	await get_tree().process_frame
	button.release_focus()

func _unhandled_input(event):
	if not game_started:
		if event.is_action_pressed("reset_action"):
			start_game()
		return
	
	if event.is_action_pressed("hit_action") and hit_button.visible and not hit_button.disabled:
		_on_hit_button_pressed()
	elif event.is_action_pressed("stand_action") and stand_button.visible and not stand_button.disabled:
		_on_stand_button_pressed()
	elif event.is_action_pressed("double_action") and double_button.visible and not double_button.disabled:
		_on_double_button_pressed()
	elif event.is_action_pressed("split_action") and split_button.visible and not split_button.disabled:
		_on_split_button_pressed()
	elif event.is_action_pressed("reset_action"):
		start_game()

func del_cards():
	if game_started:
		for hand in active_hands:
			if hand != player_hand:
				hand.queue_free()
		player_hand.modulate = Color.WHITE

func show_hand_result(results):
	for i in range(active_hands.size()):
		var hand = active_hands[i]
		var result_label = Label.new()
		result_label.text = results[i]
		result_label.position = hand.position + Vector2(0, -50)
		add_child(result_label)
		
		if "Win" in results[i]:
			hand.modulate = Color(0.5, 1, 0.5)
		elif "Lost" in results[i]:
			hand.modulate = Color(1, 0.5, 0.5)
		else:
			hand.modulate = Color(1, 1, 0.5)

func show_controls():
	var controls_label = Label.new()
	controls_label.text = "Controls: Hit-Space, S-Stand, D-Double, F-Split, R-Reset"
	controls_label.position = Vector2(20,20)
	add_child(controls_label)

func bet_setup():
	cb_bet.visible = true
	bet_slider.min_value = 1
	bet_slider.max_value = player_tokens
	bet_slider.value = 10
	update_bet_ui()

func update_bet_ui():
	tokens_label.text = "Tokens: %d" % player_tokens
	bet_label.text = "Amount: %d" % current_bet
	bet_slider.max_value = player_tokens

func _on_bet_slider_value_changed(value):
	current_bet = int(value)
	bet_label.text = "Amount: %d" % current_bet

func _on_confirm_bet_button_pressed():
	if current_bet > 0 and current_bet <= player_tokens:
		player_tokens -= current_bet
		update_bet_ui()
		cb_bet.visible = false
		start_game()

func check_player_balance():
	if player_tokens <= 0:
		game_over("Nemate vise tokena. Igra se resetuje.")
		await get_tree().create_timer(2.0)
		reset_game()

func reset_game():
	player_tokens = 100
	current_bet = 0
	game_started = false
	update_bet_ui()
	cb_bet.visible = true
	
	for child in player_hand.get_children():
		child.queue_free()
	for child in dealer_hand.get_children():
		child.queue_free()
	
	split_count = 0
	active_hands = [player_hand]
	current_hand_index = 0
