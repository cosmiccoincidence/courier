extends Node3D

@export var item_name: String = "Stick"

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		pickup()

func pickup():
	if Inventory.add_item(item_name):
		queue_free()  # Remove item from world
