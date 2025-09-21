----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Audio Mixer Music Manager:

-- The Audio Mixer Music Manager allows modders to manage modded music for frontend, campaign, and battle. 
-- Examples of how the API is used can be found in the frontend, campaign, and battle manager scripts.
-- Thank you to my friends Eric Gordon Berg, Kou, Based Memes, Grakul and Ole for helping decide on the design of the modded music systems.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- @section Music Class
-------------------------------------------------------------------------------

---@class Music
---@field play_action_event string
---@field pause_action_event string
---@field resume_action_event string
---@field stop_action_event string
local Music = {}
Music.__index = Music

--- @desc : Constructor for a new Music instance.
--- @param play_action_event string : The Action Event for playing modded music.
--- @param pause_action_event string : The Action Event for pausing modded music.
--- @param resume_action_event string : The Action Event for resuming modded music.
--- @param stop_action_event string : The Action Event for stopping modded music.
--- @return Music : Returns the Music instance.
function Music:new(play_action_event, pause_action_event, resume_action_event, stop_action_event)
    local music = {}
    music.play_action_event = play_action_event
    music.pause_action_event = pause_action_event
    music.resume_action_event = resume_action_event
    music.stop_action_event = stop_action_event
    return music
end

--- @desc : Updates an existing Music instance.
--- @param play_action_event string : The Action Event for playing modded music.
--- @param pause_action_event string : The Action Event for pausing modded music.
--- @param resume_action_event string : The Action Event for resuming modded music.
--- @param stop_action_event string : The Action Event for stopping modded music.
function Music:update(play_action_event, pause_action_event, resume_action_event, stop_action_event)
    self.play_action_event = play_action_event
    self.pause_action_event = pause_action_event
    self.resume_action_event = resume_action_event
    self.stop_action_event = stop_action_event
end

-- API:

ammm = {}

-------------------------------------------------------------------------------
--- @section Constants
-------------------------------------------------------------------------------

-- We use Global_Music_Pause to stop vanilla music because Global_Music_Stop just immediately restarts it due to the way it's hardcoded
ammm.VANILLA_MUSIC_PAUSE_ACTION_EVENT = "Global_Music_Pause"

-------------------------------------------------------------------------------
--- @section General Functions
-------------------------------------------------------------------------------

--- @desc : Triggers an Action Event by its name. 
--- @param action_event string : The name of the Action Event to trigger.
--- @return boolean : Returns true if the Action Event is triggered, false if not.
function ammm.trigger_action_event(action_event)
    if type(action_event) ~= "string" or action_event == "" then
        ammm.log_error("'action_event' must be a non-empty string. Cannot trigger Action Event.")
        return false
    end

    ammm.log("Triggering Action Event: " ..action_event)
    common.trigger_soundevent(action_event)
    return true
end

--- @desc : Pauses the vanilla music. 
function ammm.pause_vanilla_music()
    ammm.trigger_action_event(ammm.VANILLA_MUSIC_PAUSE_ACTION_EVENT)
end

-------------------------------------------------------------------------------
--- @section Frontend Music Manager Functions
-------------------------------------------------------------------------------

ammm.frontend_music = {}  

--- @desc : Adds frontend music for a given theme.
--- @param theme_display_name string : The display name of the theme.
--- @param play_action_event string : The Action Event for playing modded music.
--- @return boolean : Returns true if added or updated, false if not.
function ammm.add_frontend_music(theme_display_name, play_action_event)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammm.log_error("theme_display_name must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        ammm.log_error("play_action_event must be a non-empty string.")
        return false
    end

    -- We make the pause, resume, and stop Action Events from the play Action Event name as that is how the Audio Editor does it
    local pause_action_event = play_action_event:gsub("^Play_", "Pause_")
    local resume_action_event = play_action_event:gsub("^Play_", "Resume_")
    local stop_action_event = play_action_event:gsub("^Play_", "Stop_")

    local existing_theme_music = ammm.frontend_music[theme_display_name]
    if existing_theme_music then
        existing_theme_music:update(play_action_event, stop_action_event)
        ammm.log("Updated frontend music for theme " ..theme_display_name)
        return true
    else
        local new_theme_music = Music:new(play_action_event, pause_action_event, resume_action_event, stop_action_event)
        ammm.frontend_music[theme_display_name] = new_theme_music
        ammm.log("Added frontend music for theme " ..theme_display_name)
        return true
    end
end

--- @desc : Removes the frontend music for a given theme.
--- @param theme_display_name string : The display name of the theme.
--- @return boolean : Returns true if removed, false if not.
function ammm.remove_frontend_music(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammm.log_error("theme_display_name must be a non-empty string. Cannot remove.")
        return false
    end

    if ammm.frontend_music[theme_display_name] then
        ammm.frontend_music[theme_display_name] = nil
        ammm.log("Removed frontend music for theme " ..theme_display_name)
        return true
    else
        ammm.log_error("Frontend music for theme " ..theme_display_name .." not found. Cannot remove.")
        return false
    end
end

--- @desc : Gets the frontend music for a given theme.
--- @param theme_display_name string : The display name of the theme.
--- @return Music|nil : Returns the Music if found, nil if not.
function ammm.get_frontend_music(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammm.log_error("theme_display_name must be a non-empty string.")
        return nil
    end
    return ammm.frontend_music[theme_display_name]
end

-------------------------------------------------------------------------------
--- @section Campaign Music Manager Functions
-------------------------------------------------------------------------------

ammm.campaign_music = {}

--- @desc : Adds campaign music for a given faction.
--- @param faction_key string : The faction_key to add / update.
--- @param play_action_event string : The Action Event for playing modded music.
--- @return boolean : Returns true if added, false if not.
function ammm.add_campaign_music(faction_key, play_action_event)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        ammm.log_error("play_action_event must be a non-empty string.")
        return false
    end

    -- We make the pause, resume, and stop Action Events from the play Action Event name as that is how the Audio Editor does it
    local pause_action_event = play_action_event:gsub("^Play_", "Pause_")
    local resume_action_event = play_action_event:gsub("^Play_", "Resume_")
    local stop_action_event = play_action_event:gsub("^Play_", "Stop_")

    local existing_faction_music = ammm.campaign_music[faction_key]
    if existing_faction_music then
        existing_faction_music:update(play_action_event, stop_action_event)
        ammm.log("Updated campaign music for faction " ..faction_key)
        return true
    else
        local new_faction_music = Music:new(play_action_event, pause_action_event, resume_action_event, stop_action_event)
        ammm.campaign_music[faction_key] = new_faction_music
        ammm.log("Added campaign music for faction " ..faction_key)
        return true
    end
end

--- @desc : Removes the campaign music for a given faction.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function ammm.remove_campaign_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key must be a non-empty string. Cannot remove.")
        return false
    end

    if ammm.campaign_music[faction_key] then
        ammm.campaign_music[faction_key] = nil
        ammm.log("Removed campaign music for faction " ..faction_key)
        return true
    else
        ammm.log_error("Battle music for faction " ..faction_key .." not found. Cannot remove.")
        return false
    end
end

--- @desc : Gets the campaign music for a given faction.
--- @param faction_key string : The faction_key to get the music for.
--- @return Music|nil : Returns Music if found, nil if not.
function ammm.get_campaign_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key must be a non-empty string.")
        return nil
    end
    return ammm.campaign_music[faction_key]
end

-------------------------------------------------------------------------------
--- @section Battle Music Manager Functions
-------------------------------------------------------------------------------

ammm.battle_music = {}

--- @desc : Adds battle music for a given faction.
--- @param faction_key string : The faction_key to add / update.
--- @param play_action_event string : The Action Event for playing modded music.
--- @return boolean : Returns true if added, false if not.
function ammm.add_battle_music(faction_key, play_action_event)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        ammm.log_error("play_action_event must be a non-empty string.")
        return false
    end

    -- We make the pause, resume, and stop Action Events from the play Action Event name as that is how the Audio Editor does it
    local pause_action_event = play_action_event:gsub("^Play_", "Pause_")
    local resume_action_event = play_action_event:gsub("^Play_", "Resume_")
    local stop_action_event = play_action_event:gsub("^Play_", "Stop_")

    local existing_faction_music = ammm.battle_music[faction_key]
    if existing_faction_music then
        existing_faction_music:update(play_action_event, stop_action_event)
        ammm.log("Updated battle music for faction " ..faction_key)
        return true
    else
        local new_faction_music = Music:new(play_action_event, pause_action_event, resume_action_event, stop_action_event)
        ammm.battle_music[faction_key] = new_faction_music
        ammm.log("Added battle music for faction " ..faction_key)
        return true
    end
end

--- @desc : Removes the battle music for a given faction.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function ammm.remove_battle_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key must be a non-empty string. Cannot remove.")
        return false
    end

    if ammm.battle_music[faction_key] then
        ammm.battle_music[faction_key] = nil
        ammm.log("Removed battle music for faction " ..faction_key)
        return true
    else
        ammm.log_error("Battle music for faction " ..faction_key .." not found. Cannot remove.")
        return false
    end
end

--- @desc : Gets the battle music for a given faction.
--- @param faction_key string : The faction_key to get the music for.
--- @return Music|nil : Returns Music if found, nil if not.
function ammm.get_battle_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key must be a non-empty string.")
        return nil
    end
    return ammm.battle_music[faction_key]
end

-------------------------------------------------------------------------------
--- @section Logging Functions
-------------------------------------------------------------------------------

--- @desc : Logs a message to the game log.
--- @param text string : The message to log.
--- @param extra_prefix string|nil : Optional additional prefix to prepend after the main prefix.
function ammm.log(text, extra_prefix)
    if type(text) ~= "string" then
        ammm.log_error("'text' must be a string.")
    end

    local prefix = "Audio Mixer Music Manager" ..": "

    -- Add optional secondary prefix if provided
    if extra_prefix and extra_prefix ~= "" then
        prefix = prefix ..extra_prefix
    end

    local out_message
    if text ~= "" then
        out_message = string.format("%s%s", prefix, text)
    else
        out_message = "\n"
    end

    if out_message ~= "\n" then
        out(out_message)
    end
end

--- @desc : Logs an error message with the "Error:" prefix.
--- @param text string : The message to log.
function ammm.log_error(text)
    ammm.log(text, "Error: ")
end
