local function init()
    ammf.trigger_action_event(ammf.VANILLA_MUSIC_PAUSE_ACTION_EVENT)
    ammf.trigger_action_event("Play_music_campaign_test")
end

if core:is_campaign() then
    init()
end