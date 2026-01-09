# accessory_stat_roller.gd
# Utility class for rolling accessory stats (rings, amulets, etc.)
class_name AccessoryStatRoller
extends RefCounted

static func roll_accessory_stats(loot_item: Resource, item_level: int, item_quality: int) -> Dictionary:
	"""Roll stats for accessories (rings, amulets, etc.)"""
	var stats = {}
	
	# Accessories don't have armor, but have good stat bonuses
	var num_bonuses = 1 + item_quality  # 1-6 bonuses based on quality
	
	for i in range(num_bonuses):
		var bonus_type = randi() % 10
		
		match bonus_type:
			0, 1:  # Core stats (most common)
				var stat_names = ["strength", "dexterity", "fortitude", "vitality", "agility", "arcane"]
				var stat = stat_names[randi() % stat_names.size()]
				var amount = 2 + item_quality + (item_level / 5)
				stats[stat] = stats.get(stat, 0) + amount
			
			2, 3:  # Resistances
				var resist_names = ["fire_resistance", "frost_resistance", "static_resistance", "poison_resistance"]
				var resist = resist_names[randi() % resist_names.size()]
				var amount = 0.05 + (item_quality * 0.02)
				stats[resist] = stats.get(resist, 0.0) + amount
			
			4:  # Resources
				var resource_names = ["max_health", "max_stamina", "max_mana"]
				var resource = resource_names[randi() % resource_names.size()]
				var amount = 10 + (item_quality * 5) + (item_level * 2)
				stats[resource] = stats.get(resource, 0) + amount
			
			5:  # Regen
				var regen_names = ["health_regen", "stamina_regen", "mana_regen"]
				var regen = regen_names[randi() % regen_names.size()]
				var amount = 0.5 + (item_quality * 0.3)
				stats[regen] = stats.get(regen, 0.0) + amount
			
			6:  # Combat bonuses
				if randf() < 0.5:
					stats.crit_chance = stats.get("crit_chance", 0.0) + (0.02 + item_quality * 0.01)
				else:
					stats.attack_speed = stats.get("attack_speed", 0.0) + (0.05 + item_quality * 0.03)
			
			7:  # Damage reduction
				if randf() < 0.5:
					stats.enemy_damage_reduction = stats.get("enemy_damage_reduction", 0.0) + (0.03 + item_quality * 0.02)
				else:
					stats.environment_damage_reduction = stats.get("environment_damage_reduction", 0.0) + (0.05 + item_quality * 0.03)
			
			8:  # Movement
				stats.movement_speed = stats.get("movement_speed", 0.0) + (0.05 + item_quality * 0.02)
			
			9:  # Ability costs
				var abilities = ["sprint_stamina_cost", "dodge_roll_stamina_cost", "dash_stamina_cost"]
				var ability = abilities[randi() % abilities.size()]
				stats[ability] = stats.get(ability, 0.0) - (1.0 + item_quality * 0.5)  # Negative = cheaper
	
	return stats
