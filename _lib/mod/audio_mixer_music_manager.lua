----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Audio Mixer Music Manager:

-- The Audio Mixer Music Manager allows modders to manage modded music for frontend, campaign, and battle. 
-- Examples of how the API is used can be found in the frontend, campaign, and battle manager scripts.
-- Thank you to my friends Eric Gordon Berg, Kou, Based Memes, Grakul and Ole for helping decide on the design of the modded music systems.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

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

-- The storage for frontend themes
-- Type: Dictionary<string theme_display_name, FrontendTheme frontend_theme>
ammm.frontend_music = {}  

---@class FrontendTheme
---@field theme_display_name string
---@field play_action_event string
---@field stop_action_event string

local FrontendTheme = {}
FrontendTheme.__index = FrontendTheme

--- @desc : Constructor for a new FrontendTheme.
--- @param theme_display_name string : The display name of the theme.
--- @param play_action_event string : The Action Event for playing modded music.
--- @param stop_action_event string : The Action Event for stopping modded music.
--- @return FrontendTheme : Returns the FrontendTheme instance.
function FrontendTheme:new(theme_display_name, play_action_event, stop_action_event)
    local instance = setmetatable({}, self)
    instance.theme_display_name = theme_display_name or ""
    instance.play_action_event = play_action_event or ""
    instance.stop_action_event = stop_action_event or ""
    return instance
end

--- @desc : Updates an existing FrontendTheme's values.
--- @param play_action_event string : The Action Event for playing modded music.
--- @param stop_action_event string : The Action Event for stopping modded music.
function FrontendTheme:update(play_action_event, stop_action_event)
    self.play_action_event = play_action_event or self.play_action_event
    self.stop_action_event = stop_action_event or self.stop_action_event
end

--- @desc : Adds frontend music for a given theme.
--- @param theme_display_name string : The unique display name of the theme.
--- @param play_action_event string : The event to trigger playing the theme.
--- @param stop_action_event string : The event to trigger stopping the theme.
--- @return boolean : Returns true if added, false if not.
function ammm.add_frontend_music(theme_display_name, play_action_event, stop_action_event)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammm.log_error("'theme_display_name' must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        ammm.log_error("'play_action_event' must be a non-empty string.")
        return false
    end

    if type(stop_action_event) ~= "string" or stop_action_event == "" then
        ammm.log_error("'stop_action_event' must be a non-empty string.")
        return false
    end

    local theme = ammm.frontend_music[theme_display_name]
    if theme then
        theme:update(play_action_event, stop_action_event)
        ammm.log("Updated frontend theme: " ..theme_display_name .." with play_action_event: " ..play_action_event .." and stop_action_event: " ..stop_action_event)
        return true
    else
        local new_theme = FrontendTheme:new(theme_display_name, play_action_event, stop_action_event)
        ammm.frontend_music[theme_display_name] = new_theme
        ammm.log("Added new frontend theme: " ..theme_display_name .." with play_action_event: " ..play_action_event .." and stop_action_event: " ..stop_action_event)
        return true
    end
end

--- @desc : Removes the frontend music for a given theme.
--- @param theme_display_name string : The unique display name of the theme.
--- @return boolean : Returns true if removed, false if not.
function ammm.remove_frontend_music(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammm.log_error("theme_display_name' must be a non-empty string. Cannot remove frontend theme.")
        return false
    end

    if ammm.frontend_music[theme_display_name] then
        ammm.frontend_music[theme_display_name] = nil
        ammm.log("Removed frontend theme: " ..theme_display_name)
        return true
    else
        ammm.log_error("Frontend theme: '" ..theme_display_name .."' not found. Cannot remove.")
        return false
    end
end

--- @desc : Gets the frontend music for a given theme.
--- @param theme_display_name string : The unique display name of the theme.
--- @return FrontendTheme|nil : Returns the FrontendTheme if found, nil if not.
function ammm.get_frontend_theme(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammm.log_error("'theme_display_name' must be a non-empty string.")
        return nil
    end

    return ammm.frontend_music[theme_display_name]
end

-------------------------------------------------------------------------------
--- @section Campaign Music Manager Functions
-------------------------------------------------------------------------------

-- The storage for each faction's campaign music
-- Type: Dictionary<string faction_key, string action_event>
ammm.campaign_music = {}

--- @desc : Adds or updates the campaign music for a given faction.
--- @param faction_key string : The faction_key to add / update.
--- @param action_event string : The Action Event to trigger.
--- @return boolean : Returns true if added, false if not.
function ammm.add_campaign_music(faction_key, action_event)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("'faction_key' must be a non-empty string.")
        return false
    end

    if type(action_event) ~= "string" or action_event == "" then
        ammm.log_error("'action_event' must be a non-empty string.")
        return false
    end

    local entry_exists = ammm.campaign_music[faction_key] ~= nil
    ammm.campaign_music[faction_key] = action_event

    if entry_exists then
        ammm.log("Updated faction_key: " ..faction_key .." with action_event: " ..action_event)
    else
        ammm.log("Added new faction_key: " ..faction_key .." with action_event: " ..action_event)
    end

    return true
end

--- @desc : Removes the campaign music for a given faction.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function ammm.remove_campaign_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key' must be a non-empty string. Cannot remove Action Event.")
        return false
    end

    if ammm.campaign_music[faction_key] then
        ammm.campaign_music[faction_key] = nil
        ammm.log("Removed Action Event for faction_key: " ..faction_key)
        return true
    else
        ammm.log_error("faction_key: '" ..faction_key .."' not found. Cannot remove.")
        return false
    end
end

--- @desc : Gets the Action Event for a given faction.
--- @param faction_key string: The faction_key whose Action Event to retrieve.
--- @return string|nil : Returns the action_event if found, nil if not.
function ammm.get_campaign_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("'faction_key' must be a non-empty string. Cannot get Action Event.")
        return nil
    end

    return ammm.campaign_music[faction_key]
end

-------------------------------------------------------------------------------
--- @section Battle Music Manager Functions
-------------------------------------------------------------------------------

-- The storage for each faction's campaign music
-- Type: Dictionary<string faction_key, string action_event>
ammm.battle_music = {}

--- @desc : Adds or updates a the battle music for a faction.
--- @param faction_key string : The faction_key to add / update.
--- @param action_event string : The Action Event to trigger.
--- @return boolean : Returns true if added, false if not.
function ammm.add_battle_music(faction_key, action_event)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("'faction_key' must be a non-empty string.")
        return false
    end

    if type(action_event) ~= "string" or action_event == "" then
        ammm.log_error("'action_event' must be a non-empty string.")
        return false
    end

    local entry_exists = ammm.battle_music[faction_key] ~= nil
    ammm.battle_music[faction_key] = action_event

    if entry_exists then
        ammm.log("Updated faction_key: " ..faction_key .." with action_event: " ..action_event)
    else
        ammm.log("Added new faction_key: " ..faction_key .." with action_event: " ..action_event)
    end

    return true
end

--- @desc : Removes the battle music for a given faction.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function ammm.remove_battle_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("faction_key' must be a non-empty string. Cannot remove Action Event.")
        return false
    end

    if ammm.battle_music[faction_key] then
        ammm.battle_music[faction_key] = nil
        ammm.log("Removed Action Event for faction_key: " ..faction_key)
        return true
    else
        ammm.log_error("faction_key: '" ..faction_key .."' not found. Cannot remove.")
        return false
    end
end

--- @desc : Gets the Action Event for a given faction.
--- @param faction_key string: The faction_key whose Action Event to retrieve.
--- @return string|nil : Returns the action_event if found, nil if not.
function ammm.get_battle_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammm.log_error("'faction_key' must be a non-empty string. Cannot get Action Event.")
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
