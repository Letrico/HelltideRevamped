local utils    = {}
local enums = require "data.enums"

function utils.distance_to(target)
    local player_pos = get_player_position()
    local target_pos

    if target.get_position then
        target_pos = target:get_position()
    elseif target.x then
        target_pos = target
    end

    return player_pos:dist_to(target_pos)
end

function utils.check_z_distance(target, distance)
    local player_pos = get_player_position()
    local target_pos

    if target.get_position then
        target_pos = target:get_position()
    elseif target.x then
        target_pos = target
    end

    return math.abs(player_pos:z() - target_pos:z()) <= distance
end

---Returns wether the player is in the zone name specified
---@param zname string
function utils.player_in_zone(zname)
    return get_current_world():get_current_zone_name() == zname
end

function utils.player_in_region(rname)
    return get_current_world():get_current_zone_name():match(rname)
end

function utils.loot_on_floor()
    return loot_manager.any_item_around(get_player_position(), 30, true, true)
end

function utils.get_consumable_info(item)
    if not item then
        console.print("Error: Item is nil")
        return nil
    end
    local info = {}
    -- Helper function to safely get item properties
    local function safe_get(func, default)
        local success, result = pcall(func)
        return success and result or default
    end
    -- Get the item properties
    info.name = safe_get(function() return item:get_name() end, "Unknown")
    return info
end

function utils.is_inventory_full()
    if AlfredTheButlerPlugin then
        local status = AlfredTheButlerPlugin.get_status()
        if (status.enabled and status.need_trigger) then
            return true
        end
    elseif PLUGIN_alfred_the_butler then
        local status = PLUGIN_alfred_the_butler.get_status()
        if status.enabled and (
            status.inventory_full or
            status.restock_count > 0 or
            status.need_repair or
            status.teleport
        ) then
            return true
        end
    end
    return get_local_player():get_item_count() == 33
end

function utils.is_in_helltide()
    local buffs = get_local_player():get_buffs()
    for _, buff in ipairs(buffs) do
        if buff.name_hash == 1066539 then -- helltuide ID
        return true
        end
    end
    return false
end

function utils.is_teleporting()
    local buffs = get_local_player():get_buffs()
    for _, buff in ipairs(buffs) do
        if buff.name_hash == 44010 then -- teleport buff
        return true
        end
    end
    return false
end

function utils.have_whispering_key()
    local inventory = get_local_player():get_consumable_items()
    for _, item in pairs(inventory) do
        local item_info = utils.get_consumable_info(item)
        if item_info then
            if item_info.name == "GamblingCurrency_Key" then
                return true
            end
        end
    end

    return false
end

function utils.check_cinders(chest_name)
    local current_cinders = get_helltide_coin_cinders()
    if current_cinders >= enums.chest_types[chest_name] then
        return true
    else
        return false
    end
end

function utils.player_in_town()
    if get_local_player():get_attribute(attributes.PLAYER_IN_TOWN_LEVEL_AREA) == 1 then
        return true
    else
        return false
    end
end

function utils.helltide_active()
    local minute = tonumber(os.date("%M"))
    -- No helltide at this time.
    if minute >= 55 and minute <=59 then
        return false
    else
        return true
    end
end

function utils.do_events()
    local minute = tonumber(os.date("%M"))
    -- Don't do events at this time. Events are bugged and do not end
    if minute >= 45 then
        return false
    else
        return true
    end
end

return utils