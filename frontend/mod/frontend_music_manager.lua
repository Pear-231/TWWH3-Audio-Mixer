----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

-- Frontend Music Manager:

-- The Frontend Music Manager replicates the vanilla system of music being tied to themes.
-- It is replicated rather than directly modded because you cannot mod new Wwise Switches as they're hardcoded.
-- The system works by detecting what theme is currently visible and playing / stopping the corresponding Action Event.
-- The Action Events created for vanilla music can be found below.

-- The recommended settings for a frontend music Action Event to replicate the vanilla system are:
-- Two audio files: the first one the theme music, the second one a silent track.
-- Playlist Type = Sequence 
-- Playlist End Behaviour = Restart
-- Playlist Mode = Continuous
-- Always Reset Playlist = True
-- Looping Type = Infinite Looping
-- Transition Type = Delay
-- Transition Duration = 1

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

local saved_previous_theme_display_name = ""
local is_handling_frontend_theme_change = false
local pending_frontend_theme_display_name = nil

-- The Audio Mixer contains these Action Events remade from the vanilla sounds. This is needed as sometimes if vanilla music 
-- is paused and the game later closed, strangely the next time the game is launched the vanilla music doesn't play 
-- until the Global_Music_Play event is triggered again. This is problematic as we can't tell if the vanilla music is playing 
-- or not and triggering Global_Music_Play if it's already playing would play the music again which could mean multiple 
-- music tracks playing at the same time (which we don't want!). So to avoid this problem we just remake the whole thing as 
-- individual Action Events so we have full control of what we want to play and when.
local vanilla_frontend_theme_music = {
    -- default_theme is used as a backup where there isn't a theme assigned or all others are overwritten
    ["default_theme"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: Warhammer I"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer I – Blood for the Blood God"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer I – Call of the Beastmen"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer I – The Grim & The Grave"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer I – The King & The Warlord"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer I – Realm of the Wood Elves"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer I – Bretonnia"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer I – Norsca"] = { play_action_event = "Play_music_frontend_vanilla_wh1_theme" },
    ["Total War: Warhammer II"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – Tomb Kings"] = { play_action_event = "Play_music_frontend_vanilla_tomb_kings_theme" },
    ["Total War: Warhammer II – The Queen & The Crone"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – Vampire Coast"] = { play_action_event = "Play_music_frontend_vanilla_vampire_coast_theme" },
    ["Total War: Warhammer II – The Prophet & The Warlock"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – The Hunter & The Beast"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – The Shadow & The Blade"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – The Warden & The Paunch"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – The Twisted & The Twilight"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – Rakarth"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer II – The Silence & The Fury"] = { play_action_event = "Play_music_frontend_vanilla_wh2_theme" },
    ["Total War: Warhammer III"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: Warhammer III – Champions of Chaos"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: Warhammer III – Mirror of Madness"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: Warhammer III – Forge of the Chaos Dwarfs"] = { play_action_event = "Play_music_frontend_vanilla_chaos_dwarfs_theme" },
    ["Total War: Warhammer III – Shadows of Change"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: Warhammer III – Thrones of Decay"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" },
    ["Total War: Warhammer III – Omens of Destruction"] = { play_action_event = "Play_music_frontend_vanilla_wh3_theme" }
}

local function get_theme_display_name()
    local theme_label_uic = find_uicomponent(core:get_ui_root(), "main", "theme_button_parent", "theme_label")
    local theme_display_name = theme_label_uic and theme_label_uic:GetStateText()
    return theme_display_name
end

local function get_default_theme()
    return vanilla_frontend_theme_music["default_theme"]
end

local function save_previous_theme_display_name(current_theme_display_name)
    saved_previous_theme_display_name = current_theme_display_name
end

local function cancel_pending_play_modded_music()
    timer_manager:remove_callback("ammf_play_frontend_modded_music_callback")
end

local function play_modded_music(action_event, theme_display_name)
    cancel_pending_play_modded_music()

    local function play_modded_music_callback()
        ammm.log("Playing modded music for frontend theme " ..theme_display_name .." with Action Event " ..action_event)
        ammm.trigger_action_event(action_event)
        timer_manager:remove_callback("ammf_play_frontend_modded_music_callback")
    end

    -- The duration between music tracks playing for vanilla frontend themes is 1 second so we set the callback to 1 second.
    timer_manager:callback(
        function() 
            play_modded_music_callback() 
        end, 
        1000, 
        "ammf_play_frontend_modded_music_callback"
    )
end

local function pause_vanilla_music(theme_display_name)
    ammm.log("Pausing vanilla music for frontend theme " ..theme_display_name)
    ammm.pause_vanilla_music()
end

local function stop_modded_music(action_event, theme_display_name)
    ammm.log("Stopping modded music for frontend theme " ..theme_display_name .." with Action Event " ..action_event)
    ammm.trigger_action_event(action_event)
end

local function handle_theme_change(display_name)
    local current_theme_display_name = display_name
    local previous_theme_display_name = saved_previous_theme_display_name
    save_previous_theme_display_name(current_theme_display_name)

    ammm.log("Frontend theme changed from " ..tostring(previous_theme_display_name) .." to " ..tostring(current_theme_display_name))

    local current_theme = ammm.get_frontend_music(current_theme_display_name) or get_default_theme()
    local previous_theme = ammm.get_frontend_music(previous_theme_display_name) or get_default_theme()

    local previous_and_current_theme_music_matches = false
    if current_theme.play_action_event and previous_theme.play_action_event then
        previous_and_current_theme_music_matches = current_theme.play_action_event == previous_theme.play_action_event
    end

    if previous_and_current_theme_music_matches then
        ammm.log("Both frontend themes have the same music so the current music can continue to play.")
    else
        cancel_pending_play_modded_music()

        -- Vanilla music plays when the theme is changed so we pause it
        pause_vanilla_music(current_theme_display_name)

        stop_modded_music(previous_theme.stop_action_event, previous_theme_display_name)
        play_modded_music(current_theme.play_action_event, current_theme_display_name)
    end
end

local function on_theme_changed()
    timer_manager:callback(
        function()
            pending_frontend_theme_display_name = get_theme_display_name()

            if is_handling_frontend_theme_change then
                return
            end

            is_handling_frontend_theme_change = true
            while pending_frontend_theme_display_name do
                local next_theme = pending_frontend_theme_display_name
                pending_frontend_theme_display_name = nil
                handle_theme_change(next_theme)
            end
            is_handling_frontend_theme_change = false
        end, 
        10, 
        "ammf_on_theme_changed_debounce"
    )
end

local function handle_initial_theme()
    timer_manager:remove_callback("ammm_on_theme_initialised_callback")

    local initial_theme_display_name = get_theme_display_name()
    ammm.log("Intro movies have finished. Initial frontend theme " ..initial_theme_display_name .." is now visible.")

    local initial_theme = ammm.get_frontend_music(initial_theme_display_name)
    if initial_theme == nil then
        initial_theme = get_default_theme()
    end

    -- Vanilla music plays when the theme is initialised so we pause it
    pause_vanilla_music(initial_theme_display_name)

    play_modded_music(initial_theme.play_action_event, initial_theme_display_name)

    save_previous_theme_display_name(initial_theme_display_name)  
end

local function on_theme_initialised()
    -- The whole frontend is always visible but covered by "cover_until_intro_movies_finish" 
    -- while the intro movies play, so we play music once it's no longer visible.
    local frontend_cover = find_uicomponent(core:get_ui_root(), "cover_until_intro_movies_finish")
    local is_frontend_cover_visible = frontend_cover and frontend_cover:Visible()
    if not is_frontend_cover_visible then
        handle_initial_theme()
    end
end

local function log_frontend_music()
    ammm.log("Frontend Music:")
    ammm.log(table.tostring(ammm.frontend_music, false, -1))
end

local function add_vanilla_themes()
    for theme_display_name, theme in pairs(vanilla_frontend_theme_music) do
        -- Only add vanilla themes if they don't already exist to prevent overwriting themes set by mods
        local existing_theme = ammm.get_frontend_music(theme_display_name)
        if existing_theme == nil then
            ammm.add_frontend_music(theme_display_name, theme.play_action_event)
        end
    end
end

local function initialise_frontend_music_manager()
    timer_manager:remove_callback("ammf_initialise_frontend_music_manager_callback")

    add_vanilla_themes()

    log_frontend_music()

    timer_manager:repeat_callback(
        function()
            on_theme_initialised()
        end,
        0.1,
        "ammm_on_theme_initialised_callback"
    );

    core:add_listener(
        "on_frontend_theme_changed_listener",
        "ComponentLClickUp",
        function(context) 
            return context.string == "button_next_theme" or context.string == "button_prev_theme" 
        end,
        function()
            on_theme_changed()
        end,
        true
    );
end

if core:is_frontend() then
    -- Wait for mods to add frontend music
    core:add_ui_created_callback(
        function() 
            initialise_frontend_music_manager() 
        end, 
        1000, 
        "ammf_initialise_frontend_music_manager_callback"
    )
end