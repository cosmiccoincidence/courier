extends Panel
# Inventory Slot

var slot_index: int = -1
var item_data = null
var tooltip_manager: Control = null  # Reference to tooltip manager

@onready var icon: TextureRect = $TextureRect
@onready var label: Label = $Label

func _ready():
	# Force mouse filters
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if icon:
		icon.set_mouse_filter(MOUSE_FILTER_IGNORE)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(48, 48)
		# Center the icon in the slot
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = -24
		icon.offset_top = -24
		icon.offset_right = 24
		icon.offset_bottom = 24
		
	if label:
		label.set_mouse_filter(MOUSE_FILTER_IGNORE)
		# Configure label at bottom of slot
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Position at bottom
		label.anchor_left = 0
		label.anchor_top = 1
		label.anchor_right = 1
		label.anchor_bottom = 1
		label.offset_left = 2
		label.offset_top = -16
		label.offset_right = -2
		label.offset_bottom = -2
		# Smaller font
		label.add_theme_font_size_override("font_size", 12)
	
	# Style
	custom_minimum_size = Vector2(64, 64)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel", style)

func _process(_delta):
	# Enforce mouse filter every frame (something keeps resetting it)
	if mouse_filter != Control.MOUSE_FILTER_STOP:
		mouse_filter = Control.MOUSE_FILTER_STOP
	
	# WORKAROUND: Since mouse_entered/exited signals aren't working,
	# manually check if mouse is over this slot
	if visible and is_visible_in_tree():
		var mouse_pos = get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, size)
		var mouse_over = rect.has_point(mouse_pos)
		
		# Only call tooltip functions when hover state CHANGES
		if mouse_over and item_data and tooltip_manager:
			# Mouse is over slot with item - show tooltip only if not already showing
			if not get_meta("tooltip_showing", false):
				if tooltip_manager.has_method("show_tooltip"):
					tooltip_manager.show_tooltip(self, item_data)
					set_meta("tooltip_showing", true)
		else:
			# Mouse not over or no item - hide tooltip only if currently showing
			if get_meta("tooltip_showing", false):
				if tooltip_manager and tooltip_manager.has_method("hide_tooltip"):
					tooltip_manager.hide_tooltip()
				set_meta("tooltip_showing", false)

func set_tooltip_manager(manager: Control):
	"""Set reference to the tooltip manager"""
	tooltip_manager = manager

func set_item(item):
	item_data = item
	if item and item.has("icon") and item.icon:
		icon.texture = item.icon
		icon.show()
	else:
		icon.hide()
	
	if item and item.has("name"):
		# Show stack count if stackable
		if item.get("stackable", false) and item.get("stack_count", 1) > 1:
			label.text = "%s (x%d)" % [item.name, item.stack_count]
		else:
			label.text = item.name
		label.show()
	else:
		label.hide()

func clear_item():
	item_data = null
	icon.hide()
	label.hide()

# Use _input instead of _gui_input to test
func _input(event):
	if not visible or not is_visible_in_tree():
		return
		
	if event is InputEventMouseButton and event.pressed:
		# Check if mouse is over this slot
		var local_pos = get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, size)
		
		if rect.has_point(local_pos):
			if event.button_index == MOUSE_BUTTON_RIGHT and item_data:
				Inventory.drop_item_at_slot(slot_index)
				get_viewport().set_input_as_handled()
