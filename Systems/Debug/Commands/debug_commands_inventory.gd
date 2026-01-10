# debug_commands_inventory.gd
# Inventory-specific commands
extends Node

var console: Control = null
var debug_manager: Node:
	get:
		return get_node_or_null("/root/DebugManager")

func cmd_give_gold(args: Array, output: Control):
	"""Give gold to player"""
	var amount = 1000  # Default amount
	
	# Parse amount if provided
	if args.size() > 0 and args[0].is_valid_int():
		amount = int(args[0])
	
	# Get Inventory autoload
	var inventory = get_node_or_null("/root/Inventory")
	if not inventory:
		output.print_error("[color=#FF4D4D]Error: Inventory autoload not found[/color]")
		output.print_line("[color=#FFFF4D]Make sure 'Inventory' is set up as an autoload[/color]")
		return
	
	# Check if it has InventoryGold as a child or property
	var inventory_gold = null
	
	# Try to get InventoryGold child node
	if inventory.has_node("InventoryGold"):
		inventory_gold = inventory.get_node("InventoryGold")
	# Or check if inventory itself has the add_gold method
	elif inventory.has_method("add_gold"):
		inventory_gold = inventory
	# Or check children for the gold script
	else:
		for child in inventory.get_children():
			if child.has_method("add_gold"):
				inventory_gold = child
				break
	
	if not inventory_gold:
		output.print_error("[color=#FF4D4D]Error: Could not find gold system in Inventory autoload[/color]")
		output.print_line("[color=#FFFF4D]Searched for add_gold() method in Inventory and its children[/color]")
		return
	
	# Add gold
	if inventory_gold.has_method("add_gold"):
		var old_gold = inventory_gold.gold if "gold" in inventory_gold else 0
		inventory_gold.add_gold(amount)
		var new_gold = inventory_gold.gold if "gold" in inventory_gold else 0
		output.print_line("[color=#7FFF7F]Gave %d gold to player (Total: %d)[/color]" % [amount, new_gold])
	else:
		output.print_error("[color=#FF4D4D]Error: No add_gold() method found[/color]")

func cmd_spawn_item(args: Array, output: Control):
	"""Spawn an item with flexible parameters"""
	# Parse arguments: [type] [subtype] [name] [level] [quality] x[quantity]
	var item_type = ""
	var item_subtype = ""
	var item_name = ""
	var level = 1
	var quality = 0
	var quantity = 1
	
	# Valid types and subtypes (lowercase for comparison)
	var valid_types = ["accessory", "armor", "bag", "food", "gemstone", "potion", "trinket", "weapon", "treasure"]
	var valid_subtypes = [
		# Accessory subtypes
		"amulet", "cape", "ring",
		# Armor subtypes
		"belt", "bodyarmor", "gloves", "boots", "helmet", "pants",
		# Bag subtype
		"bag",
		# Food subtype
		"food",
		# Gemstone subtypes
		"charm", "gemstone",
		# Weapon subtypes
		"melee", "ranged", "magic",
		# Treasure subtype
		"coin"
	]
	var valid_qualities = {
		"common": 0,
		"uncommon": 1,
		"rare": 2,
		"epic": 3,
		"legendary": 4,
		"mythic": 5
	}
	
	# Track which args were recognized
	var unrecognized_args = []
	
	output.print_line("[color=#CCCCCC]Parsing: %s[/color]" % str(args))
	
	# Parse each argument
	for arg in args:
		# Strip any quotes from the argument
		arg = arg.strip_edges().replace("'", "").replace('"', "")
		var arg_lower = arg.to_lower()
		var recognized = false
		
		# Check for quantity (starts with 'x')
		if arg.begins_with("x") and arg.length() > 1:
			var qty_str = arg.substr(1)
			if qty_str.is_valid_int():
				quantity = int(qty_str)
				recognized = true
				output.print_line("[color=#CCCCCC]  '%s' → quantity = %d[/color]" % [arg, quantity])
			else:
				output.print_line("[color=#FFFF4D]Ignored: '%s' (invalid quantity)[/color]" % arg)
				continue
		
		# Check for quality (word)
		if not recognized and arg_lower in valid_qualities:
			quality = valid_qualities[arg_lower]
			recognized = true
			output.print_line("[color=#CCCCCC]  '%s' → quality = %d[/color]" % [arg, quality])
		
		# Check for level (number between 1-100)
		if not recognized and arg.is_valid_int():
			var num = int(arg)
			if num >= 1 and num <= 100:
				level = num
				recognized = true
				output.print_line("[color=#CCCCCC]  '%s' → level = %d[/color]" % [arg, level])
			else:
				output.print_line("[color=#FFFF4D]Ignored: '%s' (number out of range)[/color]" % arg)
				continue
		
		# Check for type
		if not recognized and arg_lower in valid_types and item_type == "":
			item_type = arg_lower
			recognized = true
			output.print_line("[color=#CCCCCC]  '%s' → type = %s[/color]" % [arg, item_type])
		
		# Check for subtype
		if not recognized and arg_lower in valid_subtypes and item_subtype == "":
			item_subtype = arg_lower
			recognized = true
			output.print_line("[color=#CCCCCC]  '%s' → subtype = %s[/color]" % [arg, item_subtype])
		
		# If not recognized, it's part of the item name
		if not recognized:
			unrecognized_args.append(arg)
			output.print_line("[color=#CCCCCC]  '%s' → unrecognized (will be item name)[/color]" % arg)
	
	# Join unrecognized args as item name
	if not unrecognized_args.is_empty():
		item_name = " ".join(unrecognized_args)
	
	# If no item name but we have type/subtype, use that for searching
	if item_name == "":
		if item_subtype != "":
			item_name = item_subtype
		elif item_type != "":
			item_name = item_type
	
	output.print_line("[color=#CCCCCC]Final: name='%s', type='%s', subtype='%s', level=%d, quality=%d, qty=%d[/color]" % [item_name, item_type, item_subtype, level, quality, quantity])
	
	# Join unrecognized args as item name
	if not unrecognized_args.is_empty():
		item_name = " ".join(unrecognized_args)
	
	# Build description of what we're spawning
	var desc_parts = []
	if quantity > 1:
		desc_parts.append("x%d" % quantity)
	if item_type != "":
		desc_parts.append(item_type)
	if item_subtype != "":
		desc_parts.append(item_subtype)
	if item_name != "":
		desc_parts.append("'%s'" % item_name)
	if level > 1:
		desc_parts.append("Lv.%d" % level)
	if quality > 0:
		var quality_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
		desc_parts.append(quality_names[quality])
	
	var description = " ".join(desc_parts) if not desc_parts.is_empty() else "random item"
	
	# Delegate to DebugLoot subsystem
	var debug_loot = debug_manager.get_node_or_null("DebugLoot")
	if not debug_loot:
		output.print_error("[color=#FF4D4D]Error: DebugLoot subsystem not found[/color]")
		output.print_line("[color=#FFFF4D]Make sure DebugLoot node exists under DebugManager[/color]")
		return
	
	# Spawn the items
	for i in range(quantity):
		if debug_loot.has_method("spawn_specific_item"):
			debug_loot.spawn_specific_item(item_name, level, quality, item_type, item_subtype)
		else:
			output.print_error("[color=#FF4D4D]Error: spawn_specific_item() method not found[/color]")
			return
	
	output.print_line("[color=#7FFF7F]Spawned: %s[/color]" % description)
