namespace MCBDS.PublicUI.Web.Components;

public static class MinecraftItems
{
    public static readonly List<string> AllItems = new()
    {
        // Common Items
        "diamond", "diamond_sword", "diamond_pickaxe", "diamond_axe", "diamond_shovel", "diamond_hoe",
        "diamond_helmet", "diamond_chestplate", "diamond_leggings", "diamond_boots",
        "iron_ingot", "iron_sword", "iron_pickaxe", "iron_axe", "iron_shovel", "iron_hoe",
        "iron_helmet", "iron_chestplate", "iron_leggings", "iron_boots",
        "gold_ingot", "golden_sword", "golden_pickaxe", "golden_axe", "golden_shovel", "golden_hoe",
        "golden_helmet", "golden_chestplate", "golden_leggings", "golden_boots",
        "netherite_ingot", "netherite_sword", "netherite_pickaxe", "netherite_axe", "netherite_shovel", "netherite_hoe",
        "netherite_helmet", "netherite_chestplate", "netherite_leggings", "netherite_boots",
        "stone", "cobblestone", "dirt", "grass_block", "sand", "gravel", "oak_log", "spruce_log", "birch_log",
        "oak_planks", "spruce_planks", "birch_planks", "stick", "coal", "charcoal",
        "bow", "arrow", "spectral_arrow", "tipped_arrow", "crossbow", "shield", "trident",
        "apple", "golden_apple", "enchanted_golden_apple", "bread", "cooked_beef", "cooked_porkchop", "cooked_chicken",
        "torch", "lantern", "campfire", "crafting_table", "furnace", "chest", "ender_chest", "shulker_box",
        "bed", "white_bed", "red_bed", "blue_bed", "enchanting_table", "anvil", "brewing_stand",
        "bucket", "water_bucket", "lava_bucket", "milk_bucket", "fishing_rod", "shears", "flint_and_steel",
        "ender_pearl", "eye_of_ender", "blaze_rod", "blaze_powder", "nether_star", "elytra", "firework_rocket",
        "compass", "clock", "map", "book", "enchanted_book", "paper", "experience_bottle",
        "obsidian", "crying_obsidian", "glowstone", "redstone", "redstone_torch", "lever", "button",
        "glass", "glass_pane", "tnt", "gunpowder", "slime_ball", "string", "feather", "leather",
        "bone", "bone_meal", "egg", "wheat", "wheat_seeds", "carrot", "potato", "beetroot",
        "pumpkin", "melon", "cake", "cookie", "emerald", "lapis_lazuli", "quartz",
        "name_tag", "lead", "saddle", "spawn_egg", "command_block", "structure_block", "barrier"
    };

    public static List<string> SearchItems(string query, int maxResults = 10)
    {
        if (string.IsNullOrWhiteSpace(query))
            return AllItems.Take(maxResults).ToList();

        var lowerQuery = query.ToLower().Replace(" ", "_");
        
        return AllItems
            .Where(item => item.Contains(lowerQuery))
            .OrderBy(item => item.StartsWith(lowerQuery) ? 0 : 1)
            .ThenBy(item => item)
            .Take(maxResults)
            .ToList();
    }

    public static bool IsValidItem(string itemName)
    {
        return AllItems.Contains(itemName.ToLower().Replace(" ", "_"));
    }
}
