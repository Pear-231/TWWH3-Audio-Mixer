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

local function get_faction_music()
    local local_player_faction_key = cm:get_local_faction_name(true)
    local faction_music = ammm.get_campaign_music(local_player_faction_key)
    return faction_music, local_player_faction_key
end

local function play_campaign_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        ammm.log("Playing campaign music for faction " ..local_player_faction_key)

        -- Vanilla music plays when the campaign starts so we pause it
        ammm.pause_vanilla_music()
        
        ammm.trigger_action_event(faction_music.play_action_event)
    end
end

local function pause_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        ammm.log("Pausing campaign music for faction " ..local_player_faction_key)
        ammm.trigger_action_event(faction_music.pause_action_event)
    end
end

local function resume_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        ammm.log("Resuming campaign music for faction " ..local_player_faction_key)
        ammm.trigger_action_event(faction_music.resume_action_event)
    end
end

local function log_campaign_music()
    ammm.log("Campaign Music:")
    ammm.log(table.tostring(ammm.campaign_music, false, -1))
end

local function initialise_campaign_music_manager()
    cm:remove_callback("ammf_initialise_campaign_music_manager_callback")
    
    core:add_listener(
        "ammm_campaign_esc_menu_closed_listener",
        "ScriptEventPanelClosedCampaign",
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
        "ammm_campaign_esc_menu_opened_listener",
        "ScriptEventPanelOpenedCampaign",
        function(context)
            return context.string == "esc_menu";
        end,
        function()
            ammm.log("esc_menu opened, pausing music")
            pause_modded_music()
        end,
        true
    );

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