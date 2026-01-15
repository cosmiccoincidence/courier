# debug_commands_fov.gd
# FOV/fog of war debug commands
extends Node

var console: Control = null
var debug_manager: Node = null

func _ready():
	debug_manager = get_node_or_null("/root/DebugManager")

func _get_fog_system() -> Node:
	"""Find the FogOfWar node in the scene"""
	return get_tree().root.find_child("FogOfWar", true, false)

func _get_vision_cone() -> Node:
	"""Find the VisionCone node in the scene"""
	return get_tree().root.find_child("VisionCone", true, false)

func cmd_fov(output: Control):
	"""Toggle FOV system"""
	var fog_system = _get_fog_system()
	var vision_cone = _get_vision_cone()
	
	if not fog_system and not vision_cone:
		output.print_line("[color=#FF4D4D]Error: FOV system not found[/color]")
		return
	
	# Toggle both systems
	var toggled = false
	
	if fog_system and fog_system.has_method("debug_toggle_system"):
		fog_system.debug_toggle_system()
		toggled = true
	
	if vision_cone and vision_cone.has_method("debug_toggle_system"):
		vision_cone.debug_toggle_system()
		toggled = true
	
	if toggled:
		# Check the current state
		var is_disabled = false
		if fog_system and "debug_disabled" in fog_system:
			is_disabled = fog_system.debug_disabled
		elif vision_cone and "debug_disabled" in vision_cone:
			is_disabled = vision_cone.debug_disabled
		
		if is_disabled:
			output.print_line("[color=#FFFF4D]FOV system DISABLED[/color]")
		else:
			output.print_line("[color=#7FFF7F]FOV system ENABLED[/color]")
	else:
		output.print_line("[color=#FF4D4D]Error: FOV system has no toggle method[/color]")

func cmd_explore(output: Control):
	"""Reveal entire fog of war"""
	var fog_system = _get_fog_system()
	
	if not fog_system:
		output.print_line("[color=#FF4D4D]Error: FogOfWar not found[/color]")
		return
	
	# Check if system is disabled
	if fog_system.get("debug_disabled"):
		output.print_line("[color=#FFAA55]Cannot reveal - FOV system is disabled[/color]")
		output.print_line("[color=#CCCCCC]Enable with 'fov' command first[/color]")
		return
	
	if fog_system.has_method("reveal_all"):
		fog_system.reveal_all()
		
		# Count revealed tiles
		var revealed_count = 0
		if "revealed_tiles" in fog_system:
			for tile_key in fog_system.revealed_tiles.keys():
				if fog_system.revealed_tiles[tile_key]:
					revealed_count += 1
		
		output.print_line("[color=#7FFF7F]Entire map revealed (%d tiles)[/color]" % revealed_count)
	else:
		output.print_line("[color=#FF4D4D]Error: FogOfWar has no reveal_all() method[/color]")

func cmd_unexplore(output: Control):
	"""Reset fog of war"""
	var fog_system = _get_fog_system()
	
	if not fog_system:
		output.print_line("[color=#FF4D4D]Error: FogOfWar not found[/color]")
		return
	
	# Check if system is disabled
	if fog_system.get("debug_disabled"):
		output.print_line("[color=#FFAA55]Cannot reset - FOV system is disabled[/color]")
		output.print_line("[color=#CCCCCC]Enable with 'fov' command first[/color]")
		return
	
	if fog_system.has_method("debug_reset_fog"):
		fog_system.debug_reset_fog()
		
		# Count reset tiles
		var reset_count = 0
		if "revealed_tiles" in fog_system:
			for tile_key in fog_system.revealed_tiles.keys():
				if not fog_system.revealed_tiles[tile_key]:
					reset_count += 1
		
		output.print_line("[color=#7FFF7F]Fog of war reset (%d tiles)[/color]" % reset_count)
	else:
		output.print_line("[color=#FF4D4D]Error: FogOfWar has no debug_reset_fog() method[/color]")
