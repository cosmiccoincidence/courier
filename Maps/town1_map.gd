# town1_map.gd
# Town 1 - Safe zone after Act 1
class_name Town1Map
extends TownCoreMap

# ============================================================================
# TOWN 1 CONFIGURATION
# ============================================================================

func _ready():
	# Set town-specific values before calling super._ready()
	act_number = 1      # After Act 1
	map_number = 4      # 4th map overall (after 3 Act 1 levels)
	map_name = "Riverside Town"
	
	# Calculate map_level: (1 + 4) * 1 = 5
	map_level = (act_number + map_number) * act_number
	
	print("Town 1 Map - Level: ", map_level, " Name: ", map_name, " (Act ", act_number, ", Map ", map_number, ")")
	super._ready()
