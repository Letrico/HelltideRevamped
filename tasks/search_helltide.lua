local utils = require "core.utils"
local tracker = require "core.tracker"
local helltide_task = require "tasks.helltide"
local enums = require "data.enums"
local plugin_label = "helltide_revamped"

local current_city_index = 0

local search_helltide_state = {
    SEARCHING_HELLTIDE = "SEARCHING_HELLTIDE",
    TELEPORTING = "TELEPORTING",
    WAITING_FOR_TELEPORT = "WAITING_FOR_TELEPORT",
    FOUND_HELLTIDE = "FOUND_HELLTIDE",
}

local search_helltide_task = {
    name = "Search helltide",
    current_state = search_helltide_state.SEARCHING_HELLTIDE,

    shouldExecute = function()
        return not utils.is_in_helltide()
    end,

    Execute = function(self)
        -- console.print("Current state: " .. self.current_state)

        if tracker.helltide_end then 
            self:reset()
        elseif self.current_state == search_helltide_state.SEARCHING_HELLTIDE then
            self:searching_helltide()
        elseif self.current_state == search_helltide_state.TELEPORTING then
            self:teleporting_to_helltide()
        elseif self.current_state == search_helltide_state.WAITING_FOR_TELEPORT then
            self:waiting_for_teleport()
        elseif self.current_state == search_helltide_state.FOUND_HELLTIDE then
            self:found_helltide()
        end
    end,

    searching_helltide = function(self)
        console.print("Initializing search helltide")
        self:reset()
        if not utils.helltide_active() then
            console.print("Helltide is not active, wait until helltide starts")
            if not utils.player_in_zone("Scos_Cerrigar") then
                if PLUGIN_alfred_the_butler then
                    PLUGIN_alfred_the_butler.trigger_tasks(plugin_label,function()end)
                end
                teleport_to_waypoint(0x76D58) -- Go to cerrigar and wait for helltide
            end
            return
        elseif not utils.is_in_helltide() then
            console.print("Not in helltide, teleport to next town to check")
            self.current_state = search_helltide_state.TELEPORTING
        else
            console.print("Found helltide")
            self.current_state = search_helltide_state.FOUND_HELLTIDE
        end
    end,

    teleporting_to_helltide = function(self)
        if not ( utils.player_in_zone(nil) or utils.player_in_zone("")) then
            if current_city_index > #enums.helltide_tps then
                current_city_index = 1
            else
                current_city_index = (current_city_index % #enums.helltide_tps) + 1
            end
            -- console.print("Teleporting to: " .. tostring(enums.helltide_tps[current_city_index].file))
            tracker.wait_in_town = nil
            teleport_to_waypoint(enums.helltide_tps[current_city_index].id)
            self.current_state = search_helltide_state.WAITING_FOR_TELEPORT
        else
            console.print("Currently in loading screen. Waiting before attempting teleport.")
            return
        end
    end,

    waiting_for_teleport = function(self)
        if utils.player_in_zone(enums.helltide_tps[current_city_index].name) then
            if not tracker.check_time("wait_in_town", 4) then
                return
            end
            self.current_state = search_helltide_state.SEARCHING_HELLTIDE
        else
            -- fail teleport, retry
            tracker.clear_key('wait_in_town')
            self.current_state = search_helltide_state.TELEPORTING
            return
        end
    end,

    found_helltide = function(self)
        console.print("Found helltide")
    end,

    reset = function(self)
        tracker.helltide_end = false
        helltide_task:reset()
        self.current_state = search_helltide_state.SEARCHING_HELLTIDE
    end
}

return search_helltide_task