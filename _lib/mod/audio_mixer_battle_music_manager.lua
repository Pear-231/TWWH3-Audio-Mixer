----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Audio Mixer Battle Music Manager:

-- The Audio Mixer Battle Music Manager implements the Audio Mixer Battle Music System and the 
-- audio_mixer_battle_music_manager object interface which exposes an API to interact with the system.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- @section Audio Mixer Battle Music System

-- The Audio Mixer Battle Music System replaces the vanilla dynamic music system with a more traditional
-- looping random playlist which exhausts all other items before playing one it's already played.

-- The recommended settings for a battle music Action Event are:
-- Audio Files: All the music files you want to use in the playlist. 
-- Playlist Type = Random Exhaustive
-- Repetition Interval = False
-- Playlist Mode = Continuous
-- Looping Type = Infinite Looping
-- Transition Type = Delay
-- Transition Duration = 1
-------------------------------------------------------------------------------

local function get_faction_music()
    local local_player_army = bm:get_player_army()
	local local_player_faction_key = local_player_army:faction_key()
    local faction_music = audio_mixer_music_manager.battle:get_music(local_player_faction_key)
    return faction_music, local_player_faction_key
end

local function restart_vanilla_music(faction_key)
    audio_mixer_music_manager.battle:log("No music found for faction " ..faction_key ..", restarting vanilla music.")
    audio_mixer_music_manager:restart_vanilla_music()
end

local function pause_vanilla_music()
    audio_mixer_music_manager.battle:log("Pausing vanilla music")
    audio_mixer_music_manager:pause_vanilla_music()
end

local function resume_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.battle:log("Resuming modded music for faction " ..local_player_faction_key)
        audio_mixer_music_manager:trigger_action_event(faction_music.resume_action_event)
    end
end

local function pause_modded_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.battle:log("Pausing modded music for faction " ..local_player_faction_key)
        audio_mixer_music_manager:trigger_action_event(faction_music.pause_action_event)
    end
end

local function play_modded_music(faction_music, local_player_faction_key)
    audio_mixer_music_manager.battle:log("Playing music for faction " ..local_player_faction_key)
    audio_mixer_music_manager:trigger_action_event(faction_music.play_action_event)
end

local function play_music()
    local faction_music, local_player_faction_key = get_faction_music()
    if faction_music ~= nil then
        -- Vanilla music plays when the battle starts so we pause it and play ours
        pause_vanilla_music()
        play_modded_music(faction_music, local_player_faction_key)
    else
        -- Vanilla music seems to need life support to function if the last battle played before the 
        -- game was restarted paused the vanilla music so we restart the vanilla music it manually.
        restart_vanilla_music(local_player_faction_key)
    end
end

local function on_esc_menu_closed()
    local faction_music = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.battle:log("esc_menu closed, resuming music")
        -- Pause the vanilla music again to be safe
        pause_vanilla_music()
        resume_modded_music()
    end
end

local function on_esc_menu_opened()
    -- We only handle the esc_menu for modded music because the vanilla system keeps playing music but at a 
    -- lower volume I don't really like that so am replacing that with a full on pause but only for modded music.
    local faction_music = get_faction_music()
    if faction_music ~= nil then
        audio_mixer_music_manager.battle:log("esc_menu opened, pausing music")
        pause_vanilla_music()
        pause_modded_music()
    end
end

local function on_battle_complete()
    local faction_music = get_faction_music()
    if faction_music ~= nil then    
        -- Vanilla battle music plays again when you complete a battle so we pause it
        audio_mixer_music_manager.battle:log("battle complete, pausing vanilla music")
        pause_vanilla_music()
    end
end

local function add_listeners()
    core:add_listener(
        "ambmm_esc_menu_closed_listener",
        "ScriptEventPanelClosedBattle",
        function(context)
            return context.string == "esc_menu";
        end,
        on_esc_menu_closed,
        true
    );

    core:add_listener(
        "ambmm_esc_menu_opened_listener",
        "ScriptEventPanelOpenedBattle",
        function(context)
            return context.string == "esc_menu";
        end,
        on_esc_menu_opened,
        true
    );

    core:add_listener(
        "ambmm_battle_completed_listener",
        "ScriptEventBattlePhaseChanged",
        function(context)
            return context.string == "Complete"
        end,
        on_battle_complete
    )
end

-------------------------------------------------------------------------------
--- @section AudioMixerBattleMusicManager Class
-------------------------------------------------------------------------------

--- @class AudioMixerBattleMusicManager
--- @field music table<string, Music>
audio_mixer_battle_music_manager = {
    music = {}
}

--- @description : Constructor to create the audio_mixer_battle_music_manager object interface.
--- @param audio_mixer_music_manager AudioMixerMusicManager : The AudioMixerMusicManager instance.
function audio_mixer_battle_music_manager:create(audio_mixer_music_manager)
    local existing_instance = audio_mixer_music_manager.battle
    if existing_instance then
        audio_mixer_music_manager.battle = existing_instance
        return
    end

    local new_instance = {}
    set_object_class(new_instance, self)
    audio_mixer_music_manager.battle = new_instance

    add_listeners()

    core:progress_on_loading_screen_dismissed(
        function()
            -- A short delay sounds nice
            bm:callback(play_music, 1000)
        end
    );

    self:log("Created audio_mixer_battle_music_manager")
end

--- @description : Adds battle music for a given faction.
--- @param faction_key string : The faction_key to add / update.
--- @param play_action_event string : The Action Event for playing modded music.
--- @return boolean : Returns true if added, false if not.
function audio_mixer_battle_music_manager:add_music(faction_key, play_action_event)
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

--- @description : Removes the battle music for a given faction.
--- @param faction_key string : The faction_key to remove.
--- @return boolean : Returns true if removed, false if not.
function audio_mixer_battle_music_manager:remove_music(faction_key)
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

--- @description : Gets the battle music for a given faction.
--- @param faction_key string : The faction_key to get the music for.
--- @return Music|nil : Returns Music if found, nil if not.
function audio_mixer_battle_music_manager:get_music(faction_key)
    if type(faction_key) ~= "string" or faction_key == "" then
        self:log_error("faction_key must be a non-empty string.")
        return nil
    end
    return self.music[faction_key]
end

-------------------------------------------------------------------------------
--- @section Logging
-------------------------------------------------------------------------------

--- @description : Logs a message with the "Battle" scope prefix.
--- @param text string : The message to log.
function audio_mixer_battle_music_manager:log(text)
    audio_mixer_music_manager:log(text, "Battle")
end

--- @description : Logs an error message with the "Battle" scope prefix.
--- @param text string : The message to log.
function audio_mixer_battle_music_manager:log_error(text)
    audio_mixer_music_manager:log_error(text, "Battle")
end