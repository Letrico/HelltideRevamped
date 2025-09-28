local gui = require "gui"
local settings = {
    enabled = false,
    salvage = true,
    path_angle = 1,
    silent_chest = true,
    helltide_chest = true,
    ore = true,
    herb = true,
    shrine = true,
    goblin = true,
    event = true,
}

function settings:update_settings()
    settings.enabled = gui.elements.main_toggle:get()
    settings.salvage = gui.elements.salvage_toggle:get()
    settings.silent_chest = gui.elements.silent_chest_toggle:get()
    settings.helltide_chest = gui.elements.helltide_chest_toggle:get()
    settings.ore = gui.elements.ore_toggle:get()
    settings.herb = gui.elements.herb_toggle:get()
    settings.shrine = gui.elements.shrine_toggle:get()
    settings.goblin = gui.elements.goblin_toggle:get()
    settings.event = gui.elements.event_toggle:get()
    settings.chaos_rift = gui.elements.chaos_rift_toggle:get()
end

return settings