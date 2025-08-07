extends CanvasLayer

func _on_hit_button_pressed():
	get_parent()._on_hit_button_pressed()

func _on_stand_button_pressed():
	get_parent()._on_stand_button_pressed()

func _on_play_button_pressed():
	get_parent().start_game()

func _on_restart_button_pressed():
	get_parent().restart_game()
