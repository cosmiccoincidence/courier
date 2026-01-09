# player_stats_calculator.gd
# Handles all stat calculations and derivations
extends Node

# Reference to stats component
var stats: Node

func initialize(stats_component: Node):
	"""Called by player_stats to set reference"""
	stats = stats_component

# ===== CORE STAT CALCULATIONS =====

func calculate_core_stats():
	"""Calculate final core stat values from class + upgrades + gear + buffs"""
	stats.strength = stats.class_strength + stats.upgrade_strength + stats.gear_strength + stats.buff_strength
	stats.dexterity = stats.class_dexterity + stats.upgrade_dexterity + stats.gear_dexterity + stats.buff_dexterity
	stats.fortitude = stats.class_fortitude + stats.upgrade_fortitude + stats.gear_fortitude + stats.buff_fortitude
	stats.vitality = stats.class_vitality + stats.upgrade_vitality + stats.gear_vitality + stats.buff_vitality
	stats.agility = stats.class_agility + stats.upgrade_agility + stats.gear_agility + stats.buff_agility
	stats.arcane = stats.class_arcane + stats.upgrade_arcane + stats.gear_arcane + stats.buff_arcane

# ===== RESOURCE CALCULATIONS =====

func calculate_resources():
	"""Calculate max health, stamina, mana and adjust current values proportionally"""
	var old_max_health = stats.max_health
	var old_max_stamina = stats.max_stamina
	var old_max_mana = stats.max_mana
	
	# Max HP = vitality * 10 + gear + buffs
	stats.max_health = (stats.vitality * 10) + stats.gear_max_health + stats.buff_max_health
	
	# Max Stamina = agility * 10 + gear + buffs
	stats.max_stamina = (stats.agility * 10) + stats.gear_max_stamina + stats.buff_max_stamina
	
	# Max Mana = arcane * 10 + gear + buffs
	stats.max_mana = (stats.arcane * 10) + stats.gear_max_mana + stats.buff_max_mana
	
	# Adjust current values proportionally if max changed
	_adjust_current_health(old_max_health)
	_adjust_current_stamina(old_max_stamina)
	_adjust_current_mana(old_max_mana)
	
	# Emit signals
	stats.health_changed.emit(stats.current_health, stats.max_health)
	stats.stamina_changed.emit(stats.current_stamina, stats.max_stamina)
	stats.mana_changed.emit(stats.current_mana, stats.max_mana)

func _adjust_current_health(old_max: int):
	"""Adjust current health proportionally when max changes"""
	if old_max > 0:
		var health_percent = float(stats.current_health) / float(old_max)
		stats.current_health = int(health_percent * stats.max_health)
	else:
		stats.current_health = stats.max_health

func _adjust_current_stamina(old_max: int):
	"""Adjust current stamina proportionally when max changes"""
	if old_max > 0:
		var stamina_percent = stats.current_stamina / float(old_max)
		stats.current_stamina = stamina_percent * stats.max_stamina
	else:
		stats.current_stamina = stats.max_stamina

func _adjust_current_mana(old_max: int):
	"""Adjust current mana proportionally when max changes"""
	if old_max > 0:
		var mana_percent = stats.current_mana / float(old_max)
		stats.current_mana = mana_percent * stats.max_mana
	else:
		stats.current_mana = stats.max_mana

# ===== REGEN CALCULATIONS =====

func calculate_regen_rates():
	"""Calculate HP/Stamina/Mana regen rates: (stat * 0.1) + gear + buffs"""
	# HP Regen = vitality * 0.1 + gear + buffs
	stats.health_regen_rate = (stats.vitality * 0.1) + stats.gear_health_regen + stats.buff_health_regen
	
	# Stamina Regen = agility * 0.1 + gear + buffs
	stats.stamina_regen_rate = (stats.agility * 0.1) + stats.gear_stamina_regen + stats.buff_stamina_regen
	
	# Mana Regen = arcane * 0.1 + gear + buffs
	stats.mana_regen_rate = (stats.arcane * 0.1) + stats.gear_mana_regen + stats.buff_mana_regen

# ===== DEFENSE CALCULATIONS =====

func calculate_defenses():
	"""Calculate armor and all resistances"""
	_calculate_armor()
	_calculate_resistances()
	_calculate_damage_reductions()

func _calculate_armor():
	"""Calculate armor: base + gear + buffs"""
	stats.armor = stats.base_armor + stats.gear_armor + stats.buff_armor

func _calculate_resistances():
	"""Calculate elemental resistances: gear + buffs + (fortitude * 0.02)"""
	var fortitude_bonus = stats.fortitude * 0.02  # 2% per point
	
	stats.fire_resistance = stats.gear_fire_resistance + stats.buff_fire_resistance + fortitude_bonus
	stats.frost_resistance = stats.gear_frost_resistance + stats.buff_frost_resistance + fortitude_bonus
	stats.static_resistance = stats.gear_static_resistance + stats.buff_static_resistance + fortitude_bonus
	stats.poison_resistance = stats.gear_poison_resistance + stats.buff_poison_resistance + fortitude_bonus

func _calculate_damage_reductions():
	"""Calculate source-based damage reductions"""
	stats.enemy_damage_reduction = stats.gear_enemy_damage_reduction + stats.buff_enemy_damage_reduction
	stats.environment_damage_reduction = stats.gear_environment_damage_reduction + stats.buff_environment_damage_reduction

# ===== COMBAT STAT CALCULATIONS =====
# These will be implemented when combat system is updated

func calculate_crit_chance() -> float:
	"""Calculate crit chance: (dexterity * bonus) + gear + buffs"""
	# Base from dexterity (e.g., 1% per point)
	var base_crit = stats.dexterity * 0.01
	
	# TODO: Add gear_crit_chance and buff_crit_chance when implemented
	# var total = base_crit + gear_crit_chance + buff_crit_chance
	
	return base_crit

func calculate_crit_damage() -> float:
	"""Calculate crit damage multiplier: base + (dexterity * bonus) + gear + buffs"""
	# Base multiplier
	var base_mult = 1.5  # 150% damage on crit
	
	# Bonus from dexterity (e.g., 2% per point)
	var dex_bonus = stats.dexterity * 0.02
	
	# TODO: Add gear_crit_damage and buff_crit_damage when implemented
	# var total = base_mult + dex_bonus + gear_crit_damage + buff_crit_damage
	
	return base_mult + dex_bonus

func calculate_carry_capacity() -> float:
	"""Calculate carry capacity: base + (strength * 2.0)"""
	var base_capacity = 20.0  # Base carry weight
	var strength_bonus = stats.strength * 2.0  # 2 mass per strength point
	
	return base_capacity + strength_bonus

func calculate_equipment_requirements_reduction() -> int:
	"""Calculate equipment requirement reduction from strength"""
	# Each point of strength reduces requirements by 1
	# If item needs 20 STR, and player has 15 STR, they need 5 more points
	return stats.strength

# ===== UTILITY FUNCTIONS =====

func get_total_stat_bonuses(stat_name: String) -> int:
	"""Get total bonuses (upgrades + gear + buffs) for a stat"""
	match stat_name.to_lower():
		"strength":
			return stats.upgrade_strength + stats.gear_strength + stats.buff_strength
		"dexterity":
			return stats.upgrade_dexterity + stats.gear_dexterity + stats.buff_dexterity
		"fortitude":
			return stats.upgrade_fortitude + stats.gear_fortitude + stats.buff_fortitude
		"vitality":
			return stats.upgrade_vitality + stats.gear_vitality + stats.buff_vitality
		"agility":
			return stats.upgrade_agility + stats.gear_agility + stats.buff_agility
		"arcane":
			return stats.upgrade_arcane + stats.gear_arcane + stats.buff_arcane
	
	return 0

func get_stat_breakdown(stat_name: String) -> Dictionary:
	"""Get detailed breakdown of where a stat's value comes from"""
	var breakdown = {
		"class_base": 0,
		"upgrades": 0,
		"gear": 0,
		"buffs": 0,
		"total": 0
	}
	
	match stat_name.to_lower():
		"strength":
			breakdown.class_base = stats.class_strength
			breakdown.upgrades = stats.upgrade_strength
			breakdown.gear = stats.gear_strength
			breakdown.buffs = stats.buff_strength
			breakdown.total = stats.strength
		"dexterity":
			breakdown.class_base = stats.class_dexterity
			breakdown.upgrades = stats.upgrade_dexterity
			breakdown.gear = stats.gear_dexterity
			breakdown.buffs = stats.buff_dexterity
			breakdown.total = stats.dexterity
		"fortitude":
			breakdown.class_base = stats.class_fortitude
			breakdown.upgrades = stats.upgrade_fortitude
			breakdown.gear = stats.gear_fortitude
			breakdown.buffs = stats.buff_fortitude
			breakdown.total = stats.fortitude
		"vitality":
			breakdown.class_base = stats.class_vitality
			breakdown.upgrades = stats.upgrade_vitality
			breakdown.gear = stats.gear_vitality
			breakdown.buffs = stats.buff_vitality
			breakdown.total = stats.vitality
		"agility":
			breakdown.class_base = stats.class_agility
			breakdown.upgrades = stats.upgrade_agility
			breakdown.gear = stats.gear_agility
			breakdown.buffs = stats.buff_agility
			breakdown.total = stats.agility
		"arcane":
			breakdown.class_base = stats.class_arcane
			breakdown.upgrades = stats.upgrade_arcane
			breakdown.gear = stats.gear_arcane
			breakdown.buffs = stats.buff_arcane
			breakdown.total = stats.arcane
	
	return breakdown

func can_equip_item(required_stats: Dictionary) -> bool:
	"""Check if player meets stat requirements for equipment"""
	if required_stats.has("strength") and stats.strength < required_stats.strength:
		return false
	if required_stats.has("dexterity") and stats.dexterity < required_stats.dexterity:
		return false
	if required_stats.has("fortitude") and stats.fortitude < required_stats.fortitude:
		return false
	
	return true

func get_missing_requirements(required_stats: Dictionary) -> Dictionary:
	"""Get how many stat points are missing for equipment"""
	var missing = {}
	
	if required_stats.has("strength"):
		var diff = required_stats.strength - stats.strength
		if diff > 0:
			missing.strength = diff
	
	if required_stats.has("dexterity"):
		var diff = required_stats.dexterity - stats.dexterity
		if diff > 0:
			missing.dexterity = diff
	
	if required_stats.has("fortitude"):
		var diff = required_stats.fortitude - stats.fortitude
		if diff > 0:
			missing.fortitude = diff
	
	return missing
