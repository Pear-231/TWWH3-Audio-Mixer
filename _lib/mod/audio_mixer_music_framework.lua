-- Audio Mixer Music Framework API
-- This script implements the Audio Mixer Music Framework API.
-- It allows mod authors to manage modded music for frontend, campaign, and battle.
-- Examples of how the API is used can be found in the frontend, campaign, and battle framework scripts.

ammf = {}
local frontend_themes = {}  

-- We use pause to stop vanilla music because stop just immediately restarts it due to the way it's hardcoded
ammf.VANILLA_MUSIC_PAUSE_ACTION_EVENT = "Global_Music_Pause"

-- General API Functions:

--- @function trigger_action_event
--- @desc Triggers an Action Event by its name. 
--- Logs an error if the argument is not a non-empty string.
--- @param action_event string - The name of the Action Event to trigger.
function ammf.trigger_action_event(action_event)
    if type(action_event) ~= "string" or action_event == "" then
        ammf.log_error("'action_event' must be a non-empty string. Cannot trigger Action Event.")
        return
    end

    ammf.log_error("Triggering Action Event: " ..action_event)
    common.trigger_soundevent(action_event)
end

-- Frontend Functions:

---@class FrontendTheme
---@field theme_display_name string
---@field play_action_event string
---@field stop_action_event string

local FrontendTheme = {}
FrontendTheme.__index = FrontendTheme

--- @function FrontendTheme:new
--- @desc Constructor for a new FrontendTheme.
--- @param theme_display_name string - The display name of the theme.
--- @param play_action_event string - The action event for playing modded music.
--- @param stop_action_event string - The action event for stopping modded music.
--- @return FrontendTheme
function FrontendTheme:new(theme_display_name, play_action_event, stop_action_event)
    local instance = setmetatable({}, self)
    instance.theme_display_name = theme_display_name or ""
    instance.play_action_event = play_action_event or ""
    instance.stop_action_event = stop_action_event or ""
    return instance
end

--- @function FrontendTheme:update
--- @desc Updates an existing FrontendTheme's values.
--- @param play_action_event string - The action event for playing modded music.
--- @param stop_action_event string - The action event for stopping modded music.
function FrontendTheme:update(play_action_event, stop_action_event)
    self.play_action_event = play_action_event or self.play_action_event
    self.stop_action_event = stop_action_event or self.stop_action_event
end

--- @function add_frontend_theme
--- @desc Adds a new theme or updates an existing one.
--- @param theme_display_name string - The unique display name of the theme.
--- @param play_action_event string - The event to trigger playing the theme.
--- @param stop_action_event string - The event to trigger stopping the theme.
--- @return boolean true if success, false if failure.
function ammf.add_frontend_theme(theme_display_name, play_action_event, stop_action_event)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammf.log_error("'theme_display_name' must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        ammf.log_error("'play_action_event' must be a non-empty string.")
        return false
    end

    if type(stop_action_event) ~= "string" or stop_action_event == "" then
        ammf.log_error("'stop_action_event' must be a non-empty string.")
        return false
    end

    local theme = frontend_themes[theme_display_name]
    if theme then
        theme:update(play_action_event, stop_action_event)
        ammf.log_error("Updated theme: " ..theme_display_name .." with play_action_event: " ..play_action_event .." and stop_action_event: " ..stop_action_event)
        return true
    else
        local new_theme = FrontendTheme:new(theme_display_name, play_action_event, stop_action_event)
        frontend_themes[theme_display_name] = new_theme
        ammf.log("Registered new theme: " ..theme_display_name .." with play_action_event: " ..play_action_event .." and stop_action_event: " ..stop_action_event)
        return true
    end
end

--- @function remove_frontend_theme
--- @desc Removes a theme from the frontend music framework with type validation.
--- @param theme_display_name string - The unique display name of the theme.
--- @return boolean true if removal was successful, false otherwise.
function ammf.remove_frontend_theme(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammf.log_error("theme_display_name' must be a non-empty string. Cannot remove theme.")
        return false
    end

    if frontend_themes[theme_display_name] then
        frontend_themes[theme_display_name] = nil
        ammf.log("Removed theme: " ..theme_display_name)
        return true
    else
        ammf.log_error("Theme '" ..theme_display_name .."' not found. Cannot remove.")
        return false
    end
end

--- @function get_frontend_theme
--- @desc Gets a registered theme by its display name with type validation.
--- @param theme_display_name string - The unique display name of the theme.
--- @return FrontendTheme|nil The theme object if found, nil otherwise.
function ammf.get_frontend_theme(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammf.log_error("'theme_display_name' must be a non-empty string. Cannot get theme.")
        return nil
    end

    return frontend_themes[theme_display_name]
end

-- Logging Functions:

--- @function log
--- @desc Logs a message to the game log.
--- @param text string - The message to log.
--- @param extra_prefix string|nil - Optional additional prefix to prepend after the main prefix.
function ammf.log(text, extra_prefix)
    if type(text) ~= "string" then
        ammf.log_error("'text' must be a string.")
    end

    local prefix = "Audio Mixer Music Framework" ..": "

    -- add optional secondary prefix if provided
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

--- @function log_error
--- @desc Logs an error message with the "Error:" prefix.
--- @param text string - The error message to log.
function ammf.log_error(text)
    ammf.log(text, "Error: ")
end