----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Audio Mixer Frontend Music Manager:

-- The Audio Mixer Frontend Music Manager implements the Audio Mixer Frontend Music System and the
-- audio_mixer_frontend_music_manager object interface which exposes an API to interact with the system.

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- @section Audio Mixer Frontend Music System

-- The Audio Mixer Frontend Music System replicates the vanilla system of music being tied to themes.
-- It is replicated rather than directly modded because you cannot mod new Wwise Switches as they're hardcoded.
-- The system works by detecting what theme is currently visible and playing / stopping the corresponding Action Event.
-- The Action Events created for vanilla music can be found below.

-- The recommended settings for a frontend music Action Event to replicate the vanilla system are:
-- Audio Files: Two audio files, the first one the theme music, the second one the silent vanilla track.
-- Container Type = Sequence 
-- Playlist End Behaviour = Restart
-- Play Mode = Continuous
-- Always Reset Container = True
-- Looping Type = Infinite Looping
-- Transition Type = Delay
-- Transition Duration = 1
-------------------------------------------------------------------------------

-- The Audio Mixer contains these Action Events remade from the vanilla sounds. This is needed as sometimes if vanilla music 
-- is paused and the game later closed, strangely the next time the game is launched the vanilla music doesn't play 
-- until the Global_Music_Play event is triggered again. This is problematic as we can't tell if the vanilla music is playing 
-- or not and triggering Global_Music_Play if it's already playing would play the music again which could mean multiple 
-- music tracks playing at the same time (which we don't want!). So to avoid this problem we just remake the whole thing as 
-- individual Action Events so we have full control of what we want to play and when.
local vanilla_frontend_theme_music = {
    -- default_theme is used as a backup where there isn't a theme assigned or all others are overwritten
    ["default_theme"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },

    ["Total War: WARHAMMER I"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER I – Blood for the Blood God"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER I – Call of the Beastmen"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER I – The Grim & The Grave"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER I – The King & The Warlord"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER I – Realm of the Wood Elves"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER I – Bretonnia"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER I – Norsca"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: WARHAMMER II"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – Tomb Kings"] = { play_action_event = "Play_music_frontend_vanilla_tomb_kings_theme" },
    ["Total War: WARHAMMER II – The Queen & The Crone"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – Vampire Coast"] = { play_action_event = "Play_music_frontend_vanilla_vampire_coast_theme" },
    ["Total War: WARHAMMER II – The Prophet & The Warlock"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – The Hunter & The Beast"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – The Shadow & The Blade"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – The Warden & The Paunch"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – The Twisted & The Twilight"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – Rakarth"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER II – The Silence & The Fury"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: WARHAMMER III"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: WARHAMMER III – Champions of Chaos"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: WARHAMMER III – Mirror of Madness"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: WARHAMMER III – Forge of the Chaos Dwarfs"] = { play_action_event = "Play_music_frontend_vanilla_chaos_dwarfs_theme" },
    ["Total War: WARHAMMER III – Shadows of Change"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: WARHAMMER III – Thrones of Decay"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: WARHAMMER III – Omens of Destruction"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" }
}

local function get_theme_display_name()
    local theme_label_uic = find_uicomponent(core:get_ui_root(), "main", "theme_button_parent", "theme_label")
    local theme_display_name = theme_label_uic and theme_label_uic:GetStateText()
    return theme_display_name
end

local function get_default_theme_music()
    return audio_mixer_music_manager.frontend:get_music("default_theme")
end

local function get_saved_theme_from_svr()
    faction_key = core:svr_load_string("amfmm_theme")
    audio_mixer_music_manager.frontend:log("Loaded saved theme display name from svr: " ..tostring(faction_key))
    return faction_key
end

local function save_theme_in_svr(theme_display_name)
    if type(theme_display_name) == "string" and theme_display_name ~= "" then
        core:svr_save_string("amfmm_theme", theme_display_name)
        audio_mixer_music_manager.frontend:log("Saved theme display name to svr: " ..theme_display_name)
    end
end

local function cancel_pending_play_modded_music()
    tm:remove_callback("amfmm_play_modded_music_callback")
end

local function pause_vanilla_music(theme_display_name)
    audio_mixer_music_manager.frontend:log("Pausing vanilla music for frontend theme " ..theme_display_name)
    audio_mixer_music_manager:pause_vanilla_music()
end

local function play_modded_music(action_event, theme_display_name)
    cancel_pending_play_modded_music()

    local function play_modded_music_callback()
        audio_mixer_music_manager.frontend:log("Playing modded music for frontend theme " ..theme_display_name)
        audio_mixer_music_manager:trigger_action_event(action_event)
        tm:remove_callback("amfmm_play_modded_music_callback")
    end
    
    -- The duration between music tracks playing for vanilla frontend themes is 1 second so we set the callback interval to 1 second.
    tm:callback(play_modded_music_callback, 1000, "amfmm_play_modded_music_callback")
end

local function stop_modded_music(action_event, theme_display_name)
    audio_mixer_music_manager.frontend:log("Stopping modded music for frontend theme " ..theme_display_name)
    audio_mixer_music_manager:trigger_action_event(action_event)
end

local function play_music(current_theme_display_name)
    local previous_theme_display_name = audio_mixer_music_manager.frontend.saved_previous_theme_display_name
    audio_mixer_music_manager.frontend.saved_previous_theme_display_name = current_theme_display_name

    audio_mixer_music_manager.frontend:log("Frontend theme changed from " ..tostring(previous_theme_display_name) .." to " ..tostring(current_theme_display_name))

    local current_theme_music = audio_mixer_music_manager.frontend:get_music(current_theme_display_name) or get_default_theme_music()
    local previous_theme_music = audio_mixer_music_manager.frontend:get_music(previous_theme_display_name) or get_default_theme_music()
    if current_theme_music == nil or previous_theme_music == nil then
        audio_mixer_music_manager.frontend:log_error("Either the current or previous theme music is nil. Cannot handle theme music.")
        return
    end

    local previous_and_current_theme_music_matches = false
    if current_theme_music.play_action_event and previous_theme_music.play_action_event then
        previous_and_current_theme_music_matches = current_theme_music.play_action_event == previous_theme_music.play_action_event
    end

    if previous_and_current_theme_music_matches then
        audio_mixer_music_manager.frontend:log("Both frontend themes have the same music so the current music can continue to play.")
    else
        cancel_pending_play_modded_music()

        -- Vanilla music plays when the theme is changed so we pause it then stop our music for the previous theme and play it for the current one
        pause_vanilla_music(current_theme_display_name)
        stop_modded_music(previous_theme_music.stop_action_event, previous_theme_display_name)
        play_modded_music(current_theme_music.play_action_event, current_theme_display_name)

        save_theme_in_svr(current_theme_display_name)
    end
end

local function play_music_for_initial_theme(initial_theme_display_name)
    audio_mixer_music_manager.frontend:log("Initial frontend theme " ..initial_theme_display_name .." is visible.")
    local initial_theme_music = audio_mixer_music_manager.frontend:get_music(initial_theme_display_name)
    if initial_theme_music == nil then
        audio_mixer_music_manager.frontend:log_error("Initial theme music is nil. Using default theme music.")
        initial_theme_music = get_default_theme_music()
    end

    if initial_theme_music == nil then
        audio_mixer_music_manager.frontend:log_error("Initial theme music is still nil. Cannot handle theme music.")
        return
    end

    -- Vanilla music plays when the theme is initialised so we pause it then play our music
    pause_vanilla_music(initial_theme_display_name)
    play_modded_music(initial_theme_music.play_action_event, initial_theme_display_name)

    audio_mixer_music_manager.frontend.saved_previous_theme_display_name = initial_theme_display_name
    save_theme_in_svr(initial_theme_display_name)
end

local function on_theme_changed()
    audio_mixer_music_manager.frontend.pending_frontend_theme_display_name = get_theme_display_name()

    if audio_mixer_music_manager.frontend.is_handling_frontend_theme_change then
        return
    end

    audio_mixer_music_manager.frontend.is_handling_frontend_theme_change = true
    while audio_mixer_music_manager.frontend.pending_frontend_theme_display_name do
        local current_theme_display_name = audio_mixer_music_manager.frontend.pending_frontend_theme_display_name
        audio_mixer_music_manager.frontend.pending_frontend_theme_display_name = nil
        play_music(current_theme_display_name)
    end
    audio_mixer_music_manager.frontend.is_handling_frontend_theme_change = false
end

local function listen_for_initial_theme_visibility()
    audio_mixer_campaign_music_manager:log("Setting up listener to listen for the initial theme being visible")
    tm:repeat_callback(
        function()
            -- While the intro movies play the frontend is covered by "cover_until_intro_movies_finish" 
            local intro_movies_cover = find_uicomponent(core:get_ui_root(), "cover_until_intro_movies_finish")
            local is_intro_movies_cover_visible = intro_movies_cover and intro_movies_cover:Visible()
            
            -- After fighting a battle the frontend is covered by the post battle screen 
            local post_battle_screen = find_uicomponent(core:get_ui_root(), "postbattle")
            local is_post_battle_screen_visible = post_battle_screen and post_battle_screen:Visible()

            if not is_intro_movies_cover_visible and not is_post_battle_screen_visible then
                -- Use the saved theme from the svr when the theme_label isn't visible or when returning from battle
                local initial_theme_display_name = get_theme_display_name() or get_saved_theme_from_svr()
                if initial_theme_display_name then
                    tm:remove_callback("amfmm_listen_for_initial_theme_being_visible_callback")
                    core:trigger_event("ScriptEventAmmmInitialThemeIsVisible", initial_theme_display_name)
                end
            end
        end, 
        0.1, 
        "amfmm_listen_for_initial_theme_being_visible_callback"
    );
end

local function add_vanilla_themes()
    for theme_display_name, theme in pairs(vanilla_frontend_theme_music) do
        audio_mixer_music_manager.frontend:add_music(theme_display_name, theme.play_action_event)
    end
end

local function add_listeners()
    tm:remove_callback("amfmm_add_listeners_callback")

    core:add_listener(
        "amfmm_on_theme_changed_listener",
        "ComponentLClickUp",
        function(context) 
            return context.string == "button_next_theme" or context.string == "button_prev_theme" 
        end,
        function()
            -- Give time for the label to update
            tm:callback(on_theme_changed, 10)
        end,
        true
    );
    
    core:add_listener(
        "amfmm_on_initial_theme_becomes_visible",
        "ScriptEventAmmmInitialThemeIsVisible",
        true,
        function(context)
            local  initial_theme_display_name = context.string
            -- A short delay sounds nice
            tm:callback(
                function() 
                    play_music_for_initial_theme(initial_theme_display_name)
                end, 
                500
            )
        end,
        false
    );
    
    listen_for_initial_theme_visibility()
end

-------------------------------------------------------------------------------
--- @section AudioMixerFrontendMusicManager Class
-------------------------------------------------------------------------------

--- @class AudioMixerFrontendMusicManager
--- @field music table<string, Music>
--- @field saved_previous_theme_display_name string
--- @field is_handling_frontend_theme_change boolean
--- @field pending_frontend_theme_display_name string|nil
audio_mixer_frontend_music_manager = {
    music = {},
    saved_previous_theme_display_name = "",
    is_handling_frontend_theme_change = false,
    pending_frontend_theme_display_name = nil
}

--- @description : Constructor to create the audio_mixer_frontend_music_manager object interface.
--- @param audio_mixer_music_manager AudioMixerMusicManager : The AudioMixerMusicManager instance.
function audio_mixer_frontend_music_manager:create(audio_mixer_music_manager)
    local existing_instance = audio_mixer_music_manager.frontend
    if existing_instance then
        audio_mixer_music_manager.frontend = existing_instance
        return
    end

    local new_instance = {}
    set_object_class(new_instance, self)
    audio_mixer_music_manager.frontend = new_instance

    add_vanilla_themes()
    add_listeners()

    self:log("Created audio_mixer_frontend_music_manager")
end

--- @description : Adds frontend music for a given theme.
--- @param theme_display_name string : The display name of the theme.
--- @param play_action_event string : The Action Event for playing modded music.
--- @return boolean : Returns true if added or updated, false if not.
function audio_mixer_frontend_music_manager:add_music(theme_display_name, play_action_event)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        self:log_error("theme_display_name must be a non-empty string.")
        return false
    end

    if type(play_action_event) ~= "string" or play_action_event == "" then
        self:log_error("play_action_event must be a non-empty string.")
        return false
    end

    local existing_theme_music = self.music[theme_display_name]
    if existing_theme_music then
        existing_theme_music:update(play_action_event)
        self:log("Updated music for theme " ..theme_display_name)
        return true
    else
        local new_theme_music = Music:create(play_action_event)
        self.music[theme_display_name] = new_theme_music
        self:log("Added music for theme " ..theme_display_name)
        return true
    end
end

--- @description : Removes the frontend music for a given theme.
--- @param theme_display_name string : The display name of the theme.
--- @return boolean : Returns true if removed, false if not.
function audio_mixer_frontend_music_manager:remove_music(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        self:log_error("theme_display_name must be a non-empty string. Cannot remove.")
        return false
    end

    if self.music[theme_display_name] then
        self.music[theme_display_name] = nil
        self:log("Removed music for theme " ..theme_display_name)
        return true
    else
        self:log_error("Music for theme " ..theme_display_name .." not found. Cannot remove.")
        return false
    end
end

--- @description : Gets the frontend music for a given theme.
--- @param theme_display_name string : The display name of the theme.
--- @return Music|nil : Returns the Music if found, nil if not.
function audio_mixer_frontend_music_manager:get_music(theme_display_name)
    if type(theme_display_name) ~= "string" or theme_display_name == "" then
        self:log_error("theme_display_name must be a non-empty string.")
        return nil
    end
    return self.music[theme_display_name]
end

-------------------------------------------------------------------------------
--- @section Logging
-------------------------------------------------------------------------------

--- @description : Logs a message with the "Frontend" scope prefix.
--- @param text string : The message to log.
function audio_mixer_frontend_music_manager:log(text)
    audio_mixer_music_manager:log(text, "Frontend")
end

--- @description : Logs an error message with the "Frontend" scope prefix.
--- @param text string : The message to log.
function audio_mixer_frontend_music_manager:log_error(text)
    audio_mixer_music_manager:log_error(text, "Frontend")
end