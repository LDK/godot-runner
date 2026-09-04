extends Collectible

func _on_collect(runner: Runner) -> void:
	print("Hello")
	if runner is Enemy:
		var enemy = runner as Enemy
		enemy.has_gold = true
	elif runner is Hero:
		var hero = runner as Hero
		print("Oh")
		hero.gold_collected.emit()
		
