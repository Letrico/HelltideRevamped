local gui = {}
local version = "v0.4"
local plugin_label = "helltide_revamped"

local function create_checkbox(value, key)
    return checkbox:new(value, get_hash(plugin_label .. "_" .. key))
end

gui.elements = {
    main_tree = tree_node:new(0),
    main_toggle = create_checkbox(false, "main_toggle"),
    settings_tree = tree_node:new(1),
    salvage_toggle = create_checkbox(true, plugin_label .. "salvage_toggle"),
    silent_chest_toggle = create_checkbox(true, plugin_label .. "silent_chest_toggle"),
    helltide_chest_toggle = create_checkbox(true, plugin_label .. "helltide_chest_toggle"),
    ore_toggle = create_checkbox(true, plugin_label .. "ore_toggle"),
    herb_toggle = create_checkbox(true, plugin_label .. "herb_toggle"),
    shrine_toggle = create_checkbox(true, plugin_label .. "shrine_toggle"),
    goblin_toggle = create_checkbox(true, plugin_label .. "goblin_toggle"),
    event_toggle = create_checkbox(true, plugin_label .. "event_toggle"),
    chaos_rift_toggle = create_checkbox(true, plugin_label .. "chaos_rift_toggle"),
}

function gui.render()
    if not gui.elements.main_tree:push("Helltide Revamped | Letrico | " .. version) then return end

    gui.elements.main_toggle:render("Enable", "Enable the bot")
    
    if gui.elements.settings_tree:push("Settings") then
        gui.elements.salvage_toggle:render("Salvage with alfred", "Enable salvaging items with alfred")
        gui.elements.silent_chest_toggle:render("Open Silent Chest (key required)", "Open silent chest")
        gui.elements.helltide_chest_toggle:render("Open Helltide Chest", "Open helltide chest")
        gui.elements.ore_toggle:render("Collect Ore", "Collect ore")
        gui.elements.herb_toggle:render("Collect Herb", "Collect herb")
        gui.elements.shrine_toggle:render("Use Shrine", "Use shrine")
        gui.elements.goblin_toggle:render("Chase goblin", "Chase goblin")
        gui.elements.event_toggle:render("Do events (flame pillar/ravenous soul)", "Do events")
        gui.elements.chaos_rift_toggle:render("Do chaos rift", "Do chaos rift")
        gui.elements.settings_tree:pop()
    end

    gui.elements.main_tree:pop()
end

return gui