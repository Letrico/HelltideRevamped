local tracker = {
    has_salvaged = false,
    needs_salvage = false,
    helltide_start = false,
    waypoints = {}
}

function tracker.check_time(key, delay)
    local current_time = get_time_since_inject()
    if not tracker[key] then
        tracker[key] = current_time
    end
    if current_time - tracker[key] >= delay then
        return true
    end
    return false
end

function tracker.set_teleported_from_town(value)

    tracker.teleported_from_town = value

end

-- The plan is to have a separate table that stores all the key added by check_time and clear them all on exit
function tracker.clear_key(key)
    tracker[key] = nil
end

return tracker