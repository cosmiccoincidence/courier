# auto_pickup_manager.gd
# Singleton that manages automatic item pickup
extends Node

# Item types that should be automatically picked up
@export var auto_pickup_types: Array[String] = [
	"gold", 
	#"potion", 
	#"food"
	]

# Distance threshold for pickup (in meters/units)
@export var pickup_range: float = 0.5

# Check interval (to avoid checking every frame)
@export var check_interval: float = 0.1

var player: CharacterBody3D = null
var check_timer: float = 0.0

func _ready():
	# Find player
	call_deferred("_find_player")

func _find_player():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("AutoPickupManager: Player not found, will retry...")

func _process(delta):
	# Keep trying to find player if not found
	if not player:
		_find_player()
		return
	
	# Increment timer
	check_timer += delta
	
	# Only check periodically
	if check_timer >= check_interval:
		check_timer = 0.0
		_check_nearby_items()

func _check_nearby_items():
	"""Check for items within pickup range and auto-pickup eligible ones"""
	if not player:
		return
	
	# Get all items in the scene
	var items = get_tree().get_nodes_in_group("item")
	
	for item in items:
		if not is_instance_valid(item) or not item is BaseItem:
			continue
		
		# Check if item type is in auto-pickup list
		if not should_auto_pickup(item):
			continue
		
		# Check horizontal distance (ignore Y axis)
		var player_pos_2d = Vector2(player.global_position.x, player.global_position.z)
		var item_pos_2d = Vector2(item.global_position.x, item.global_position.z)
		var distance = player_pos_2d.distance_to(item_pos_2d)
		
		# If within range, pick it up
		if distance <= pickup_range:
			# Make sure item isn't already being picked up
			if not item.being_picked_up and not item.just_spawned:
				item.pickup()

func should_auto_pickup(item: BaseItem) -> bool:
	"""Check if an item should be automatically picked up"""
	if not item:
		return false
	
	# Check if item type is in the auto-pickup list
	var item_type = item.item_type.to_lower()
	
	for auto_type in auto_pickup_types:
		if item_type == auto_type.to_lower():
			return true
	
	return false

func add_auto_pickup_type(type: String):
	"""Add an item type to auto-pickup list"""
	var lower_type = type.to_lower()
	if not lower_type in auto_pickup_types:
		auto_pickup_types.append(lower_type)
		print("AutoPickup: Added type '%s'" % type)

func remove_auto_pickup_type(type: String):
	"""Remove an item type from auto-pickup list"""
	var lower_type = type.to_lower()
	if lower_type in auto_pickup_types:
		auto_pickup_types.erase(lower_type)
		print("AutoPickup: Removed type '%s'" % type)

func toggle_auto_pickup_type(type: String):
	"""Toggle an item type in the auto-pickup list"""
	var lower_type = type.to_lower()
	if lower_type in auto_pickup_types:
		remove_auto_pickup_type(type)
	else:
		add_auto_pickup_type(type)

func is_auto_pickup_enabled(type: String) -> bool:
	"""Check if a type is enabled for auto-pickup"""
	return type.to_lower() in auto_pickup_types

func get_auto_pickup_types() -> Array[String]:
	"""Get list of enabled auto-pickup types"""
	return auto_pickup_types.duplicate()

func clear_auto_pickup_types():
	"""Remove all auto-pickup types"""
	auto_pickup_types.clear()
	print("AutoPickup: Cleared all types")
