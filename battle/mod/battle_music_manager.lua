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

local function get_faction_music()
    local local_player_army = bm:get_player_army()
	local local_player_faction_key = local_player_army:faction_key()
    local faction_music = ammm.get_battle_music(local_player_faction_key)
    return faction_music, local_player_faction_key
end

local function play_battle_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        ammm.log("Playing battle music for faction " ..local_player_faction_key)
        ammm.pause_vanilla_music()
        ammm.trigger_action_event(faction_music.play_action_event)
    end
end

local function pause_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        ammm.log("Pausing battle music for faction " ..local_player_faction_key)
        ammm.trigger_action_event(faction_music.pause_action_event)
    end
end

local function resume_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        ammm.log("Resuming battle music for faction " ..local_player_faction_key)
        ammm.trigger_action_event(faction_music.resume_action_event)
    end
end

local function log_battle_music()
    ammm.log("Battle Music:")
    ammm.log(table.tostring(ammm.battle_music, false, -1))
end

local function initialise_battle_music_manager()
    timer_manager:remove_callback("ammf_initialise_battle_music_manager_callback")
    
    core:add_listener(
        "ammm_battle_esc_menu_closed_listener",
        "ScriptEventPanelClosedBattle",
        function(context)
            return context.string == "esc_menu";
        end,
        function()
            -- Vanilla music plays when the esc_menu is closed so we pause it
            ammm.pause_vanilla_music()

            ammm.log("esc_menu closed, resuming music")
            resume_modded_music()
        end,
        true
    );

    core:add_listener(
        "ammm_battle_esc_menu_opened_listener",
        "ScriptEventPanelOpenedBattle",
        function(context)
            return context.string == "esc_menu";
        end,
        function()
            ammm.log("esc_menu opened, pausing music")
            pause_modded_music()
        end,
        true
    );

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