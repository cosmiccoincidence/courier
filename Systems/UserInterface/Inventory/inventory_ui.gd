extends Control

@onready var grid_container: GridContainer = $InventoryPanel/GridContainer
@onready var weight_label: Label = $InventoryPanel/WeightLabel
@onready var gold_label: Label = $InventoryPanel/GoldLabel
@onready var slot_tooltip: Control = $SlotTooltip  # Tooltip manager

# Hardcoded path since export wasn't working
const SLOT_SCENE_PATH = "res://Systems/UserInterface/Inventory/inventory_slot.tscn"

var slot_size: int = 64  # Size of each slot in pixels
var columns: int = 0  # Will be calculated from Inventory.max_slots
var rows: int = 5  # Fixed number of rows

func _input(event):
	"""Handle inventory toggle and drops outside the inventory grid"""
	# Toggle inventory visibility
	if event.is_action_pressed("toggle_inventory"):
		visible = !visible
		
		# Optional: Control mouse mode
		if visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# Uncomment below if you want captured mouse during gameplay
		# else:
		# 	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Handle drops outside the inventory grid
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Check if we're dragging an item
			var InventorySlot = load("res://Systems/UserInterface/Inventory/inventory_slot.gd")
			if InventorySlot and InventorySlot.dragged_item_data != null:
				# Mouse released - check if it's outside the inventory
				var mouse_pos = get_global_mouse_position()
				var grid_rect = grid_container.get_global_rect()
				
				if not grid_rect.has_point(mouse_pos):
					# Dropped outside inventory - drop in world
					Inventory.drop_item_at_slot(InventorySlot.dragged_from_slot)
					
					# Clean up drag state
					var original_slot = _get_slot_by_index(InventorySlot.dragged_from_slot)
					if original_slot:
						original_slot.modulate = Color(1, 1, 1, 1)
					
					InventorySlot.call("_end_drag")

func _get_slot_by_index(index: int) -> Panel:
	"""Get a slot by its index"""
	var slots = grid_container.get_children()
	if index >= 0 and index < slots.size():
		return slots[index]
	return null

func _ready():
	# Calculate columns based on Inventory.max_slots
	columns = Inventory.max_slots / rows
	
	# Create tooltip manager if it doesn't exist
	if not slot_tooltip:
		slot_tooltip = Control.new()
		slot_tooltip.name = "SlotTooltip"
		add_child(slot_tooltip)
		
		# Attach tooltip script
		var tooltip_script = load("res://Systems/UserInterface/Inventory/inventory_slot_tooltip.gd")
		if tooltip_script:
			slot_tooltip.set_script(tooltip_script)
		else:
			push_warning("Could not load inventory_slot_tooltip.gd - tooltips will not work")
	
	# Make the main InventoryPanel transparent (so only slots are visible)
	var panel = $InventoryPanel
	if panel:
		var transparent_style = StyleBoxFlat.new()
		transparent_style.bg_color = Color(0, 0, 0, 0)  # Fully transparent
		panel.add_theme_stylebox_override("panel", transparent_style)
		# Panel should pass mouse events to children
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Load slot scene directly
	var slot_scene = load(SLOT_SCENE_PATH)
	
	if not slot_scene:
		push_error("Could not load slot scene from: ", SLOT_SCENE_PATH)
		return
	
	# IMPORTANT: Allow slots to receive mouse events
	# Don't set mouse_filter to IGNORE on the main control!
	# mouse_filter = Control.MOUSE_FILTER_IGNORE  # REMOVED - this blocks all mouse events
	
	# Set up the grid
	grid_container.columns = columns
	# CRITICAL: GridContainer must pass mouse events to children
	grid_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Create all the slots based on calculated grid size
	for i in range(columns * rows):
		var slot = slot_scene.instantiate()
		if not slot:
			continue
		
		# Force it to STOP
		slot.set_mouse_filter(Control.MOUSE_FILTER_STOP)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.slot_index = i
		slot.add_to_group("inventory_slots")  # Add to group for easy lookup
		grid_container.add_child(slot)
		
		# Set tooltip manager reference
		if slot.has_method("set_tooltip_manager") and slot_tooltip:
			slot.set_tooltip_manager(slot_tooltip)
	
	# Connect to inventory changes
	Inventory.inventory_changed.connect(_update_inventory)
	Inventory.weight_changed.connect(_update_weight_display)
	Inventory.gold_changed.connect(_update_gold_display)
	_update_inventory()
	_update_weight_display(Inventory.get_total_weight(), Inventory.soft_max_weight)
	_update_gold_display(Inventory.get_gold())
	
	# Start hidden
	hide()

func _update_inventory():
	var items = Inventory.get_items()
	var slots = grid_container.get_children()
	
	# Update each slot
	for i in range(slots.size()):
		if i < items.size():
			slots[i].set_item(items[i])
		else:
			slots[i].clear_item()

func _update_weight_display(current_weight: float, max_weight: float):
	if weight_label:
		# Format: "Weight: 5.5 / 10.0"
		weight_label.text = "Weight: %.1f / %.1f" % [current_weight, max_weight]
		
		# Optional: Change color based on weight
		var weight_percent = current_weight / max_weight
		if weight_percent >= 1.0:
			weight_label.modulate = Color.DARK_RED  # Over soft limit
		elif weight_percent >= 0.9:
			weight_label.modulate = Color.RED  # High warning
		elif weight_percent >= 0.75:
			weight_label.modulate = Color.YELLOW  # Low warning
		else:
			weight_label.modulate = Color.WHITE  # Normal

func _update_gold_display(amount: int):
	if gold_label:
		gold_label.text = "Gold: %d" % amount
