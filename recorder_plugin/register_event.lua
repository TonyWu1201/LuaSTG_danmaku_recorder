--config
local config = {
    use_imgui = true,
    use_native_ui = false,
    ffmpeg_path = nil --如需指定ffmpeg路径请手动修改此项
}

local event_dispatcher = lstg.globalEventDispatcher
local debugger = require('lib.Ldebug')

local recorder = require("danmaku_recorder.recorder")
recorder:init(config.ffmpeg_path)

local recorder_ui
if config.use_native_ui then
    recorder_ui = require("danmaku_recorder.recorder_ui")
    recorder_ui:init()
end

local recorder_imgui
if config.use_imgui then
    recorder_imgui = require("danmaku_recorder.recorder_imgui")
    recorder_imgui:init()
    debugger.addView("Danmaku Recorder Plugin", recorder_imgui)
end

if event_dispatcher then
    event_dispatcher:RegisterEvent("GameState.BeforeStageRender", "recorder_start_capture", 0, function ()
        recorder:start_capture()
    end)
    event_dispatcher:RegisterEvent("GameState.AfterObjRender", "recorder_end_capture", 0, function ()
        recorder:end_capture()
        SetViewMode("ui")
        recorder:draw_capture_content()
    end)

    if config.use_native_ui then
        event_dispatcher:RegisterEvent("GameState.BeforeDoFrame", "recorder_ui_frame", 1, function ()
            recorder_ui:frame()
        end)
        event_dispatcher:RegisterEvent("GameState.AfterRender", "recorder_ui_render", -1, function ()
            recorder_ui:render()
        end)
    end

    if config.use_imgui then
        event_dispatcher:RegisterEvent("GameState.AfterRender", "recorder_imgui_render", -2, function ()
            SetViewMode("ui")
            recorder_imgui:render()
        end)
    end
end