# debug_commands_enemy.gd
# Enemy-specific debug commands
extends Node

var console: Control = null
var debug_manager: Node = null

func _ready():
	debug_manager = get_node_or_null("/root/DebugManager")

func cmd_kill(output: Control):
	"""Kill closest enemy to player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	# Find all enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		output.print_line("[color=#FFAA55]No enemies found[/color]")
		return
	
	# Find closest enemy
	var closest_enemy = null
	var closest_distance = INF
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = player.global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	
	if not closest_enemy:
		output.print_line("[color=#FFAA55]No valid enemies found[/color]")
		return
	
	# Kill the enemy
	if closest_enemy.has_method("die"):
		# Set dying flag if it exists
		if "is_dying" in closest_enemy:
			closest_enemy.is_dying = true
		closest_enemy.die()
		output.print_line("[color=#FF4D4D]Killed closest enemy (%.1fm away)[/color]" % closest_distance)
	elif closest_enemy.has_method("take_damage"):
		closest_enemy.take_damage(99999, false)
		output.print_line("[color=#FF4D4D]Killed closest enemy (%.1fm away)[/color]" % closest_distance)
	else:
		output.print_line("[color=#FF4D4D]Enemy has no die() or take_damage() method[/color]")

func cmd_kill_all(output: Control):
	"""Kill all enemies on the map"""
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		output.print_line("[color=#FFAA55]No enemies found[/color]")
		return
	
	var killed_count = 0
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			# Kill the enemy
			if enemy.has_method("die"):
				# Set dying flag if it exists
				if "is_dying" in enemy:
					enemy.is_dying = true
				enemy.die()
				killed_count += 1
			elif enemy.has_method("take_damage"):
				enemy.take_damage(99999, false)
				killed_count += 1
	
	if killed_count > 0:
		output.print_line("[color=#FF4D4D]Killed %d enemies[/color]" % killed_count)
	else:
		output.print_line("[color=#FFAA55]No valid enemies to kill[/color]")
