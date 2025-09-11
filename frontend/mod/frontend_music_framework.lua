-- Frontend Framework
-- This script implements the frontend framework of the Audio Mixer Music Framework API. 
-- It allows mod authors to manage modded music for the frontend, campaign, and battle. 
-- An example of how it's used can be found in the frontend_music_framework.lua file.

local previous_theme_display_name

-- The Audio Mixer contains these events remade from the vanilla sounds.
-- This is needed as sometimes if vanilla music is paused and the game later closed, strangely the next time the game is launched 
-- the vanilla music doesn't play until the Global_Music_Play event is triggered again which causes problems as we can't tell if 
-- it's playing or not so to trigger Global_Music_Play if it's already playing would play the music again which could mean 
-- multiple music tracks playing at the same time which we don't want...
local vanilla_music_frontend_themes = {
    {
        theme_display_name = "Total War: Warhammer I",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer I – Blood for the Blood God",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer I – Call of the Beastmen",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer I – The Grim & The Grave",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer I – The King & The Warlord",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer I – Realm of the Wood Elves",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer I – Bretonnia",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer I – Norsca",
        play_action_event = "Play_music_frontend_wh1_theme",
        stop_action_event = "Stop_music_frontend_wh1_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – The Queen & The Crone",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – The Prophet & The Warlock",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – The Hunter & The Beast",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – The Silence & The Fury",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – The Shadow & The Blade",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – The Warden & The Paunch",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – The Twisted & The Twilight",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – Rakarth",
        play_action_event = "Play_music_frontend_wh2_theme",
        stop_action_event = "Stop_music_frontend_wh2_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – Tomb Kings",
        play_action_event = "Play_music_frontend_wh2_tomb_kings_theme",
        stop_action_event = "Stop_music_frontend_wh2_tomb_kings_theme"
    },
    {
        theme_display_name = "Total War: Warhammer II – Vampire Coast",
        play_action_event = "Play_music_frontend_wh2_vampire_coast_theme",
        stop_action_event = "Stop_music_frontend_wh2_vampire_coast_theme"
    },
    {
        theme_display_name = "Total War: Warhammer III",
        play_action_event = "Play_music_frontend_wh3_theme",
        stop_action_event = "Stop_music_frontend_wh3_theme"
    },
    {
        theme_display_name = "Total War: Warhammer III – Champions of Chaos",
        play_action_event = "Play_music_frontend_wh3_theme",
        stop_action_event = "Stop_music_frontend_wh3_theme"
    },
    {
        theme_display_name = "Total War: Warhammer III – Mirror of Madness",
        play_action_event = "Play_music_frontend_wh3_theme",
        stop_action_event = "Stop_music_frontend_wh3_theme"
    },
    {
        theme_display_name = "Total War: Warhammer III – Shadows of Change",
        play_action_event = "Play_music_frontend_wh3_theme",
        stop_action_event = "Stop_music_frontend_wh3_theme"
    },
    {
        theme_display_name = "Total War: Warhammer III – Thrones of Decay",
        play_action_event = "Play_music_frontend_wh3_theme",
        stop_action_event = "Stop_music_frontend_wh3_theme"
    },
    {
        theme_display_name = "Total War: Warhammer III – Omens of Destruction",
        play_action_event = "Play_music_frontend_wh3_theme",
        stop_action_event = "Stop_music_frontend_wh3_theme"
    },
    {
        theme_display_name = "Total War: Warhammer III – Forge of the Chaos Dwarfs",
        play_action_event = "Play_music_frontend_wh3_chaos_dwarfs_theme",
        stop_action_event = "Stop_music_frontend_wh3_chaos_dwarfs_theme"
    }
}

local function pause_vanilla_music(theme_display_name)
    ammf.log("Pausing vanilla music for theme: " ..theme_display_name .." with Action Event: " ..ammf.VANILLA_MUSIC_PAUSE_ACTION_EVENT)
    ammf.trigger_action_event(vanilla_music_pause_action_event)
end

local function stop_modded_music(action_event, theme_display_name)
    ammf.log("Stopping modded music for theme: " ..theme_display_name .." with Action Event: " ..action_event)
    ammf.trigger_action_event(action_event)
end

local function play_modded_music(action_event, theme_display_name)
    local function play_modded_music_callback()
        ammf.log("Playing modded music for theme: " ..theme_display_name .." with Action Event: " ..action_event)
        ammf.trigger_action_event(action_event)
        timer_manager:remove_callback("play_modded_music")
    end

    -- Wait 1 second (the duration for vanilla and modded music to fade out) before playing the music
    timer_manager:callback(function() play_modded_music_callback() end, 1000, "play_modded_music")
end

local function get_current_theme_display_name()
    local theme_label_uic = find_uicomponent(core:get_ui_root(), "main", "theme_button_parent", "theme_label")
    local theme_display_name = theme_label_uic and theme_label_uic:GetStateText()
    return theme_display_name
end

local function save_previous_theme_display_name(current_theme_display_name)
    previous_theme_display_name = current_theme_display_name
end

local function validate_theme(theme)
    if theme == nil then
        ammf.log_error("Theme is null. Using default theme.")
        return frontend_themes["Total War: Warhammer III"]
    else
        return theme
    end
end

function on_theme_changed()
    local current_theme_display_name = get_current_theme_display_name()

    ammf.log("Handling music for theme change from: " ..previous_theme_display_name .." to: " ..current_theme_display_name)

    local current_theme = validate_theme(ammf.get_frontend_theme(current_theme_display_name))
    local previous_theme = validate_theme(ammf.get_frontend_theme(previous_theme_display_name))

    save_previous_theme_display_name(current_theme_display_name)

    local previous_and_current_theme_music_matches = false
    if current_theme and previous_theme and current_theme.play_action_event and previous_theme.play_action_event then
        previous_and_current_theme_music_matches = current_theme.play_action_event == previous_theme.play_action_event
    end

    if not previous_and_current_theme_music_matches then
        pause_vanilla_music(current_theme_display_name)
        stop_modded_music(previous_theme.stop_action_event, previous_theme_display_name)
        play_modded_music(current_theme.play_action_event, current_theme_display_name)
        return
    end
end

function on_theme_initialised()
    -- The whole frontend is always visible but covered by "cover_until_intro_movies_finish" while the intro movies play, so we play music once it's not visible
    local frontend_cover = find_uicomponent(core:get_ui_root(), "cover_until_intro_movies_finish")
    local is_frontend_cover_visible = frontend_cover and frontend_cover:Visible()
    if not is_frontend_cover_visible then
        local initial_theme_display_name = get_current_theme_display_name()

        ammf.log("Handling music for initial theme: " ..initial_theme_display_name)

        save_previous_theme_display_name(initial_theme_display_name)

        local initial_theme = validate_theme(ammf.get_frontend_theme(initial_theme_display_name))

        local initial_theme_has_modded_music = initial_theme ~= nil

        -- The initial theme has modded music
        if initial_theme_has_modded_music then
            pause_vanilla_music(initial_theme_display_name)
            play_modded_music(initial_theme.play_action_event, initial_theme_display_name)
        end

        timer_manager:remove_callback("check_frontend_cover_visibility")
    end  
end

local function register_vanilla_music_frontend_themes()
    for _, theme in ipairs(vanilla_music_frontend_themes) do
        ammf.add_frontend_theme(theme.theme_display_name, theme.play_action_event, theme.stop_action_event)
    end
end

local function init()
    register_vanilla_music_frontend_themes()
    
    timer_manager:repeat_callback(
        function()
            on_theme_initialised()
        end,
        0.1,
        "check_frontend_cover_visibility"
    );

    core:add_listener(
        "on_frontend_theme_changed",
        "ComponentLClickUp",
        function(context) return context.string == "button_next_theme" or context.string == "button_prev_theme" end,
        function()
            on_theme_changed()
        end,
        true
    );
end

if core:is_frontend() then
    core:add_ui_created_callback(init)
end