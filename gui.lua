local gui = {}
local version = "v0.1"
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
    helltiide_chest_toggle = create_checkbox(true, plugin_label .. "silent_chest_toggle"),
}

function gui.render()
    if not gui.elements.main_tree:push("Helltide Revamped | Letrico | " .. version) then return end

    gui.elements.main_toggle:render("Enable", "Enable the bot")
    
    if gui.elements.settings_tree:push("Settings") then
        gui.elements.salvage_toggle:render("Salvage with alfred", "Enable salvaging items with alfred")
        gui.elements.silent_chest_toggle:render("Open Silent Chest (key required)", "Open silent chest")
        gui.elements.helltiide_chest_toggle:render("Open Helltide Chest", "Open helltide chest")
        gui.elements.settings_tree:pop()
    end

    gui.elements.main_tree:pop()
end

return gui