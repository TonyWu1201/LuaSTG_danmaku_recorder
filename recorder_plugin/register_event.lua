local event_dispatcher = lstg.globalEventDispatcher

local recorder = require("danmaku_recorder.recorder")
recorder:init()
local recorder_ui = require("danmaku_recorder.recorder_ui")
recorder_ui:init()

if event_dispatcher then
    event_dispatcher:RegisterEvent("GameState.BeforeStageRender", "recorder_start_capture", 0, function ()
        recorder:start_capture()
    end)
    event_dispatcher:RegisterEvent("GameState.AfterObjRender", "recorder_end_capture", 0, function ()
        recorder:end_capture()
        SetViewMode("ui")
        recorder:draw_capture_content()
    end)
    event_dispatcher:RegisterEvent("GameState.BeforeDoFrame", "recorder_ui_frame", 1, function ()
        recorder_ui:frame()
    end)
    event_dispatcher:RegisterEvent("GameState.AfterRender", "recorder_ui_render", -1, function ()
        recorder_ui:render()
    end)
else
    lstg.Log(3, "[danmaku recorder]注意：如果你在log中看到了这段文字，说明插件并没有成功注册事件，请检查LuaSTG版本。")
end