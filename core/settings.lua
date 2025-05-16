local gui = require "gui"
local settings = {
    enabled = false,
    salvage = true,
    path_angle = 1,
    silent_chest = true,
    helltide_chest = true,
}

function settings:update_settings()
    settings.enabled = gui.elements.main_toggle:get()
    settings.salvage = gui.elements.salvage_toggle:get()
    settings.silent_chest = gui.elements.silent_chest_toggle:get()
    settings.helltide_chest = gui.elements.helltiide_chest_toggle:get()
end

return settings