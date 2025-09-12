local function play_battle_music()
    timer_manager:remove_callback("ammf_play_battle_music_callback")

    -- This should? play music according to the local faction unless audio is triggered globally for some reason.
	local local_player_army = bm:get_player_army()
	local local_player_faction_key = local_player_army:faction_key()
    local action_event = ammf.get_battle_faction_action_event(local_player_faction_key)
    if action_event ~= nil then
        ammf.pause_vanilla_music()
        
        ammf.log("Playing battle music for faction: " ..local_player_faction_key)
        ammf.trigger_action_event(action_event)
    end
end

if core:is_battle() then
    -- Wait for mods to add battle music.
    timer_manager:callback(function() play_battle_music() end, 1000, "ammf_play_battle_music_callback")
end