namespace MCBDS.PublicUI.Components;

public static class MinecraftItems
{
    public static readonly Dictionary<string, List<string>> ItemsByCategory = new()
    {
        ["Building Blocks"] = new()
        {
            "stone", "granite", "polished_granite", "diorite", "polished_diorite", "andesite", "polished_andesite",
            "grass", "dirt", "coarse_dirt", "podzol", "cobblestone", "oak_planks", "spruce_planks", "birch_planks",
            "jungle_planks", "acacia_planks", "dark_oak_planks", "sand", "red_sand", "gravel", "gold_ore",
            "iron_ore", "coal_ore", "oak_log", "spruce_log", "birch_log", "jungle_log", "acacia_log", "dark_oak_log",
            "glass", "lapis_ore", "lapis_block", "sandstone", "wool", "gold_block", "iron_block", "brick_block",
            "tnt", "mossy_cobblestone", "obsidian", "diamond_ore", "diamond_block", "crafting_table", "furnace",
            "stone_bricks", "bookshelf", "coal_block", "ice", "clay", "netherrack", "soul_sand", "glowstone",
            "quartz_ore", "quartz_block", "prismarine", "hay_block", "hardened_clay", "slime", "packed_ice",
            "red_sandstone", "purpur_block", "end_stone", "concrete", "concrete_powder"
        },
        ["Tools & Weapons"] = new()
        {
            "wooden_sword", "wooden_shovel", "wooden_pickaxe", "wooden_axe", "wooden_hoe",
            "stone_sword", "stone_shovel", "stone_pickaxe", "stone_axe", "stone_hoe",
            "iron_sword", "iron_shovel", "iron_pickaxe", "iron_axe", "iron_hoe",
            "golden_sword", "golden_shovel", "golden_pickaxe", "golden_axe", "golden_hoe",
            "diamond_sword", "diamond_shovel", "diamond_pickaxe", "diamond_axe", "diamond_hoe",
            "bow", "arrow", "flint_and_steel", "fishing_rod", "clock", "compass", "shears", "shield",
            "trident", "crossbow"
        },
        ["Armor"] = new()
        {
            "leather_helmet", "leather_chestplate", "leather_leggings", "leather_boots",
            "chainmail_helmet", "chainmail_chestplate", "chainmail_leggings", "chainmail_boots",
            "iron_helmet", "iron_chestplate", "iron_leggings", "iron_boots",
            "golden_helmet", "golden_chestplate", "golden_leggings", "golden_boots",
            "diamond_helmet", "diamond_chestplate", "diamond_leggings", "diamond_boots",
            "turtle_helmet", "elytra"
        },
        ["Food"] = new()
        {
            "apple", "golden_apple", "enchanted_golden_apple", "mushroom_stew", "bread", "porkchop",
            "cooked_porkchop", "cod", "cooked_cod", "salmon", "cooked_salmon", "tropical_fish", "pufferfish",
            "cake", "cookie", "melon", "beef", "cooked_beef", "chicken", "cooked_chicken", "rotten_flesh",
            "spider_eye", "carrot", "potato", "baked_potato", "poisonous_potato", "golden_carrot",
            "pumpkin_pie", "rabbit", "cooked_rabbit", "rabbit_stew", "mutton", "cooked_mutton",
            "beetroot", "beetroot_soup", "dried_kelp", "sweet_berries", "honey_bottle"
        },
        ["Materials"] = new()
        {
            "coal", "charcoal", "diamond", "iron_ingot", "gold_ingot", "emerald", "quartz",
            "leather", "string", "feather", "gunpowder", "flint", "bone", "bone_meal",
            "blaze_rod", "blaze_powder", "ender_pearl", "ender_eye", "nether_wart",
            "redstone", "glowstone_dust", "snowball", "slime_ball"
        }
    };

    public static readonly List<string> AllItems = ItemsByCategory.Values
        .SelectMany(items => items)
        .Distinct()
        .OrderBy(item => item)
        .ToList();

    public static List<string> SearchItems(string query, int maxResults = 15)
    {
        if (string.IsNullOrWhiteSpace(query))
            return AllItems.Take(maxResults).ToList();

        query = query.ToLower().Trim();

        var exactMatches = AllItems
            .Where(item => item.ToLower().StartsWith(query))
            .ToList();

        var containsMatches = AllItems
            .Where(item => item.ToLower().Contains(query) && !item.ToLower().StartsWith(query))
            .ToList();

        return exactMatches.Concat(containsMatches)
            .Take(maxResults)
            .ToList();
    }
}
