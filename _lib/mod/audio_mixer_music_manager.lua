----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Audio Mixer Music Manager:

-- The Audio Mixer Music Manager implements the Audio Mixer's replacement of the vanilla music systems for frontend, campaign and battle, to facilitate modding music into the game. 
-- Modders can manage modded music for frontend, campaign and battle using the respective manager.
-- Information on how each system is implemented can be found in each manager's script.
-- Examples of how to use the managers and an example Audio Project for the Audio Editor can be found in Eric Gordon Berg's wonderful Harmony of Shadows original sountrack mod.
-- Thank you to my friends Eric Gordon Berg, Ace, Based Memes, Kou, Grakul and Ole for helping design the music systems, and Ace for helping me get started with the scripts.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- @section AudioMixerMusicManager Class
-------------------------------------------------------------------------------

--- @class AudioMixerMusicManager
--- @field battle AudioMixerBattleMusicManager|nil
--- @field frontend AudioMixerFrontendMusicManager|nil
--- @field campaign AudioMixerCampaignMusicManager|nil
--- @field vanilla_music_stop_action_event string
--- @field vanilla_music_pause_action_event string
--- @field vanilla_music_resume_action_event string
audio_mixer_music_manager = {
    frontend = nil,
    campaign = nil,
    battle = nil,
    vanilla_music_stop_action_event = "Global_Music_Stop",
    vanilla_music_pause_action_event = "Global_Music_Pause"
}

--- @description : Constructor to create the audio_mixer_music_manager instance.
function audio_mixer_music_manager:create()
    local existing_instance = core:get_static_object("audio_mixer_music_manager")
    if existing_instance then
        return
    end

    local new_instance = {}
    set_object_class(new_instance, self)
    core:add_static_object("audio_mixer_music_manager", new_instance)

    -- Create the scoped music managers
    if core:is_frontend() then
        audio_mixer_frontend_music_manager:create(audio_mixer_music_manager)
    elseif core:is_campaign() then
        audio_mixer_campaign_music_manager:create(audio_mixer_music_manager)
    elseif core:is_battle() then
        audio_mixer_battle_music_manager:create(audio_mixer_music_manager)
    end

    self:log("Created audio_mixer_music_manager")
end

-------------------------------------------------------------------------------
--- @section Action Event Triggering
-------------------------------------------------------------------------------

--- @description : Triggers an Action Event by its name. 
--- @param action_event string : The name of the Action Event to trigger.
--- @return boolean : Returns true if the Action Event is triggered, false if not.
function audio_mixer_music_manager:trigger_action_event(action_event)
    if type(action_event) ~= "string" or action_event == "" then
        self:log_error("'action_event' must be a non-empty string. Cannot trigger Action Event.")
        return false
    end

    self:log("Triggering Action Event: " ..action_event)
    common.trigger_soundevent(action_event)
    return true
end

--- @description : Stops the vanilla music that is currently playing and then restarts the music immediately after due to the way it's hardcoded.
function audio_mixer_music_manager:restart_vanilla_music()
    self:trigger_action_event(self.vanilla_music_stop_action_event)
end

--- @description : Pauses the vanilla music. 
function audio_mixer_music_manager:pause_vanilla_music()
    self:trigger_action_event(self.vanilla_music_pause_action_event)
end

-------------------------------------------------------------------------------
--- @section Logging
-------------------------------------------------------------------------------

--- @description : Logs a message to the game log.
--- @param text string : The message to log.
--- @param scope string|nil : Optional scope prefix to add to the main log prefix.
--- @param log_type string|nil : Optional log type to show after the main log prefix.
function audio_mixer_music_manager:log(text, scope, log_type)
    if type(text) ~= "string" then
        self:log_error("'text' must be a string.", scope)
        return
    end

    local base = "Audio Mixer Music Manager"
    if scope and scope ~= "" then
        base = base .. " - " .. scope
    end
    if log_type and log_type ~= "" then
        base = base .. " " .. log_type
    end
    local prefix = base .. ": "

    local out_message = (text ~= "") and (prefix .. text) or "\n"
    if out_message ~= "\n" then
        out(out_message)
    end
end

--- @description : Logs an error message to the game log.
--- @param text string : The message to log.
--- @param scope string|nil : Optional scope prefix to add to the main log prefix.
function audio_mixer_music_manager:log_error(text, scope)
    self:log(text, scope, "Error")
end

-------------------------------------------------------------------------------
--- @section Music Class
-------------------------------------------------------------------------------

--- @class Music
--- @field play_action_event string
--- @field pause_action_event string
--- @field resume_action_event string
--- @field stop_action_event string
Music = {}

--- @description : Constructor for a new Music instance.
--- @param play_action_event string : The Action Event for playing modded music.
--- @return Music : Returns the Music instance.
function Music:create(play_action_event)
    -- We make the pause, resume, and stop Action Events from the play Action Event name as that is how the Audio Editor does it.
    local pause_action_event = play_action_event:gsub("^Play_", "Pause_")
    local resume_action_event = play_action_event:gsub("^Play_", "Resume_")
    local stop_action_event = play_action_event:gsub("^Play_", "Stop_")

    local music = {
        play_action_event = play_action_event,
        pause_action_event = pause_action_event,
        resume_action_event = resume_action_event,
        stop_action_event = stop_action_event
    }
    set_object_class(music, self)
    return music
end

--- @description : Updates an existing Music instance.
--- @param play_action_event string : The Action Event for playing modded music.
function Music:update(play_action_event)
    -- We make the pause, resume, and stop Action Events from the play Action Event name as that is how the Audio Editor does it.
    local pause_action_event = play_action_event:gsub("^Play_", "Pause_")
    local resume_action_event = play_action_event:gsub("^Play_", "Resume_")
    local stop_action_event = play_action_event:gsub("^Play_", "Stop_")

    self.play_action_event = play_action_event
    self.pause_action_event = pause_action_event
    self.resume_action_event = resume_action_event
    self.stop_action_event = stop_action_event
end

audio_mixer_music_manager:create()