# loot_stat_generator.gd
# Generates item stat dictionaries from LootItem resources
# Rolls all stats based on level and quality
class_name LootStatGenerator
extends RefCounted

static func generate_item_stats(loot_item: Resource, item_level: int = 1, item_quality: int = 0) -> Dictionary:
	"""
	Create a full item dictionary from a LootItem resource.
	Rolls stats based on level and quality.
	
	item_level: 1-100, affects stat values
	item_quality: 0-5 (0=normal, 1=magic, 2=rare, 3=epic, 4=legendary, 5=mythic)
	"""
	
	var item = {
		# ===== BASIC INFO =====
		"name": loot_item.item_name,
		"icon": loot_item.icon,  # Add icon texture
		"type": loot_item.item_type,
		"subtype": loot_item.item_subtype,
		"level": item_level,
		"quality": item_quality,
		
		# ===== PHYSICAL =====
		"mass": loot_item.mass,
		"value": _calculate_value(loot_item.base_value, item_level, item_quality),
		"durability": loot_item.durability,
		"stackable": loot_item.stackable,
		"max_stack_size": loot_item.max_stack_size,
		
		# ===== REQUIREMENTS =====
		"required_strength": loot_item.required_strength,
		"required_dexterity": loot_item.required_dexterity,
		"required_fortitude": loot_item.required_fortitude,
		
		# ===== CORE STAT BONUSES =====
		"strength": loot_item.bonus_strength,
		"dexterity": loot_item.bonus_dexterity,
		"fortitude": loot_item.bonus_fortitude,
		"vitality": loot_item.bonus_vitality,
		"agility": loot_item.bonus_agility,
		"arcane": loot_item.bonus_arcane,
		
		# ===== RESOURCES =====
		"max_health": loot_item.bonus_max_health,
		"max_stamina": loot_item.bonus_max_stamina,
		"max_mana": loot_item.bonus_max_mana,
		
		# ===== REGEN =====
		"health_regen": loot_item.bonus_health_regen,
		"stamina_regen": loot_item.bonus_stamina_regen,
		"mana_regen": loot_item.bonus_mana_regen,
		
		# ===== RESISTANCES =====
		"fire_resistance": loot_item.bonus_fire_resistance,
		"frost_resistance": loot_item.bonus_frost_resistance,
		"static_resistance": loot_item.bonus_static_resistance,
		"poison_resistance": loot_item.bonus_poison_resistance,
		
		# ===== DAMAGE REDUCTION =====
		"enemy_damage_reduction": loot_item.bonus_enemy_damage_reduction,
		"environment_damage_reduction": loot_item.bonus_environment_damage_reduction,
		
		# ===== COMBAT =====
		"attack_speed": loot_item.bonus_attack_speed,
		"crit_chance": loot_item.bonus_crit_chance,
		"crit_damage": loot_item.bonus_crit_damage,
		
		# ===== MOVEMENT =====
		"movement_speed": loot_item.bonus_movement_speed,
		
		# ===== ABILITY COSTS =====
		"sprint_stamina_cost": loot_item.bonus_sprint_stamina_cost,
		"dodge_roll_stamina_cost": loot_item.bonus_dodge_roll_stamina_cost,
		"dash_stamina_cost": loot_item.bonus_dash_stamina_cost,
	}
	
	# Roll stats based on item type
	match loot_item.item_type.to_lower():
		"weapon":
			_add_weapon_stats(item, loot_item, item_level, item_quality)
		"armor":
			_add_armor_stats(item, loot_item, item_level, item_quality)
		"accessory":
			_add_accessory_stats(item, loot_item, item_level, item_quality)
	
	return item

static func _add_weapon_stats(item: Dictionary, loot_item: Resource, level: int, quality: int):
	"""Add rolled weapon stats to item"""
	var weapon_stats = WeaponStatRoller.roll_weapon_stats(loot_item, level, quality)
	
	# Add base weapon stats
	for key in weapon_stats:
		item[key] = weapon_stats[key]
	
	# Add weapon hand restriction
	if "weapon_hand" in loot_item:
		match loot_item.weapon_hand:
			0: item.hand = "any"
			1: item.hand = "primary"
			2: item.hand = "offhand"
			3: item.hand = "two_hand"
	
	# Maybe add elemental bonus for magic weapons
	if quality >= 2:  # Rare or better
		var elemental_bonus = WeaponStatRoller.roll_elemental_weapon_bonus(level, quality)
		for key in elemental_bonus:
			item[key] = elemental_bonus[key]

static func _add_armor_stats(item: Dictionary, loot_item: Resource, level: int, quality: int):
	"""Add rolled armor stats to item"""
	var armor_stats = ArmorStatRoller.roll_armor_stats(loot_item, level, quality)
	
	# Add base armor stats
	for key in armor_stats:
		item[key] = armor_stats[key]
	
	# Maybe add special bonus
	if quality >= 2:  # Rare or better
		var special_bonus = ArmorStatRoller.roll_special_armor_bonus(level, quality)
		for key in special_bonus:
			if item.has(key):
				item[key] += special_bonus[key]  # Add to existing
			else:
				item[key] = special_bonus[key]

static func _add_accessory_stats(item: Dictionary, loot_item: Resource, level: int, quality: int):
	"""Add rolled accessory stats to item"""
	var accessory_stats = AccessoryStatRoller.roll_accessory_stats(loot_item, level, quality)
	
	# Add all rolled stats
	for key in accessory_stats:
		if item.has(key):
			item[key] += accessory_stats[key]  # Add to base bonuses
		else:
			item[key] = accessory_stats[key]

static func _calculate_value(base_value: int, level: int, quality: int) -> int:
	"""Calculate item value based on level and quality"""
	var level_mult = 1.0 + (level - 1) * 0.1  # 10% per level
	var quality_mult = 1.0 + (quality * 0.5)  # 50% per quality tier
	
	return max(1, int(base_value * level_mult * quality_mult))

static func get_quality_name(quality: int) -> String:
	"""Get quality tier name"""
	match quality:
		0: return "Normal"
		1: return "Magic"
		2: return "Rare"
		3: return "Epic"
		4: return "Legendary"
		5: return "Mythic"
		_: return "Unknown"

static func get_quality_color(quality: int) -> Color:
	"""Get color for quality tier"""
	match quality:
		0: return Color.WHITE  # Normal
		1: return Color(0.5, 0.5, 1.0)  # Magic - Blue
		2: return Color(1.0, 1.0, 0.0)  # Rare - Yellow
		3: return Color(0.7, 0.0, 1.0)  # Epic - Purple
		4: return Color(1.0, 0.5, 0.0)  # Legendary - Orange
		5: return Color(1.0, 0.0, 1.0)  # Mythic - Magenta
		_: return Color.GRAY

static func get_damage_type_color(damage_type: String) -> Color:
	"""Get color for damage type"""
	match damage_type.to_lower():
		"physical": return Color.GRAY
		"magic": return Color(0.5, 0.5, 1.0)  # Blue
		"fire": return Color(1.0, 0.3, 0.0)  # Red-orange
		"frost": return Color(0.5, 0.8, 1.0)  # Light blue
		"static": return Color(1.0, 1.0, 0.3)  # Yellow
		"poison": return Color(0.3, 1.0, 0.3)  # Green
		_: return Color.WHITE
