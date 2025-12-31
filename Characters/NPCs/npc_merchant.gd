extends BaseNPC
class_name NPCMerchant

@export var shop_inventory: Array[LootItem] = []
@export var interaction_range: float = 3.0

var player_in_range: bool = false

func _ready():
	super._ready()  # Call parent _ready
	display_name = "Merchant"
	# Additional setup

func _physics_process(delta):
	super._physics_process(delta)  # Call parent physics
	check_player_proximity()

func check_player_proximity():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		player_in_range = distance <= interaction_range
