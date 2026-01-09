# loot_item.gd
# Resource definition for loot items - 6-stat system
class_name LootItem
extends Resource

# ===== BASIC INFO =====
@export var item_name: String = "Item"
@export var icon: Texture2D
@export var item_scene: PackedScene  # The actual item scene to spawn

# ===== CLASSIFICATION =====
@export var item_type: String = "misc"  # weapon, armor, consumable, material, accessory, etc.
@export var item_subtype: String = ""  # sword, axe, helmet, boots, ring, amulet, etc.
@export var item_tags: Array[String] = []  # Tags for filtering

# ===== PHYSICAL PROPERTIES =====
@export var mass: float = 1.0
@export var durability: int = 100  # 100 = new, 0 = broken
@export var base_value: int = 10  # Base value before level/quality modifiers
@export var stackable: bool = false
@export var max_stack_size: int = 1

# ===== STAT REQUIREMENTS =====
@export_group("Stat Requirements")
@export var required_strength: int = 0
@export var required_dexterity: int = 0
@export var required_fortitude: int = 0  # NEW!

# ===== CORE STAT BONUSES =====
@export_group("Core Stat Bonuses")
@export var bonus_strength: int = 0
@export var bonus_dexterity: int = 0
@export var bonus_fortitude: int = 0
@export var bonus_vitality: int = 0
@export var bonus_agility: int = 0
@export var bonus_arcane: int = 0

# ===== RESOURCE BONUSES =====
@export_group("Resource Bonuses")
@export var bonus_max_health: int = 0
@export var bonus_max_stamina: int = 0
@export var bonus_max_mana: int = 0

# ===== REGEN BONUSES =====
@export_group("Regen Bonuses")
@export var bonus_health_regen: float = 0.0
@export var bonus_stamina_regen: float = 0.0
@export var bonus_mana_regen: float = 0.0

# ===== WEAPON STATS =====
@export_group("Weapon Stats")
@export var min_weapon_damage: int = 0
@export var max_weapon_damage: int = 0

# Weapon damage type
enum DamageType {
	PHYSICAL,  # Slash/pierce/blunt - blocked by armor
	MAGIC,     # Pure arcane damage - blocked by magic resist
	FIRE,      # Fire damage - blocked by fire resist
	FROST,     # Ice/cold damage - blocked by frost resist
	STATIC,    # Lightning damage - blocked by static resist
	POISON     # Poison damage - blocked by poison resist
}
@export var weapon_damage_type: DamageType = DamageType.PHYSICAL

@export var weapon_range: float = 1.5
@export var weapon_speed: float = 1.0
@export_range(0.0, 1.0) var weapon_crit_chance: float = 0.0
@export var weapon_crit_multiplier: float = 1.5
@export_range(0.0, 1.0) var weapon_block_rating: float = 0.0
@export var weapon_parry_window: float = 0.0

# Weapon hand restrictions
enum WeaponHand {
	ANY,        # Can equip in either hand
	PRIMARY,    # Left hand only (slots 10, 14)
	OFFHAND,    # Right hand only (slots 11, 15)
	TWOHAND     # Takes both hands
}
@export var weapon_hand: WeaponHand = WeaponHand.ANY

# ===== ARMOR/DEFENSE STATS =====
@export_group("Defense Stats")
@export var min_armor: int = 0  # Min armor rating to roll
@export var max_armor: int = 0  # Max armor rating to roll

# Armor type affects resistance modifiers
enum ArmorType {
	CLOTH,    # Low armor, high elemental resist
	LEATHER,  # Balanced
	MAIL,     # Medium armor, medium resist
	PLATE     # High armor, low/negative elemental resist
}
@export var armor_type: ArmorType = ArmorType.LEATHER

# ===== RESISTANCE BONUSES =====
@export_group("Resistance Bonuses")
@export_range(-1.0, 1.0) var bonus_fire_resistance: float = 0.0
@export_range(-1.0, 1.0) var bonus_frost_resistance: float = 0.0
@export_range(-1.0, 1.0) var bonus_static_resistance: float = 0.0
@export_range(-1.0, 1.0) var bonus_poison_resistance: float = 0.0

# ===== DAMAGE REDUCTION BONUSES =====
@export_group("Damage Reduction")
@export_range(0.0, 1.0) var bonus_enemy_damage_reduction: float = 0.0  # vs elites/bosses
@export_range(0.0, 1.0) var bonus_environment_damage_reduction: float = 0.0  # vs traps/hazards

# ===== COMBAT BONUSES =====
@export_group("Combat Bonuses")
@export var bonus_attack_speed: float = 0.0
@export_range(0.0, 1.0) var bonus_crit_chance: float = 0.0
@export var bonus_crit_damage: float = 0.0

# ===== MOVEMENT BONUSES =====
@export_group("Movement Bonuses")
@export var bonus_movement_speed: float = 0.0

# ===== ABILITY COST MODIFIERS =====
@export_group("Ability Costs")
@export var bonus_sprint_stamina_cost: float = 0.0  # Negative = cheaper
@export var bonus_dodge_roll_stamina_cost: float = 0.0
@export var bonus_dash_stamina_cost: float = 0.0

# ===== STACKABLE SETTINGS =====
@export_group("Stackable Settings")
@export var min_drop_amount: int = 1
@export var max_drop_amount: int = 1
@export var scaled_quantity: bool = false  # Scale by enemy level

# ===== LOOT TABLE PROPERTIES =====
@export_group("Loot Table")
@export var item_drop_weight: float = 1.0
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export var min_level: int = 1  # Minimum level for this item to drop
@export var max_level: int = 100  # Maximum level
