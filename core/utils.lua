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

---Returns wether the player is in the zone name specified
---@param zname string
function utils.player_in_zone(zname)
    return get_current_world():get_current_zone_name() == zname
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

return utils