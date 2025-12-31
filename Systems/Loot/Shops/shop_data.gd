# shop_data.gd
# Resource that defines a shop's inventory and configuration
class_name ShopData
extends Resource

@export var shop_name: String = "General Store"
@export var shop_gold: int = 1000  # How much gold the shop has

# Item pool - specific items this shop sells
@export_group("Shop Inventory")
@export var item_pool: Array[LootItem] = []  # Specific items to sell (if empty, uses all_items from LootManager)

# Item type filtering - which types of items can be sold
@export_group("Item Type Filtering")
@export var allowed_item_types: Array[String] = []  # If empty, allows all types
@export var excluded_item_types: Array[String] = []  # Blacklist specific types

# Price modifiers
@export_group("Pricing")
@export var buy_price_multiplier: float = 1.25  # Player buys at 125% of base value
@export var sell_price_multiplier: float = 0.75  # Player sells at 75% of base value

# Markup/Markdown system (random price variations)
@export var price_variation_chance: float = 0.3  # 30% chance for price variation
@export var markup_range: Vector2 = Vector2(1.1, 1.5)  # 110% to 150% for marked up items
@export var markdown_range: Vector2 = Vector2(0.7, 0.9)  # 70% to 90% for marked down items

# Stock system
@export_group("Stock Management")
@export var default_stock_min: int = 1  # Minimum stock per item
@export var default_stock_max: int = 5  # Maximum stock per item
@export var infinite_stock_items: Array[String] = []  # Item names that never run out (e.g., ["Bread", "Water"])

# Item level restrictions
@export_group("Level Restrictions")
@export var max_item_level: int = 99  # Don't show items above this level
@export var min_item_level: int = 1   # Don't show items below this level

# Internal data (auto-populated)
var item_stock: Dictionary = {}  # LootItem -> stock count (0 = out of stock)
var special_prices: Dictionary = {}  # LootItem -> float multiplier
var _initialized: bool = false

func _init():
	# Initialize will be called when shop opens
	pass

func initialize():
	"""Initialize stock and prices - call this when shop opens"""
	if _initialized:
		return
	
	_initialized = true
	_initialize_stock()
	_apply_price_variations()

func _initialize_stock():
	"""Set initial stock for all items in the shop"""
	var items_to_stock: Array[LootItem] = []
	
	# Determine which items to stock
	if not item_pool.is_empty():
		# Use specific item pool
		items_to_stock = item_pool
	else:
		# Use all items from LootManager, filtered by type
		if LootManager and "all_items" in LootManager:
			items_to_stock = _filter_items_by_type(LootManager.all_items)
		else:
			push_warning("ShopData: LootManager not found or has no all_items")
	
	# Set stock for each item
	for item in items_to_stock:
		if not item_stock.has(item):
			# Check if this item has infinite stock
			if item.item_name in infinite_stock_items:
				item_stock[item] = 999  # Large number to represent "infinite"
			else:
				item_stock[item] = randi_range(default_stock_min, default_stock_max)

func _filter_items_by_type(all_items: Array) -> Array[LootItem]:
	"""Filter items by allowed/excluded types"""
	var filtered: Array[LootItem] = []
	
	for item in all_items:
		if not item is LootItem:
			continue
		
		# Check excluded types
		if item.item_type in excluded_item_types:
			continue
		
		# Check allowed types (if specified)
		if not allowed_item_types.is_empty():
			if not item.item_type in allowed_item_types:
				continue
		
		# Note: item_level filtering happens when items are generated, not here
		# LootItem resources don't have item_level - it's assigned during generation
		
		filtered.append(item)
	
	return filtered

func _apply_price_variations():
	"""Randomly mark up or mark down some items"""
	var items_to_vary: Array[LootItem] = []
	
	# Get items to apply variations to
	if not item_pool.is_empty():
		items_to_vary = item_pool
	elif item_stock.size() > 0:
		items_to_vary.assign(item_stock.keys())
	
	for item in items_to_vary:
		if randf() < price_variation_chance:
			# Randomly choose markup or markdown
			if randf() < 0.5:
				# Markup
				special_prices[item] = randf_range(markup_range.x, markup_range.y)
			else:
				# Markdown
				special_prices[item] = randf_range(markdown_range.x, markdown_range.y)

func get_buy_price(item: LootItem) -> int:
	"""Get the price the player pays to buy this item"""
	var base_price = item.base_value
	var multiplier = buy_price_multiplier
	
	# Check for special pricing
	if special_prices.has(item):
		multiplier = special_prices[item]
	
	return int(base_price * multiplier)

func get_sell_price(item_value: int) -> int:
	"""Get the price the shop pays when player sells an item"""
	return int(item_value * sell_price_multiplier)

func has_stock(item: LootItem) -> bool:
	"""Check if item is in stock"""
	return item_stock.get(item, 0) > 0

func get_stock(item: LootItem) -> int:
	"""Get stock count for an item"""
	return item_stock.get(item, 0)

func remove_stock(item: LootItem, amount: int = 1) -> bool:
	"""Remove stock when player buys"""
	# Check for infinite stock
	if item.item_name in infinite_stock_items:
		return true  # Never runs out
	
	if has_stock(item):
		item_stock[item] = max(0, item_stock[item] - amount)
		return true
	return false

func add_stock(item: LootItem, amount: int = 1):
	"""Add stock when player sells"""
	# Don't add to infinite stock items
	if item.item_name in infinite_stock_items:
		return
	
	if item_stock.has(item):
		item_stock[item] += amount
	else:
		item_stock[item] = amount

func can_afford_to_buy_from_player(price: int) -> bool:
	"""Check if shop has enough gold to buy from player"""
	return shop_gold >= price

func is_item_level_valid(item_level: int) -> bool:
	"""Check if item level is within shop's range"""
	return item_level >= min_item_level and item_level <= max_item_level

func get_all_items() -> Array[LootItem]:
	"""Get all items this shop can sell (for display)"""
	if not item_pool.is_empty():
		return item_pool
	else:
		# Return items from stock
		var items: Array[LootItem] = []
		items.assign(item_stock.keys())
		return items
