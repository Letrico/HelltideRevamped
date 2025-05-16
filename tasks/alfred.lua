local plugin_label = "helltide_revamped" -- change to your plugin name

local settings = require 'core.settings'
local tracker = require "core.tracker"
-- need use_alfred to enable
-- settings.salvage = true

local status_enum = {
    IDLE = 'idle',
    WAITING = 'waiting for alfred to complete',
}
local task = {
    name = 'alfred_running', -- change to your choice of task name
    status = status_enum['IDLE']
}

local function reset()
    PLUGIN_alfred_the_butler.pause(plugin_label)
    -- add more stuff here if you need to do something after alfred is done
    tracker.has_salvaged = true
    tracker.needs_salvage = false
    task.status = status_enum['IDLE']
end

function task.shouldExecute()
    if settings.salvage and PLUGIN_alfred_the_butler then
        local status = PLUGIN_alfred_the_butler.get_status()
        -- add additional conditions to trigger if required
        if (status.enabled and tracker.needs_salvage) then
            return true
        end
    end
    return false
end

function task.Execute()
    if task.status == status_enum['IDLE'] then
        PLUGIN_alfred_the_butler.resume()
        -- PLUGIN_alfred_the_butler.trigger_tasks(plugin_label,reset)
        PLUGIN_alfred_the_butler.trigger_tasks_with_teleport(plugin_label,reset)
        task.status = status_enum['WAITING']
    end
end

if settings.enabled and settings.salvage and PLUGIN_alfred_the_butler then
    -- do an initial reset
    reset()
end

return task