local function init()
    local vanilla_music_pause_action_event = "Global_Music_Pause"
    common.trigger_soundevent(vanilla_music_pause_action_event)
    common.trigger_soundevent("Play_music_campaign_test")
end

if core:is_campaign() then
    cm:add_first_tick_callback_sp_each(init)
end