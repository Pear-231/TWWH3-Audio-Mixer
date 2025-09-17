----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Campaign Music Manager:

-- The Campaign Music Manager replaces the vanilla dynamic music system with a more traditional 
-- looping random playlist which exhausts all other items before playing one it's already played.

-- The recommended settings for a campaign music Action Event are:
-- Two audio files: the first one the theme music, the second one a silent track.
-- Playlist Type = Random Exhaustive
-- Repetition Interval = False
-- Playlist Mode = Continuous
-- Looping Type = Infinite Looping
-- Transition Type = Delay
-- Transition Duration = 1

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

local function log_campaign_music()
    ammm.log("Campaign Music:")
    for faction_key, play_action_event in pairs(ammm.campaign_music) do
        ammm.log("faction_key: " .. faction_key .. ", play_action_event: " .. play_action_event)
    end
end

local function play_campaign_music()
    -- This should? play music according to the local faction unless audio is triggered globally for some reason
    local local_player_faction_key = cm:get_local_faction_name(true)
    local action_event = ammm.get_campaign_music(local_player_faction_key)
    ammm.log("Checking for campaign music for faction: " ..local_player_faction_key)

    if action_event ~= nil then
        ammm.log("Playing campaign music for faction: " ..local_player_faction_key)
        ammm.pause_vanilla_music()
        ammm.trigger_action_event(action_event)
    end
end

local function initialise_campaign_music_manager()
    cm:remove_callback("ammf_initialise_campaign_music_manager_callback")
    log_campaign_music()
    play_campaign_music()
end

if core:is_campaign() then
    -- Wait for mods to add campaign music
    cm:add_first_tick_callback(
        function() 
            cm:callback(
                function() 
                    initialise_campaign_music_manager() 
                end, 
            1, 
            "ammf_initialise_campaign_music_manager_callback") 
        end
    )
end