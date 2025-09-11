-- Audio Mixer Music Framework API
-- This script implements the Audio Mixer Music Framework API.
-- It allows mod authors to manage modded music for frontend, campaign, and battle.
-- Examples of how the API is used can be found in the frontend, campaign, and battle framework scripts.

-- API:

ammf = {}

-- Contants:

-- We use pause to stop vanilla music because stop just immediately restarts it due to the way it's hardcoded
ammf.VANILLA_MUSIC_PAUSE_ACTION_EVENT = "Global_Music_Pause"

-- General Functions:

--- @function : trigger_action_even.
--- @desc : Triggers an Action Event by its name. 
--- @param action_event string : The name of the Action Event to trigger.
--- @return boolean : Returns true if the Action Event is triggered, false if not.
function ammf.trigger_action_event(action_event)
    if type(action_event) ~= "string" or action_event == "" then
        ammf.log_error("'action_event' must be a non-empty string. Cannot trigger Action Event.")
        return false
    end

    ammf.log_error("Triggering Action Event: " ..action_event)
    common.trigger_soundevent(action_event)
    return true
end

--- @function : pause_vanilla_music.
--- @desc : Pauses the vanilla music. 
function ammf.pause_vanilla_music()
    ammf.trigger_action_event(ammf.VANILLA_MUSIC_PAUSE_ACTION_EVENT)
end

-- Frontend Music Framework Functions:

-- The storage for frontend themes.
-- Type: Dictionary<string theme_display_name, FrontendTheme frontend_theme>
local frontend_themes = {}  

---@class FrontendTheme
---@field theme_display_name string
---@field play_action_event string
---@field stop_action_event string

local FrontendTheme = {}
FrontendTheme.__index = FrontendTheme

--- @function : FrontendTheme:new
--- @desc : Constructor for a new FrontendTheme.
--- @param theme_display_name string : The display name of the theme.
--- @param play_action_event string : The action event for playing modded music.
--- @param stop_action_event string : The action event for stopping modded music.
--- @return FrontendTheme : Returns the FrontendTheme instance.
function FrontendTheme:new(theme_display_name, play_action_event, stop_action_event)
    local instance = setmetatable({}, self)
    instance.theme_display_name = theme_display_name or ""
    instance.play_action_event = play_action_event or ""
    instance.stop_action_event = stop_action_event or ""
    return instance
end

--- @function : FrontendTheme:update
--- @desc : Updates an existing FrontendTheme's values.
--- @param play_action_event string : The action event for playing modded music.
--- @param stop_action_event string : The action event for stopping modded music.
function FrontendTheme:update(play_action_event, stop_action_event)
    self.play_action_event = play_action_event or self.play_action_event
    self.stop_action_event = stop_action_event or self.stop_action_event
end

--- @function : add_frontend_theme
--- @desc : Adds a new theme or updates an existing one.
--- @param theme_display_name string : The unique display name of the theme.
--- @param play_action_event string : The event to trigger playing the theme.
--- @param stop_action_event string : The event to trigger stopping the theme.
--- @return boolean : Returns true if added, false if not.
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
        ammf.log("Updated theme: " ..theme_display_name .." with play_action_event: " ..play_action_event .." and stop_action_event: " ..stop_action_event)
        return true
    else
        local new_theme = FrontendTheme:new(theme_display_name, play_action_event, stop_action_event)
        frontend_themes[theme_display_name] = new_theme
        ammf.log("Registered new theme: " ..theme_display_name .." with play_action_event: " ..play_action_event .." and stop_action_event: " ..stop_action_event)
        return true
    end
end

--- @function : remove_frontend_theme
--- @desc : Removes a theme from the frontend music framework with type validation.
--- @param theme_display_name string : The unique display name of the theme.
--- @return boolean : Returns true if removed, false if not.
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
        ammf.log_error("Theme: '" ..theme_display_name .."' not found. Cannot remove.")
        return false
    end
end

--- @function : get_frontend_theme
--- @desc : Gets a registered theme by its display name with type validation.
--- @param theme_display_name string : The unique display name of the theme.
--- @return FrontendTheme|nil : Returns the FrontendTheme if found, nil if not.
function ammf.get_frontend_theme(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        ammf.log_error("'theme_display_name' must be a non-empty string. Cannot get theme.")
        return nil
    end

    return frontend_themes[theme_display_name]
end

-- Campaign Music Framework Functions:

-- The storage for each faction's campaign music.
-- Type: Dictionary<string faction_key, string action_event>
local campaign_faction_music = {}

--- @function : add_campaign_faction_action_event
--- @desc : Adds or updates a campaign music for a faction.
--- @param faction_key string : The faction_key to add / update.
--- @param action_event string : The Action Event to trigger.
--- @return boolean : Returns true if added, false if not.
function ammf.add_campaign_faction_action_event(faction_key, action_event)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammf.log_error("'faction_key' must be a non-empty string.")
        return false
    end

    if type(action_event) ~= "string" or action_event == "" then
        ammf.log_error("'action_event' must be a non-empty string.")
        return false
    end

    local entry_exists = campaign_faction_music[faction_key] ~= nil
    campaign_faction_music[faction_key] = action_event

    if entry_exists then
        ammf.log("Updated faction_key: " ..faction_key .." with action_event: " ..action_event)
    else
        ammf.log("Registered new faction_key: " ..faction_key .." with action_event: " ..action_event)
    end

    return true
end

--- @function : remove_campaign_faction_action_event
--- @desc : Removes the faction's campaign music item.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function ammf.remove_campaign_faction_action_event(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammf.log_error("faction_key' must be a non-empty string. Cannot remove Action Event.")
        return false
    end

    if campaign_faction_music[faction_key] then
        campaign_faction_music[faction_key] = nil
        ammf.log("Removed Action Event for faction_key: " ..faction_key)
        return true
    else
        ammf.log_error("faction_key: '" ..faction_key .."' not found. Cannot remove.")
        return false
    end
end

--- @function : get_campaign_faction_action_event
--- @desc : Gets the Action Event for a given faction_key.
--- @param faction_key string: The faction_key whose Action Event to retrieve.
--- @return string|nil : Returns the action_event if found, nil if not.
function ammf.get_campaign_faction_action_event(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammf.log_error("'faction_key' must be a non-empty string. Cannot get Action Event.")
        return nil
    end

    return campaign_faction_music[faction_key]
end

-- Battle Music Framework Functions:

-- The storage for each faction's campaign music.
-- Type: Dictionary<string faction_key, string action_event>
local battle_faction_music = {}

--- @function : add_battle_faction_action_event
--- @desc : Adds or updates a battle music for a faction.
--- @param faction_key string : The faction_key to add / update.
--- @param action_event string : The Action Event to trigger.
--- @return boolean : Returns true if added, false if not.
function ammf.add_battle_faction_action_event(faction_key, action_event)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammf.log_error("'faction_key' must be a non-empty string.")
        return false
    end

    if type(action_event) ~= "string" or action_event == "" then
        ammf.log_error("'action_event' must be a non-empty string.")
        return false
    end

    local entry_exists = battle_faction_music[faction_key] ~= nil
    battle_faction_music[faction_key] = action_event

    if entry_exists then
        ammf.log("Updated faction_key: " ..faction_key .." with action_event: " ..action_event)
    else
        ammf.log("Registered new faction_key: " ..faction_key .." with action_event: " ..action_event)
    end

    return true
end

--- @function : remove_battle_faction_action_event
--- @desc : Removes the faction's battle music.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function ammf.remove_battle_faction_action_event(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammf.log_error("faction_key' must be a non-empty string. Cannot remove Action Event.")
        return false
    end

    if battle_faction_music[faction_key] then
        battle_faction_music[faction_key] = nil
        ammf.log("Removed Action Event for faction_key: " ..faction_key)
        return true
    else
        ammf.log_error("faction_key: '" ..faction_key .."' not found. Cannot remove.")
        return false
    end
end

--- @function : get_battle_faction_action_event
--- @desc : Gets the Action Event for a given faction_key.
--- @param faction_key string: The faction_key whose Action Event to retrieve.
--- @return string|nil : Returns the action_event if found, nil if not.
function ammf.get_battle_faction_action_event(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        ammf.log_error("'faction_key' must be a non-empty string. Cannot get Action Event.")
        return nil
    end

    return battle_faction_music[faction_key]
end

-- Logging Functions:

--- @function : log
--- @desc : Logs a message to the game log.
--- @param text string : The message to log.
--- @param extra_prefix string|nil : Optional additional prefix to prepend after the main prefix.
function ammf.log(text, extra_prefix)
    if type(text) ~= "string" then
        ammf.log_error("'text' must be a string.")
    end

    local prefix = "Audio Mixer Music Framework" ..": "

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

--- @function : log_error
--- @desc : Logs an error message with the "Error:" prefix.
--- @param text string : The message to log.
function ammf.log_error(text)
    ammf.log(text, "Error: ")
end