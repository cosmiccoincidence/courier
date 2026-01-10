# debug_commands.gd
# Processes commands from the debug console
extends Node

var debug_manager: Node = null
var console: Control = null

func _ready():
	debug_manager = get_parent()

func set_console(console_ref: Control):
	"""Set the console reference"""
	console = console_ref

func toggle_console():
	"""Toggle the console visibility"""
	if console and console.has_method("toggle_console"):
		console.toggle_console()

func process_command(command: String, output: Control):
	"""Process a debug command"""
	# Parse command and arguments
	var parts = command.split(" ", false)
	if parts.is_empty():
		return
	
	var cmd = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []
	
	# Execute command
	match cmd:
		"help":
			_cmd_help(output)
		"clear":
			_cmd_clear(output)
		"spawn":
			_cmd_spawn(args, output)
		"tp", "teleport":
			_cmd_teleport(args, output)
		"give":
			_cmd_give(args, output)
		"stat":
			_cmd_stat(args, output)
		"kill":
			_cmd_kill(args, output)
		"heal":
			_cmd_heal(args, output)
		"god":
			_cmd_god(output)
		"speed":
			_cmd_speed(args, output)
		"time":
			_cmd_time(args, output)
		_:
			output.print_line("[color=#FF4D4D]Unknown command: '%s'. Type 'help' for available commands.[/color]" % cmd)

func _cmd_help(output: Control):
	"""Show help for all commands"""
	output.print_line("[color=#4DAAFF]═══ AVAILABLE COMMANDS ═══[/color]")
	output.print_line("[color=#7FFF7F]help[/color] - Show this help")
	output.print_line("[color=#7FFF7F]clear[/color] - Clear console output")
	output.print_line("[color=#7FFF7F]spawn <item> [level] [quality][/color] - Spawn an item")
	output.print_line("[color=#7FFF7F]give <item> [amount][/color] - Add item to inventory")
	output.print_line("[color=#7FFF7F]tp <x> <y> <z>[/color] - Teleport player")
	output.print_line("[color=#7FFF7F]stat <name> <value>[/color] - Set player stat")
	output.print_line("[color=#7FFF7F]heal [amount][/color] - Heal player")
	output.print_line("[color=#7FFF7F]kill[/color] - Kill player")
	output.print_line("[color=#7FFF7F]god[/color] - Toggle god mode")
	output.print_line("[color=#7FFF7F]speed <multiplier>[/color] - Set movement speed")
	output.print_line("[color=#7FFF7F]time <hour>[/color] - Set time of day")

func _cmd_clear(output: Control):
	"""Clear console output"""
	output.clear_output()
	output.print_line("[color=#4DAAFF]Console cleared[/color]")

func _cmd_spawn(args: Array, output: Control):
	"""Spawn an item in the world"""
	if args.is_empty():
		output.print_line("[color=#FFFF4D]Usage: spawn <item_name> [level] [quality][/color]")
		output.print_line("[color=#CCCCCC]Example: spawn sword 10 3[/color]")
		return
	
	var item_name = args[0]
	var level = int(args[1]) if args.size() > 1 else 1
	var quality = int(args[2]) if args.size() > 2 else 0
	
	# Delegate to DebugLoot subsystem
	var debug_loot = debug_manager.get_node_or_null("DebugLoot")
	if debug_loot and debug_loot.has_method("spawn_specific_item"):
		debug_loot.spawn_specific_item(item_name, level, quality)
		output.print_line("[color=#7FFF7F]Spawned: %s (Lv.%d, Quality %d)[/color]" % [item_name, level, quality])
	else:
		output.print_line("[color=#FF4D4D]Error: DebugLoot subsystem not available[/color]")

func _cmd_teleport(args: Array, output: Control):
	"""Teleport player to coordinates"""
	if args.size() < 3:
		output.print_line("[color=#FFFF4D]Usage: tp <x> <y> <z>[/color]")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var pos = Vector3(float(args[0]), float(args[1]), float(args[2]))
	player.global_position = pos
	output.print_line("[color=#7FFF7F]Teleported to: (%.1f, %.1f, %.1f)[/color]" % [pos.x, pos.y, pos.z])

func _cmd_give(args: Array, output: Control):
	"""Give item to player inventory"""
	if args.is_empty():
		output.print_line("[color=#FFFF4D]Usage: give <item_name> [amount][/color]")
		return
	
	var item_name = args[0]
	var amount = int(args[1]) if args.size() > 1 else 1
	
	output.print_line("[color=#FFFF4D]Give command not yet implemented[/color]")
	# TODO: Implement inventory addition

func _cmd_stat(args: Array, output: Control):
	"""Set player stat"""
	if args.size() < 2:
		output.print_line("[color=#FFFF4D]Usage: stat <name> <value>[/color]")
		output.print_line("[color=#CCCCCC]Stats: strength, dexterity, vitality, fortitude, agility, arcane[/color]")
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var stat_name = args[0].to_lower()
	var value = int(args[1])
	
	var stats = player.get_node_or_null("PlayerStats")
	if not stats:
		output.print_line("[color=#FF4D4D]Error: PlayerStats not found[/color]")
		return
	
	# Set the stat
	if stat_name in stats:
		stats.set(stat_name, value)
		if stats.has_method("recalculate_all_stats"):
			stats.recalculate_all_stats()
		output.print_line("[color=#7FFF7F]Set %s to %d[/color]" % [stat_name, value])
	else:
		output.print_line("[color=#FF4D4D]Unknown stat: %s[/color]" % stat_name)

func _cmd_kill(args: Array, output: Control):
	"""Kill the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var stats = player.get_node_or_null("PlayerStats")
	if stats and "current_health" in stats:
		stats.current_health = 0
		output.print_line("[color=#FF4D4D]Player killed[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: Could not kill player[/color]")

func _cmd_heal(args: Array, output: Control):
	"""Heal the player"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	var amount = float(args[0]) if not args.is_empty() else -1.0
	
	var stats = player.get_node_or_null("PlayerStats")
	if stats:
		if amount > 0:
			stats.current_health = min(stats.current_health + amount, stats.max_health)
			output.print_line("[color=#7FFF7F]Healed for %d HP[/color]" % int(amount))
		else:
			stats.current_health = stats.max_health
			output.print_line("[color=#7FFF7F]Fully healed[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: PlayerStats not found[/color]")

func _cmd_god(output: Control):
	"""Toggle god mode"""
	var debug_player = debug_manager.get_node_or_null("DebugPlayer")
	if debug_player and debug_player.has_method("toggle_god_mode"):
		debug_player.toggle_god_mode()
		output.print_line("[color=#FFFF4D]God mode toggled[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: DebugPlayer subsystem not available[/color]")

func _cmd_speed(args: Array, output: Control):
	"""Set movement speed multiplier"""
	if args.is_empty():
		output.print_line("[color=#FFFF4D]Usage: speed <multiplier>[/color]")
		return
	
	var multiplier = float(args[0])
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		output.print_line("[color=#FF4D4D]Error: No player found[/color]")
		return
	
	if "speed" in player:
		var base_speed = player.get("base_speed") if "base_speed" in player else 5.0
		player.speed = base_speed * multiplier
		output.print_line("[color=#7FFF7F]Speed set to x%.1f[/color]" % multiplier)
	else:
		output.print_line("[color=#FF4D4D]Error: Player has no speed property[/color]")

func _cmd_time(args: Array, output: Control):
	"""Set time of day"""
	if args.is_empty():
		output.print_line("[color=#FFFF4D]Usage: time <hour>[/color]")
		output.print_line("[color=#CCCCCC]Hour: 0-23 (0 = midnight, 12 = noon)[/color]")
		return
	
	var hour = int(args[0])
	var debug_time = debug_manager.get_node_or_null("DebugTime")
	if debug_time and debug_time.has_method("set_time"):
		debug_time.set_time(hour)
		output.print_line("[color=#7FFF7F]Time set to %02d:00[/color]" % hour)
	else:
		output.print_line("[color=#FF4D4D]Error: DebugTime subsystem not available[/color]")
