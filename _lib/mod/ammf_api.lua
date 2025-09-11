-- ============================================================================
-- Audio Mixer Music Framework API
-- ============================================================================
-- This script implements the Audio Mixer Music Framework API.
-- It allows mod authors to manage modded music for frontend, campaign, and battle.
-- Examples of how the API is used can be found in the frontend, campaign, and battle framework scripts.
-- ============================================================================

ammf_api = {}
local frontend_themes = {}  

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

--- @function set_frontend_theme
--- @desc Registers a new theme or updates an existing one.
--- @param theme_display_name string - The unique display name of the theme.
--- @param play_action_event string - The event to trigger playing the theme.
--- @param stop_action_event string - The event to trigger stopping the theme.
--- @return boolean true on success, false on failure.
function ammf_api.set_frontend_theme(theme_display_name, play_action_event, stop_action_event)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammf_api.log("Error: 'theme_display_name' must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        ammf_api.log("Error: 'play_action_event' must be a non-empty string.")
        return false
    end

    if type(stop_action_event) ~= "string" or stop_action_event == "" then
        ammf_api.log("Error: 'stop_action_event' must be a non-empty string.")
        return false
    end

    local theme = frontend_themes[theme_display_name]
    if theme then
        theme:update(play_action_event, stop_action_event)
        ammf_api.log("Updated theme: " .. theme_display_name .. " with play_action_event: " .. play_action_event .. " and stop_action_event: " .. stop_action_event)
        return true
    else
        local new_theme = FrontendTheme:new(theme_display_name, play_action_event, stop_action_event)
        frontend_themes[theme_display_name] = new_theme
        ammf_api.log("Registered new theme: " .. theme_display_name .. " with play_action_event: " .. play_action_event .. " and stop_action_event: " .. stop_action_event)
        return true
    end
end

--- @function remove_frontend_theme
--- @desc Removes a theme from the frontend music framework with type validation.
--- @param theme_display_name string - The unique display name of the theme.
--- @return boolean true if removal was successful, false otherwise.
function ammf_api.remove_frontend_theme(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammf_api.log("Error: 'theme_display_name' must be a non-empty string. Cannot remove theme.")
        return false
    end

    if frontend_themes[theme_display_name] then
        frontend_themes[theme_display_name] = nil
        ammf_api.log("Removed theme: " .. theme_display_name)
        return true
    else
        ammf_api.log("Error: Theme '" .. theme_display_name .. "' not found. Cannot remove.")
        return false
    end
end

--- @function get_frontend_theme
--- @desc Gets a registered theme by its display name with type validation.
--- @param theme_display_name string - The unique display name of the theme.
--- @return FrontendTheme|nil The theme object if found, nil otherwise.
function ammf_api.get_frontend_theme(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammf_api.log("Error: 'theme_display_name' must be a non-empty string. Cannot get theme.")
        return nil
    end

    return frontend_themes[theme_display_name]
end

--- @function log
--- @desc Logs a message to the game log.
--- @param text string - The message to log.
function ammf_api.log(text)
    if type(text) ~= "string" then
        ammf_api.log("Error: 'text' must be a string.")
        return nil
    end

    local prefix = "Audio Mixer Music Framework" .. ": "

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