# debug_commands_world.gd
# World-specific commands
extends Node

var console: Control = null
var debug_manager: Node:
	get:
		return get_node_or_null("/root/DebugManager")

func cmd_time(args: Array, output: Control):
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
