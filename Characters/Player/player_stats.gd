# player_stats.gd
# Handles all player stats, health, stamina, mana, and stat calculations
extends Node

# Reference to main player
var player: CharacterBody3D

# Calculator component
var calculator: Node

# ===== 6 CORE STATS =====
# Formula: stat = class_base + upgrades + gear + buffs

@export_group("Base Stats - Current Total")
@export var strength: int = 10
@export var dexterity: int = 10
@export var fortitude: int = 10
@export var vitality: int = 10
@export var agility: int = 10
@export var arcane: int = 10

# Class base values (set at character creation)
var class_strength: int = 10
var class_dexterity: int = 10
var class_fortitude: int = 10
var class_vitality: int = 10
var class_agility: int = 10
var class_arcane: int = 10

# NPC upgrades (purchased at towns)
var upgrade_strength: int = 0
var upgrade_dexterity: int = 0
var upgrade_fortitude: int = 0
var upgrade_vitality: int = 0
var upgrade_agility: int = 0
var upgrade_arcane: int = 0

# Gear bonuses
var gear_strength: int = 0
var gear_dexterity: int = 0
var gear_fortitude: int = 0
var gear_vitality: int = 0
var gear_agility: int = 0
var gear_arcane: int = 0

# Buff bonuses (shrines, auras, skills)
var buff_strength: int = 0
var buff_dexterity: int = 0
var buff_fortitude: int = 0
var buff_vitality: int = 0
var buff_agility: int = 0
var buff_arcane: int = 0

# Special stat
@export var luck: float = 0.0  # Affects loot quality/quantity

# ===== RESOURCES =====
@export_group("Resources")

# Health (vitality * 10 + gear + buffs)
var max_health: int = 100
var current_health: int = 100
var gear_max_health: int = 0
var buff_max_health: int = 0

# Stamina (agility * 10 + gear + buffs)
var max_stamina: int = 100
var current_stamina: float = 100
var gear_max_stamina: int = 0
var buff_max_stamina: int = 0

# Mana (arcane * 10 + gear + buffs)
var max_mana: int = 100
var current_mana: float = 100
var gear_max_mana: int = 0
var buff_max_mana: int = 0

# ===== REGEN RATES =====
# Formula: (stat * 0.1) + gear + buffs

var health_regen_rate: float = 1.0
var stamina_regen_rate: float = 1.0
var mana_regen_rate: float = 1.0

var gear_health_regen: float = 0.0
var gear_stamina_regen: float = 0.0
var gear_mana_regen: float = 0.0

var buff_health_regen: float = 0.0
var buff_stamina_regen: float = 0.0
var buff_mana_regen: float = 0.0

@export var health_regen_interval: float = 10.0
@export var stamina_regen_interval: float = 0.5
@export var mana_regen_interval: float = 2.0

# Regen timers
var time_since_last_health_regen: float = 0.0
var time_since_last_stamina_regen: float = 0.0
var time_since_last_mana_regen: float = 0.0
var time_since_sprint_stopped: float = 0.0
var stamina_regen_delay: float = 1.0

# ===== DEFENSE STATS =====
@export_group("Defense")

# Armor (base + gear + buffs)
@export var base_armor: int = 5
var armor: int = 5
var gear_armor: int = 0
var buff_armor: int = 0

# Resistances (gear + buffs + fortitude bonus)
var fire_resistance: float = 0.0
var frost_resistance: float = 0.0
var static_resistance: float = 0.0
var poison_resistance: float = 0.0

var gear_fire_resistance: float = 0.0
var gear_frost_resistance: float = 0.0
var gear_static_resistance: float = 0.0
var gear_poison_resistance: float = 0.0

var buff_fire_resistance: float = 0.0
var buff_frost_resistance: float = 0.0
var buff_static_resistance: float = 0.0
var buff_poison_resistance: float = 0.0

# Source-based damage reductions
var enemy_damage_reduction: float = 0.0  # vs elites + bosses
var environment_damage_reduction: float = 0.0  # vs hazards + traps

var gear_enemy_damage_reduction: float = 0.0
var gear_environment_damage_reduction: float = 0.0

var buff_enemy_damage_reduction: float = 0.0
var buff_environment_damage_reduction: float = 0.0

# ===== STATE =====
var is_encumbered: bool = false
var is_invincible: bool = false

# ===== SIGNALS =====
signal health_changed(current: int, max_value: int)
signal stamina_changed(current: float, max_value: float)
signal mana_changed(current: float, max_value: float)
signal stats_updated
signal encumbered_changed(is_encumbered: bool, effects_active: bool)

# ===== GOD MODE CONSTANTS =====
const GOD_CRIT_CHANCE := 1.0
const GOD_CRIT_MULT := 2.0

# ===== INITIALIZATION =====

func initialize(player_node: CharacterBody3D):
	"""Called by player to set reference and calculate initial stats"""
	player = player_node
	
	# Create calculator component
	var calculator_script = load("res://Characters/Player/player_stats_calculator.gd")
	if calculator_script:
		calculator = Node.new()
		calculator.name = "StatsCalculator"
		calculator.set_script(calculator_script)
		add_child(calculator)
		calculator.initialize(self)
	
	# Set starting health/stamina/mana to max
	recalculate_all_stats()
	current_health = max_health
	current_stamina = max_stamina
	current_mana = max_mana
	
	# Connect to Inventory encumbered status
	Inventory.encumbered_status_changed.connect(_on_encumbered_status_changed)

# ===== STAT CALCULATION =====

func recalculate_all_stats():
	"""Recalculate all derived stats from base stats + gear + buffs"""
	if calculator:
		calculator.calculate_core_stats()
		calculator.calculate_resources()
		calculator.calculate_regen_rates()
		calculator.calculate_defenses()
	stats_updated.emit()

# Removed: _recalculate_core_stats() - now in calculator
# Removed: _recalculate_resources() - now in calculator
# Removed: _recalculate_regen_rates() - now in calculator
# Removed: _recalculate_defenses() - now in calculator

# ===== STAT UPGRADES =====

func add_stat_upgrade(stat_name: String):
	"""Add a stat upgrade (from NPC training)"""
	match stat_name.to_lower():
		"strength":
			upgrade_strength += 1
		"dexterity":
			upgrade_dexterity += 1
		"fortitude":
			upgrade_fortitude += 1
		"vitality":
			upgrade_vitality += 1
		"agility":
			upgrade_agility += 1
		"arcane":
			upgrade_arcane += 1
	
	recalculate_all_stats()

# ===== PROCESS =====

func _process(delta):
	"""Handle regeneration"""
	if not player or player.is_dying:
		return
	
	# Health regen
	time_since_last_health_regen += delta
	if time_since_last_health_regen >= health_regen_interval:
		_regenerate_health()
		time_since_last_health_regen = 0.0
	
	# Mana regen
	time_since_last_mana_regen += delta
	if time_since_last_mana_regen >= mana_regen_interval:
		_regenerate_mana()
		time_since_last_mana_regen = 0.0
	
	# Stamina regen (with sprint delay)
	time_since_last_stamina_regen += delta
	if time_since_sprint_stopped >= stamina_regen_delay:
		if time_since_last_stamina_regen >= stamina_regen_interval:
			_regenerate_stamina()
			time_since_last_stamina_regen = 0.0

func _regenerate_health():
	"""Regenerate health based on regen rate"""
	if current_health < max_health:
		current_health = min(max_health, current_health + int(health_regen_rate))
		health_changed.emit(current_health, max_health)

func _regenerate_stamina():
	"""Regenerate stamina based on regen rate"""
	if current_stamina < max_stamina:
		current_stamina = min(max_stamina, current_stamina + stamina_regen_rate)
		stamina_changed.emit(current_stamina, max_stamina)

func _regenerate_mana():
	"""Regenerate mana based on regen rate"""
	if current_mana < max_mana:
		current_mana = min(max_mana, current_mana + mana_regen_rate)
		mana_changed.emit(current_mana, max_mana)

# ===== RESOURCE USAGE =====

func use_stamina(amount: float):
	"""Use stamina"""
	current_stamina = max(0, current_stamina - amount)
	stamina_changed.emit(current_stamina, max_stamina)

func use_mana(amount: float):
	"""Use mana"""
	current_mana = max(0, current_mana - amount)
	mana_changed.emit(current_mana, max_mana)

func update_sprint_state(is_sprinting: bool, delta: float):
	"""Called by player to update sprint-related timers"""
	if is_sprinting:
		time_since_sprint_stopped = 0.0
	else:
		time_since_sprint_stopped += delta

# ===== DAMAGE =====

func take_damage(amount: int):
	"""Apply damage to player"""
	if player.god_mode:
		print("God Mode: Damage blocked")
		return
	
	# Check invincibility frames
	if is_invincible:
		print("I-frames: Damage blocked")
		return
	
	# Apply armor reduction
	var damage_taken = max(1, amount - armor)
	current_health = max(0, current_health - damage_taken)
	
	print("Player took %d damage (%d reduced by %d armor)" % [damage_taken, amount, armor])
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		player.die()

func set_invincible(invincible: bool):
	"""Set invincibility state (for i-frames)"""
	is_invincible = invincible
	if is_invincible:
		print("[PlayerStats] I-frames: Invincibility ACTIVE")
	else:
		print("[PlayerStats] I-frames: Invincibility ENDED")

# ===== ENCUMBRANCE =====

func _on_encumbered_status_changed(encumbered: bool):
	"""Called when inventory mass changes encumbered state"""
	is_encumbered = encumbered
	var effects_active = is_encumbered and not player.god_mode
	encumbered_changed.emit(is_encumbered, effects_active)
