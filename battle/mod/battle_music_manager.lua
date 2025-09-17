----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Battle Music Manager:

-- The Battle Music Manager replaces the vanilla dynamic music system with a more traditional 
-- looping random playlist which exhausts all other items before playing one it's already played.

-- The recommended settings for a battle music Action Event are:
-- Two audio files: the first one the theme music, the second one a silent track.
-- Playlist Type = Random Exhaustive
-- Repetition Interval = False
-- Playlist Mode = Continuous
-- Looping Type = Infinite Looping
-- Transition Type = Delay
-- Transition Duration = 1

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

local function log_battle_music()
    ammm.log("Battle Music:")
    for faction_key, play_action_event in pairs(ammm.battle_music) do
        ammm.log("faction_key: " .. faction_key .. ", play_action_event: " .. play_action_event)
    end
end

local function play_battle_music()
    -- This should? play music according to the local faction unless audio is triggered globally for some reason
	local local_player_army = bm:get_player_army()
	local local_player_faction_key = local_player_army:faction_key()
    local action_event = ammm.get_battle_music(local_player_faction_key)
    ammm.log("Checking for battle music for faction: " ..local_player_faction_key)

    if action_event ~= nil then
        ammm.log("Playing battle music for faction: " ..local_player_faction_key)
        ammm.pause_vanilla_music()
        ammm.trigger_action_event(action_event)
    end
end

local function initialise_battle_music_manager()
    timer_manager:remove_callback("ammf_initialise_battle_music_manager_callback")
    log_battle_music()
    play_battle_music()
end

if core:is_battle() then
    -- Wait for mods to add battle music
    timer_manager:callback(
        function() 
            initialise_battle_music_manager() 
        end, 
        1000, 
        "ammf_initialise_battle_music_manager_callback"
    )
end

