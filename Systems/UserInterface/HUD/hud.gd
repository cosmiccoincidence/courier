# hud.gd
# HUD display for player stats
extends CanvasLayer

# Stat Bars
@onready var health_bar: ProgressBar = $StatBars/Health/HealthBar
@onready var stamina_bar: ProgressBar = $StatBars/Stamina/StaminaBar
@onready var mana_bar: ProgressBar = $StatBars/Mana/ManaBar

# Stat Labels
@onready var health_label: Label = $StatBars/Health/HealthBar/HealthLabel
@onready var stamina_label: Label = $StatBars/Stamina/StaminaBar/StaminaLabel
@onready var mana_label: Label = $StatBars/Mana/ManaBar/ManaLabel

# Other UI
@onready var time_label: Label = $TimeLabel
@onready var map_label: Label = $MapLabel
@onready var encumbered_label: Label = $EncumberedLabel
@onready var death_label: Label = $DeathLabel
@onready var ending_label: Label = $EndingLabel 

@export var player: CharacterBody3D

func _ready():
	# Hide percentage displays
	health_bar.show_percentage = false
	stamina_bar.show_percentage = false
	if mana_bar:
		mana_bar.show_percentage = false
	
	# Initialize bars from player stats
	if player:
		var stats = player.get_node_or_null("PlayerStats")
		if stats:
			# New component-based stats
			update_health(stats.current_health, stats.max_health)
			update_stamina(stats.current_stamina, stats.max_stamina)
			update_mana(stats.current_mana, stats.max_mana)
		else:
			# Fallback to old structure
			update_health(player.get("current_health"), player.get("max_health"))
			update_stamina(player.get("current_stamina"), player.get("max_stamina"))
			# No mana in old structure
			if mana_bar:
				mana_bar.visible = false
	
	# Connect to time changes
	TimeManager.time_changed.connect(_on_time_changed)
	update_time_display()
	
	# Connect to map loaded signal
	var map_generator = get_tree().get_first_node_in_group("map_generator")
	if map_generator:
		if map_generator.has_signal("map_loaded"):
			map_generator.map_loaded.connect(_on_map_loaded)
	
	# Update map label initially
	update_map_label()

# ===== STAT BAR UPDATES =====

func update_health(current: int, maximum: int):
	"""Update health bar and label"""
	if not health_bar:
		return
	health_bar.max_value = maximum
	health_bar.value = current
	if health_label:
		health_label.text = "%d/%d" % [current, maximum]

func update_stamina(current: float, maximum: float):
	"""Update stamina bar and label"""
	if not stamina_bar:
		return
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	if stamina_label:
		stamina_label.text = "%.0f/%.0f" % [current, maximum]

func update_mana(current: float, maximum: float):
	"""Update mana bar and label"""
	if not mana_bar:
		return
	mana_bar.max_value = maximum
	mana_bar.value = current
	if mana_label:
		mana_label.text = "%.0f/%.0f" % [current, maximum]

# ===== STATUS UPDATES =====

func update_encumbered_status(is_encumbered: bool, effects_active: bool = true):
	"""Update encumbered warning label"""
	if encumbered_label:
		if is_encumbered:
			encumbered_label.text = "ENCUMBERED!"
			encumbered_label.modulate = Color(1.0, 0.3, 0.3)  # Red tint - penalties active
			encumbered_label.visible = true
		else:
			encumbered_label.visible = false

func show_death_message():
	"""Show death message"""
	if death_label:
		death_label.visible = true

func show_ending_message():
	"""Show ending message"""
	if ending_label:
		ending_label.visible = true

# ===== TIME DISPLAY =====

func update_time_display():
	"""Update time label from TimeManager"""
	if time_label:
		time_label.text = TimeManager.get_full_time_string()

func _on_time_changed(hour: int, minute: int, day: int):
	"""Called when time changes"""
	update_time_display()

# ===== MAP DISPLAY =====

func _on_map_loaded(act_num: int, map_num: int, map_name: String = ""):
	"""Called when a new map is loaded"""
	if map_label:
		if map_name != "":
			# Show map name for special maps (towns, start, end)
			map_label.text = map_name
		else:
			# Show act:map format for regular levels
			map_label.text = "Map %d:%d" % [act_num, map_num]

func update_map_label():
	"""Update map label from map generator"""
	if not map_label:
		return
	
	# Find the map generator in the scene
	var map_generator = get_tree().get_first_node_in_group("map_generator")
	
	if map_generator:
		var act_num = 1  # Default
		var map_num = 1  # Default
		
		# Get act_number if it exists
		if map_generator.has_method("get") and map_generator.get("act_number") != null:
			act_num = map_generator.get("act_number")
		
		# Get map_number if it exists
		if map_generator.has_method("get") and map_generator.get("map_number") != null:
			map_num = map_generator.get("map_number")
		
		map_label.text = "Map %d:%d" % [act_num, map_num]
	else:
		map_label.text = "Map 1:1"  # Fallback
