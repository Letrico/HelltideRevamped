local utils = require "core.utils"
local tracker = require "core.tracker"
local explorerlite = require "core.explorerlite"
local settings = require "core.settings"
local enums = require "data.enums"

local found_chest = nil
local found_ore = nil
local found_herb = nil

local helltide_state = {
    INIT = "INIT",
    EXPLORE_HELLTIDE = "EXPLORE_HELLTIDE",
    MOVING_TO_PYRE = "MOVING_TO_PYRE",
    INTERACT_PYRE = "INTERACT_PYRE",
    STAY_NEAR_PYRE = "STAY_NEAR_PYRE",
    MOVING_TO_HELLTIDE_CHEST = "MOVING_TO_HELLTIDE_CHEST",
    MOVING_TO_SILENT_CHEST = "MOVING_TO_SILENT_CHEST",
    MOVING_TO_ORE = "MOVING_TO_ORE",
    MOVING_TO_HERB = "MOVING_TO_HERB",
    MOVING_TO_SHRINE = "MOVING_TO_SHRINE",
    CHASE_GOBLIN = "CHASE_GOBLIN",
    GO_NEAREST_COORDINATE = "GO_NEAREST_COORDINATE",
    BACK_TO_TOWN = "BACK_TO_TOWN"
}

local ni = 1
local explorer_active = false

local function find_closest_target(name)
    local actors = actors_manager:get_all_actors()
    local closest_target = nil
    local closest_distance = math.huge

    for _, actor in pairs(actors) do
        if actor:get_skin_name():match(name) then
            local actor_pos = actor:get_position()
            local distance = utils.distance_to(actor_pos)
            if distance < closest_distance then
                closest_target = actor
                closest_distance = distance
            end
        end
    end

    if closest_target then
        return closest_target
    end
    return nil
end

local function find_closest_waypoint_index(waypoints)
    local index = nil
    local closest_coordinate = 10000

    for i, coordinate in ipairs(waypoints) do
        if utils.distance_to(coordinate) < closest_coordinate then
            closest_coordinate = utils.distance_to(coordinate)
            index = i
        end
    end
    return index
end

local function get_distance(point)
    return get_player_position():dist_to(point)
end

local function load_waypoints(file)
    if file == "menestad" then
        tracker.waypoints = require("waypoints.menestad")
        console.print("Loaded waypoints: menestad")
    elseif file == "marowen" then
        tracker.waypoints = require("waypoints.marowen")
        console.print("Loaded waypoints: marowen")
    elseif file == "ironwolfs" then
        tracker.waypoints = require("waypoints.ironwolfs")
        console.print("Loaded waypoints: ironwolfs")
    elseif file == "wejinhani" then
        tracker.waypoints = require("waypoints.wejinhani")
        console.print("Loaded waypoints: wejinhani")
    elseif file == "jirandai" then
        tracker.waypoints = require("waypoints.jirandai")
        console.print("Loaded waypoints: jirandai")
    else
        console.print("No waypoints loaded")
    end
end

local function check_and_load_waypoints()
    for _, tp in ipairs(enums.helltide_tps) do
        if utils.player_in_zone(tp.name) then
            load_waypoints(tp.file)
            return
        end
    end
end

local function randomize_waypoint(waypoint, max_offset)
    max_offset = max_offset or 1.5 -- Valor padrão de 1.5 metros
    local random_x = math.random() * max_offset * 2 - max_offset
    local random_y = math.random() * max_offset * 2 - max_offset
    
    local randomized_point = vec3:new(
        waypoint:x() + random_x,
        waypoint:y() + random_y,
        waypoint:z()
    )
    
    -- Garante que o ponto randomizado seja caminhável
    randomized_point = utility.set_height_of_valid_position(randomized_point)
    if utility.is_point_walkeable(randomized_point) then
        return randomized_point
    else
        return waypoint -- Retorna o waypoint original se o ponto randomizado não for caminhável
    end
end

local function check_events(self)
    if find_closest_target("S04_Helltide_Prop_SoulSyphon_01_Dyn") and find_closest_target("S04_Helltide_Prop_SoulSyphon_01_Dyn"):is_interactable() then
        self.current_state = helltide_state.MOVING_TO_PYRE
    elseif find_closest_target("S04_Helltide_FlamePillar_Switch_Dyn") and find_closest_target("S04_Helltide_FlamePillar_Switch_Dyn"):is_interactable() then
        self.current_state = helltide_state.MOVING_TO_PYRE
    elseif settings.silent_chest and utils.have_whispering_key() and 
            find_closest_target("Hell_Prop_Chest_Rare_Locked") and
            find_closest_target("Hell_Prop_Chest_Rare_Locked"):is_interactable() and
            utils.distance_to(find_closest_target("Hell_Prop_Chest_Rare_Locked")) < 12
    then
        self.current_state = helltide_state.MOVING_TO_SILENT_CHEST
    elseif find_closest_target("HarvestNode_Ore") and
            find_closest_target("HarvestNode_Ore"):is_interactable() and
            utils.distance_to(find_closest_target("HarvestNode_Ore")) < 8
    then
        found_ore = find_closest_target("HarvestNode_Ore")
        self.current_state = helltide_state.MOVING_TO_ORE
    elseif find_closest_target("HarvestNode_Herb") and
            find_closest_target("HarvestNode_Herb"):is_interactable() and
            utils.distance_to(find_closest_target("HarvestNode_Herb")) < 8
    then
        found_herb = find_closest_target("HarvestNode_Herb")
        self.current_state = helltide_state.MOVING_TO_HERB
    elseif find_closest_target("Shrine_") and
            find_closest_target("Shrine_"):is_interactable() and
            utils.distance_to(find_closest_target("Shrine_")) < 6
    then
        self.current_state = helltide_state.MOVING_TO_SHRINE
    elseif find_closest_target("treasure_goblin") then
        self.current_state = helltide_state.CHASE_GOBLIN
    elseif settings.helltide_chest then
        for chest_name, _ in pairs(enums.chest_types) do
            if find_closest_target(chest_name) and
                find_closest_target(chest_name):is_interactable() and
                utils.check_cinders(chest_name) and 
                utils.distance_to(find_closest_target(chest_name)) < 12
            then
                found_chest = chest_name
                self.current_state = helltide_state.MOVING_TO_HELLTIDE_CHEST
                break
            end
        end
    end
end

local helltide_task = {
    name = "Explore Helltiide",
    current_state = helltide_state.INIT,

    shouldExecute = function()
        return utils.is_in_helltide()
    end,

    Execute = function(self)
        console.print("Current state: " .. self.current_state)
        if get_local_player() and get_local_player():is_dead() then
            revive_at_checkpoint()
        end

        if LooteerPlugin then
            local looting = LooteerPlugin.getSettings('looting')
            if looting then
                explorerlite.is_task_running = true
                return
            end
        end

        if tracker.has_salvaged then
            self:return_from_salvage()
        elseif utils.is_inventory_full() then
            self:back_to_town()
        elseif self.current_state == helltide_state.INIT then
            self:initiate_waypoints()
        elseif self.current_state == helltide_state.EXPLORE_HELLTIDE then
            self:explore_helltide()
        elseif self.current_state == helltide_state.MOVING_TO_PYRE then
            self:move_to_pyre()
        elseif self.current_state == helltide_state.INTERACT_PYRE then
            self:interact_pyre()
        elseif self.current_state == helltide_state.STAY_NEAR_PYRE then
            self:stay_near_pyre()
        elseif self.current_state == helltide_state.MOVING_TO_SILENT_CHEST then
            self:move_to_silent_chest()
        elseif self.current_state == helltide_state.MOVING_TO_HELLTIDE_CHEST then
            self:move_to_helltide_chest()
        elseif self.current_state == helltide_state.MOVING_TO_ORE then
            self:move_to_ore()
        elseif self.current_state == helltide_state.MOVING_TO_HERB then
            self:move_to_herb()
        elseif self.current_state == helltide_state.MOVING_TO_SHRINE then
            self:move_to_shrine()
        elseif self.current_state == helltide_state.CHASE_GOBLIN then
            self:chase_goblin()
        elseif self.current_state == helltide_state.GO_NEAREST_COORDINATE then
            self:go_to_nearest_coordinate()
        elseif self.current_state == helltide_state.BACK_TO_TOWN then
            self:back_to_town()
        end
    end,

    initiate_waypoints = function(self)
        explorerlite.is_task_running = true
        explorer_active = false
        check_and_load_waypoints()
        self.current_state = helltide_state.EXPLORE_HELLTIDE
    end,

    explore_helltide = function(self)
        if type(tracker.waypoints) ~= "table" then
            console.print("Error: waypoints is not a table")
            return
        end

        if type(ni) ~= "number" then
            console.print("Error: ni is not a number")
            return
        end

        check_events(self)

        if not utils.player_in_town() and ni == 1 then -- reset midway a run
            local nearest_ni = find_closest_waypoint_index(tracker.waypoints)
            if nearest_ni then
                ni = nearest_ni
            end 
        end

        if ni > #tracker.waypoints or ni < 1 or #tracker.waypoints == 0 then
            ni = 1
        end

        local current_waypoint = tracker.waypoints[ni]
        if current_waypoint then
            local distance = get_distance(current_waypoint)

            if distance < 2 then
                ni = ni + 1
            else
                if not explorer_active then
                    local randomized_waypoint = randomize_waypoint(current_waypoint)
                    pathfinder.request_move(randomized_waypoint)
                else
                    console.print("no explorer")
                end
            end
        end
    end,

    move_to_pyre = function(self)
        local pyre = find_closest_target("S04_Helltide_Prop_SoulSyphon_01_Dyn") or find_closest_target("S04_Helltide_FlamePillar_Switch_Dyn")
        if pyre then 
            if utils.distance_to(pyre) > 2 then
                -- console.print(string.format("Moving to pyre"))
                explorerlite.is_task_running = false
                explorer_active = true
                explorerlite:set_custom_target(pyre:get_position())
                explorerlite:move_to_target()
                -- pathfinder.force_move(pyre:get_position())
                return
            else
                self.current_state = helltide_state.INTERACT_PYRE
            end
        else
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    interact_pyre = function(self)
        local pyre = find_closest_target("S04_Helltide_Prop_SoulSyphon_01_Dyn")  or find_closest_target("S04_Helltide_FlamePillar_Switch_Dyn")
        if pyre then
            if pyre:is_interactable() then
                interact_object(pyre)
            else
                self.current_state = helltide_state.STAY_NEAR_PYRE
            end
        else
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    stay_near_pyre = function(self)
        local pyre = find_closest_target("S04_Helltide_Prop_SoulSyphon_01_Dyn")  or find_closest_target("S04_Helltide_FlamePillar_Switch_Dyn")
        if pyre then
            if pyre:is_interactable() then
                self.current_state = helltide_state.INTERACT_PYRE
            elseif utils.distance_to(pyre) > 1 then
                -- console.print(string.format("Stay near pyre"))
                explorerlite.is_task_running = false
                explorer_active = true
                explorerlite:set_custom_target(pyre:get_position())
                explorerlite:move_to_target()
                -- pathfinder.force_move(pyre:get_position())
                return
            else
                self.current_state = helltide_state.GO_NEAREST_COORDINATE
            end
        else
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    move_to_silent_chest = function(self)
        local chest = find_closest_target("Hell_Prop_Chest_Rare_Locked")
        if chest and chest:is_interactable() then 
            if utils.distance_to(chest) > 2 then
                -- console.print(string.format("Moving to chest"))
                explorerlite.is_task_running = false
                explorer_active = true
                explorerlite:set_custom_target(chest:get_position())
                explorerlite:move_to_target()
                -- pathfinder.force_move(chest:get_position())
                return
            else
                interact_object(chest)
            end
        else
            if not tracker.check_time("chest_drop_time", 4) then
                return
            end
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    move_to_helltide_chest = function(self)
        if found_chest then
            local chest = find_closest_target(found_chest)
            if chest and chest:is_interactable() then 
                if utils.distance_to(chest) > 2 then
                    -- console.print(string.format("Moving to chest"))
                    explorerlite.is_task_running = false
                    explorer_active = true
                    explorerlite:set_custom_target(chest:get_position())
                    explorerlite:move_to_target()
                    -- pathfinder.force_move(chest:get_position())
                    return
                else
                    interact_object(chest)
                end
            else
                if not tracker.check_time("chest_drop_time", 4) then
                    return
                end
                self.current_state = helltide_state.GO_NEAREST_COORDINATE
            end
        else
            found_chest = nil
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    move_to_ore = function(self)
        if found_ore and found_ore:is_interactable() then 
            if utils.distance_to(found_ore) > 2 then
                -- console.print(string.format("Moving to found_ore"))
                explorerlite.is_task_running = false
                explorer_active = true
                explorerlite:set_custom_target(found_ore:get_position())
                explorerlite:move_to_target()
                -- pathfinder.force_move(found_ore:get_position())
                return
            else
                interact_object(found_ore)
            end
        else
            -- if not tracker.check_time("ore_drop_time", 2) then
            --     return
            -- end
            found_ore = nil
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    move_to_herb = function(self)
        if found_herb and found_herb:is_interactable() then 
            if utils.distance_to(found_herb) > 2 then
                -- console.print(string.format("Moving to found_herb"))
                explorerlite.is_task_running = false
                explorer_active = true
                explorerlite:set_custom_target(found_herb:get_position())
                explorerlite:move_to_target()
                -- pathfinder.force_move(found_herb:get_position())
                return
            else
                interact_object(found_herb)
            end
        else
            -- if not tracker.check_time("herb_drop_time", 2) then
            --     return
            -- end
            found_herb = nil
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    move_to_shrine = function(self)
        local shrine = find_closest_target("Shrine_")
        if shrine and shrine:is_interactable() then 
            if utils.distance_to(shrine) > 2 then
                -- console.print(string.format("Moving to found_shrine"))
                explorerlite.is_task_running = false
                explorer_active = true
                explorerlite:set_custom_target(shrine:get_position())
                explorerlite:move_to_target()
                -- pathfinder.force_move(shrine:get_position())
                return
            else
                interact_object(shrine)
            end
        else
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    chase_goblin = function(self)
        local goblin = find_closest_target("treasure_goblin")
        if goblin then 
            if utils.distance_to(goblin) > 2 then
                -- console.print(string.format("Moving to found_goblin"))
                explorerlite.is_task_running = false
                explorer_active = true
                explorerlite:set_custom_target(goblin:get_position())
                explorerlite:move_to_target()
                -- pathfinder.force_move(goblin:get_position())
                return
            else
                interact_object(goblin)
            end
        else
            if not tracker.check_time("goblin_drop_time", 4) then
                return
            end
            self.current_state = helltide_state.GO_NEAREST_COORDINATE
        end
    end,

    go_to_nearest_coordinate = function(self)
        check_events(self)
        tracker.clear_key('chest_drop_time')
        tracker.clear_key('pyre_timeout')
        local nearest_ni = find_closest_waypoint_index(tracker.waypoints)
        if nearest_ni and math.abs(nearest_ni - ni) > 5 then
            ni = nearest_ni
        end
        explorerlite.is_task_running = false
        explorer_active = true
        if utils.distance_to(tracker.waypoints[ni]) > 4 then
            explorer_active = true
            explorerlite:set_custom_target(tracker.waypoints[ni])
            explorerlite:move_to_target()
        else
            explorer_active = false
            explorerlite.is_task_running = true
            self.current_state = helltide_state.EXPLORE_HELLTIDE
        end
    end,

    back_to_town = function(self)
        explorerlite.is_task_running = true
        explorer_active = false
        if settings.salvage then
            tracker.needs_salvage = true
        end
    end,

    return_from_salvage = function(self)
        if not tracker.check_time("salvage_return_time", 3) then
            return
        end
        tracker.has_salvaged = false -- reset alfred flag
        tracker.clear_key('salvage_return_time')
        self.current_state = helltide_state.EXPLORE_HELLTIDE
    end,

    reset = function(self)
        ni = 1
        self.current_state = helltide_state.INIT
        tracker.has_salvaged = false
        tracker.needs_salvage = false
        found_chest = nil
        found_ore = nil
        found_herb = nil
    end
}

return helltide_task