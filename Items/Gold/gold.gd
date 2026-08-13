extends Collectible

func _on_collect(runner: Runner) -> void:
	if runner is Enemy:
		var enemy = runner as Enemy
		enemy.has_gold = true
	elif runner is Hero:
		var hero = runner as Hero
		hero.gold_collected.emit()
		
