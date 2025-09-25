----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Audio Mixer Campaign Music Manager:

-- The Audio Mixer Campaign Music Manager implements the Audio Mixer Campaign Music System and the 
-- audio_mixer_campaign_music_manager object interface which exposes an API to interact with the system.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- @section Audio Mixer Campaign Music System

-- The Audio Mixer Campaign Music System replaces the vanilla dynamic music system with a more traditional 
-- looping random playlist which exhausts all other items before playing one it's already played.

-- The recommended settings for a campaign music Action Event are:
-- Audio Files: All the music files you want to use in the playlist. 
-- Playlist Type = Random Exhaustive
-- Repetition Interval = False
-- Playlist Mode = Continuous
-- Looping Type = Infinite Looping
-- Transition Type = Delay
-- Transition Duration = 1
-------------------------------------------------------------------------------

local function get_faction_music()
    local local_player_faction_key = cm:get_local_faction_name(true)
    local faction_music = audio_mixer_music_manager.campaign:get_music(local_player_faction_key)
    return faction_music, local_player_faction_key
end

local function restart_vanilla_music(faction_key)
    audio_mixer_music_manager.campaign:log("No music found for faction " ..faction_key ..", restarting vanilla music.")
    audio_mixer_music_manager:restart_vanilla_music()
end

local function pause_vanilla_music()
    audio_mixer_music_manager.campaign:log("Pausing vanilla music")
    audio_mixer_music_manager:pause_vanilla_music()
end

local function resume_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.campaign:log("Resuming modded music for faction " ..local_player_faction_key)
        audio_mixer_music_manager:trigger_action_event(faction_music.resume_action_event)
    end
end

local function pause_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.campaign:log("Pausing modded music for faction " ..local_player_faction_key)
        audio_mixer_music_manager:trigger_action_event(faction_music.pause_action_event)
    end
end

local function play_modded_music(faction_music, local_player_faction_key)
    audio_mixer_music_manager.campaign:log("Playing music for faction " ..local_player_faction_key)
    audio_mixer_music_manager:trigger_action_event(faction_music.play_action_event)
end

local function play_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        -- Vanilla music plays when the campaign starts so we pause it and play ours
        pause_vanilla_music()
        play_modded_music(faction_music, local_player_faction_key)
    else
        -- Vanilla music seems to need life support to function if the last campaign played before the 
        -- game was restarted paused the vanilla music so we restart the vanilla music it manually.
        restart_vanilla_music(local_player_faction_key)
    end
end

local function on_esc_menu_closed()        
    local faction_music = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.campaign:log("esc_menu closed, resuming music")
        pause_vanilla_music()
        resume_modded_music()
    end
end

local function on_esc_menu_opened()
    -- We only handle the esc_menu for modded music because the vanilla system keeps playing music but at a 
    -- lower volume I don't really like that so am replacing that with a full on pause but only for modded music.
    local faction_music = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.campaign:log("esc_menu opened, pausing music")
        pause_vanilla_music()
        pause_modded_music()
    end
end

local function add_listeners()  
    core:add_listener(
        "amcmm_esc_menu_closed_listener",
        "ScriptEventPanelClosedCampaign",
        function(context)
            return context.string == "esc_menu";
        end,
        on_esc_menu_closed,
        true
    );

    core:add_listener(
        "amcmm_esc_menu_opened_listener",
        "ScriptEventPanelOpenedCampaign",
        function(context)
            return context.string == "esc_menu";
        end,
        on_esc_menu_opened,
        true
    );

    core:add_listener(
        "amcmm_campaign_intro_movie_finished_listener",
        "ScriptEventAmmmCampaignIntroMovieFinished",
        true,
        function()
            audio_mixer_campaign_music_manager:log("Campaign intro movie finished.")
            play_music()
        end,
        false
    );
end

local function listen_for_intro_movie_finishing()
    audio_mixer_campaign_music_manager:log("Intro movie is playing, setting up listener to listen for when it finishes")
    cm:repeat_callback(
        function()
            local intro_movie = find_uicomponent(core:get_ui_root(), "movie_overlay_intro_movie")
            if not intro_movie then
                cm:remove_callback("amfmm_is_movie_overlay_intro_movie_visible_callback")
                core:trigger_event("ScriptEventAmmmCampaignIntroMovieFinished")
            end
        end,
        0.1,
        "amfmm_is_movie_overlay_intro_movie_visible_callback"
    );
end

-------------------------------------------------------------------------------
--- @section AudioMixerCampaignMusicManager Class
-------------------------------------------------------------------------------

--- @class AudioMixerCampaignMusicManager
--- @field music table<string, Music>
audio_mixer_campaign_music_manager = { 
    music = {}
}

--- @description : Constructor to create the audio_mixer_campaign_music_manager object interface.
--- @param audio_mixer_music_manager AudioMixerMusicManager : The AudioMixerMusicManager instance.
function audio_mixer_campaign_music_manager:create(audio_mixer_music_manager)
    local existing_instance = audio_mixer_music_manager.campaign
    if existing_instance then
        audio_mixer_music_manager.campaign = existing_instance
        return
    end

    local new_instance = {}
    set_object_class(new_instance, self)   
    audio_mixer_music_manager.campaign = new_instance

    cm:add_first_tick_callback(
        function() 
            add_listeners()

            core:progress_on_loading_screen_dismissed(
                function()
                    -- Allow time for a potential intro movie to start
                    cm:callback(
                        function() 
                            if common.is_any_movie_playing() then
                                listen_for_intro_movie_finishing()
                            else
                                play_music()
                            end
                        end, 
                        1
                    )
                end
            );
        end
    )

    self:log("Created audio_mixer_campaign_music_manager")
end

--- @description : Adds campaign music for a given faction.
--- @param faction_key string : The faction_key to add / update.
--- @param play_action_event string : The Action Event for playing modded music.
--- @return boolean : Returns true if added, false if not.
function audio_mixer_campaign_music_manager:add_music(faction_key, play_action_event)
    if type(faction_key) ~= "string" or faction_key == "" then
        self:log_error("faction_key must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        self:log_error("play_action_event must be a non-empty string.")
        return false
    end

    local existing_faction_music = self.music[faction_key]
    if existing_faction_music then
        existing_faction_music:update(play_action_event)
        self:log("Updated music for faction " ..faction_key)
        return true
    else
        local new_faction_music = Music:create(play_action_event)
        self.music[faction_key] = new_faction_music
        self:log("Added music for faction " ..faction_key)
        return true
    end
end

--- @description : Removes the campaign music for a given faction.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function audio_mixer_campaign_music_manager:remove_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        self:log_error("faction_key must be a non-empty string. Cannot remove.")
        return false
    end

    if self.music[faction_key] then
        self.music[faction_key] = nil
        self:log("Removed music for faction " ..faction_key)
        return true
    else
        self:log_error("Music for faction " ..faction_key .." not found. Cannot remove.")
        return false
    end
end

--- @description : Gets the campaign music for a given faction.
--- @param faction_key string : The faction_key to get the music for.
--- @return Music|nil : Returns Music if found, nil if not.
function audio_mixer_campaign_music_manager:get_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        self:log_error("faction_key must be a non-empty string.")
        return nil
    end
    return self.music[faction_key]
end

-------------------------------------------------------------------------------
--- @section Logging
-------------------------------------------------------------------------------

--- @description : Logs a message with the "Campaign" scope prefix.
--- @param text string : The message to log.
function audio_mixer_campaign_music_manager:log(text)
    audio_mixer_music_manager:log(text, "Campaign")
end

--- @description : Logs an error with the "Campaign" scope.
--- @param text string : The message to log.
function audio_mixer_campaign_music_manager:log_error(text)
    audio_mixer_music_manager:log_error(text, "Campaign")
end