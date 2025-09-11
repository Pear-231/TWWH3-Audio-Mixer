local function play_campaign_music()
    -- This should? play music according to the local faction unless audio is triggered globally for some reason.
    local local_player_faction_key = cm:get_local_faction(true)
    local action_event = ammf.get_campaign_faction_action_event(local_player_faction_key)
    if action_event ~= nil then
        ammf.pause_vanilla_music()
        ammf.trigger_action_event(action_event)
    end
end

if core:is_campaign() then
    play_campaign_music()
end