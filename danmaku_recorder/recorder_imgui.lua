local recorder = require('danmaku_recorder.recorder')
local CT = require('danmaku_recorder.CoordTransfer')
local imgui_exist, imgui = pcall(require, "imgui")
local cjson_util = require("cjson.util")

local recorder_imgui = {}
recorder_imgui.ver = {}
recorder_imgui.ver.major = 1
recorder_imgui.ver.minor = 2
recorder_imgui.ver.patch = 0
recorder_imgui.enable = false

local framerate_list = {1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60}
local scale_list = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0}
local maxframe_list = {50, 75, 100, 125, 150, 175, 200, 225, 250, 275, 300, 400, 500, 600, 700, 800, 900, 1000}

local label = "##Danmaku Recorder"

local slider_flag = 128 --ImGuiSliderFlags_NoInput
local color_flag = 131072 + 32 + 64 --ImGuiColorEditFlags_AlphaPreview | ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoTooltip

local function key_trigger(capturekey)
    local keystate = false
    local prekeystate = false
    return function ()
        prekeystate = keystate
        keystate = lstg.GetKeyState(capturekey)
        return keystate and not prekeystate
    end
end

local function mouse_key_trigger(capturekey)
    local keystate = false
    local prekeystate = false
    return function ()
        prekeystate = keystate
        keystate = lstg.Input.Mouse.GetKeyState(capturekey)
        return keystate and not prekeystate
    end
end

local function recorder_listener(lstatus)
    local status = recorder:get_status()
    local prestatus = recorder:get_status()
    return function ()
        prestatus = status
        status = recorder:get_status()
        return status == lstatus and prestatus ~= lstatus
    end
end

local left_trigger = mouse_key_trigger(lstg.Input.Mouse.Left)
local right_trigger = mouse_key_trigger(lstg.Input.Mouse.Right)

local record_start = recorder_listener("recording")
local record_end = recorder_listener("initialized")

function recorder_imgui:init()
    local config
    local flag1, raw_config = pcall(lstg.LoadTextFile, "danmaku_recorder/config.json")
    if flag1 then
        local flag2, e = pcall(cjson.decode, raw_config)
        if flag2 then
            config = e
        else
            lstg.Log(3, "[danmaku_recorder] 注意解析config.json失败")
        end
    else
        lstg.Log(3, "[danmaku_recorder] 注意读取config.json失败")
    end

    self.framerate_list_pos = 10
    self.scale_list_pos = 4
    self.maxframe_list_pos = 4
    self.encoder_list = recorder:enum_encoders()
    self.current_encoder = recorder:get_current_encoder()
    self.start_record_trigger = {}
    self.end_record_trigger = {}
    if config then
        if config.hotkeys then
            if config.hotkeys.start_record then
                if type(config.hotkeys.start_record) == "table" then
                    for _, v in ipairs(config.hotkeys.start_record) do
                        if KEY[v] then
                            table.insert(self.start_record_trigger, key_trigger(KEY[v]))
                        end
                    end
                elseif type(config.hotkeys.start_record) == "string" then
                    if KEY[config.hotkeys.start_record] then
                        table.insert(self.start_record_trigger, key_trigger(KEY[config.hotkeys.start_record]))
                    end
                end
            end
            if config.hotkeys.end_record then
                if type(config.hotkeys.end_record) == "table" then
                    for _, v in ipairs(config.hotkeys.end_record) do
                        if KEY[v] then
                            table.insert(self.end_record_trigger, key_trigger(KEY[v]))
                        end
                    end
                elseif type(config.hotkeys.end_record) == "string" then
                    if KEY[config.hotkeys.end_record] then
                        table.insert(self.end_record_trigger, key_trigger(KEY[config.hotkeys.end_record]))
                    end
                end
            end
        end
        local loaded = false
        if config.save_config and config.save_config.enable and type(config.save_config.path) == "string" then
            if lstg.FileManager.FileExist(config.save_config.path) then
                local fhandle = io.open(config.save_config.path, "r")
                if fhandle then
                    local success, recorder_ui_config = pcall(cjson.decode, fhandle:read("*a"))
                    if success then
                        if recorder_ui_config.framerate_list_pos and type(recorder_ui_config.framerate_list_pos) == "number" then
                            self.framerate_list_pos = min(max(recorder_ui_config.framerate_list_pos, 1), #framerate_list)
                        end
                        if recorder_ui_config.scale_list_pos and type(recorder_ui_config.scale_list_pos) == "number" then
                            self.scale_list_pos = min(max(recorder_ui_config.scale_list_pos, 1), #scale_list)
                        end
                        if recorder_ui_config.maxframe_list_pos and type(recorder_ui_config.maxframe_list_pos) == "number" then
                            self.maxframe_list_pos = min(max(recorder_ui_config.maxframe_list_pos, 1), #maxframe_list)
                        end
                        if recorder_ui_config.encoder and type(recorder_ui_config.encoder) == "number" then
                            self.current_encoder = min(max(recorder_ui_config.encoder, 1), #self.encoder_list)
                        end
                        loaded = true
                    else
                        lstg.Log(3, "[danmaku_recorder] 解析配置失败")
                    end
                    fhandle:close()
                else
                    lstg.Log(3, "[danmaku_recorder] 读取配置失败")
                end
            else
                lstg.Log(2, "[danmaku_recorder] 配置文件不存在")
                local path = string.gsub(config.save_config.path, "\\", "/")
                local dir = string.match(path, "(.+)/[^/]*%.%w+$") or "./"
                if not lstg.FileManager.DirectoryExist(dir) then
                    lstg.Log(2, "[danmaku_recorder] 尝试创建目录")
                    lstg.FileManager.CreateDirectory(dir)
                end
            end
            self.save_config = true
            self.save_config_path = config.save_config.path
        end
        if config.default_config and not loaded then
            if config.default_config.framerate then
                for i, v in ipairs(framerate_list) do
                    if v == config.default_config.framerate then self.framerate_list_pos = i break end
                end
            end
            if config.default_config.scale then
                for i, v in ipairs(scale_list) do
                    if v == config.default_config.scale then self.scale_list_pos = i break end
                end
            end
            if config.default_config.maxframe then
                for i, v in ipairs(maxframe_list) do
                    if v == config.default_config.maxframe then self.maxframe_list_pos = i break end
                end
            end
        end
        if config.auto_enable then
            self.enable = true
        end
    end
    self.highlight_color = {255 / 255, 0 / 255, 255 / 255, 100 / 255} --rgba
    self.set_capture_status = "null"
    self.point1x, self.point1y, self.point2x, self.point2y = 0, 0, 0, 0
    self.show_capture = false

    imgui.backend.CacheGlyphFromString("开始停止录像")
    imgui.backend.CacheGlyphFromString("重新加载编码器配置")
    imgui.backend.CacheGlyphFromString("录像帧率")
    imgui.backend.CacheGlyphFromString("缩放比例")
    imgui.backend.CacheGlyphFromString("录制帧数上限")
    imgui.backend.CacheGlyphFromString("高亮颜色")
    imgui.backend.CacheGlyphFromString("设置录制区域为")
    imgui.backend.CacheGlyphFromString("显示录制区域")
    imgui.backend.CacheGlyphFromString("使用鼠标设置录制区域")
    imgui.backend.CacheGlyphFromString("按下左键开始完成选择")
    imgui.backend.CacheGlyphFromString("右键或按按钮取消")
    imgui.backend.CacheGlyphFromString("未初始化无法使用")
    imgui.backend.CacheGlyphFromString("保存成功失败帧数文件大小")
    imgui.backend.CacheGlyphFromString("在文件夹中显示")
end

function recorder_imgui:getWindowName()
    return "Danmaku Recorder"
end

function recorder_imgui:getMenuItemName()
    return "Danmaku Recorder Plugin"
end

function recorder_imgui:getMenuGroupName()
    return "Tool"
end

function recorder_imgui:getEnable()
    return self.enable
end

function recorder_imgui:setEnable(v)
    self.enable = v
end

function recorder_imgui:cancel_cursor_capture()
    self.set_capture_status = "null"
    self.point1x, self.point1y, self.point2x, self.point2y = 0, 0, 0, 0
    recorder:set_capture_area(self.fallback_capture_area.l, self.fallback_capture_area.t, self.fallback_capture_area.r, self.fallback_capture_area.b)
end

local function start_record(self)
    recorder:set_framerate(framerate_list[self.framerate_list_pos])
    recorder:set_scale(scale_list[self.scale_list_pos])
    recorder:set_max_frame(maxframe_list[self.maxframe_list_pos])
    recorder:set_encoder(self.current_encoder)
    recorder:start_record()
end

local function end_record(self)
    recorder:end_record()
end

function recorder_imgui:update()
    if self.enable then
        local start_keyflag = false
        local end_keyflag = false
        for _, v in ipairs(self.start_record_trigger) do
            if v() then
                start_keyflag = true
                break
            end
        end
        for _, v in ipairs(self.end_record_trigger) do
            if v() then
                end_keyflag = true
                break
            end
        end
        if recorder:get_status() == "initialized" then
            if start_keyflag then
                start_record(self)
            end
        elseif recorder:get_status() == "recording" then
            if end_keyflag then
                end_record(self)
            end
        end
    end
    if record_start() then
        self.last_record_info = nil
    end
    if record_end() then
        local t_last_record_info = recorder:get_last_record_info()
        self.last_record_info = {}
        if t_last_record_info.success then
            self.last_record_info.success = true
            local size = t_last_record_info.size
            local unit = ""
            local unit_list = {"B", "KB", "MB"}
            local p = 1
            while p <= 2 do
                if size <= 1024 then
                    break
                else
                    p = p + 1
                    size = size / 1024
                end
            end
            unit = unit_list[p]
            self.last_record_info.size = size
            self.last_record_info.unit = unit
            self.last_record_info.path = t_last_record_info.path
            self.last_record_info.frame = t_last_record_info.frame
        else
            self.last_record_info.success = false
        end
    end
    if self.set_capture_status == "wait" then
        if left_trigger() then
            self.point1x, self.point1y = CT.CoordTransfer("window", "ui", lstg.Input.Mouse.GetPosition())
            self.set_capture_status = "capturing"
        end
        if right_trigger() then
            self:cancel_cursor_capture()
        end
    end
    if self.set_capture_status == "capturing" then
        self.point2x, self.point2y = CT.CoordTransfer("window", "ui", lstg.Input.Mouse.GetPosition())
        local l = min(self.point1x, self.point2x)
        local r = max(self.point1x, self.point2x)
        local b = min(self.point1y, self.point2y)
        local t = max(self.point1y, self.point2y)
        recorder:set_capture_area(l, t, r, b)
        if left_trigger() then
            self.set_capture_status = "null"
        end
        if right_trigger() then
            self:cancel_cursor_capture()
        end
    end
end

function recorder_imgui:render()
    if self.show_capture or self.set_capture_status == "capturing" then
        SetViewMode("ui")
        local l_color = lstg.Color(self.highlight_color[4] * 255, self.highlight_color[1] * 255, self.highlight_color[2] * 255, self.highlight_color[3] * 255)
        lstg.SetImageState("white", "mul+add", l_color)
        local capture_area = recorder:get_capture_area()
        lstg.Render4V("white",
                capture_area.l, capture_area.b, 0.5,
                capture_area.l, capture_area.t, 0.5,
                capture_area.r, capture_area.t, 0.5,
                capture_area.r, capture_area.b, 0.5
            )
        SetViewMode("world") -- 恢复
    end
end

function recorder_imgui:layout()
    if imgui_exist then
        if recorder:get_status() == "initialized" then
            if imgui.ImGui.Button("开始录像" ..label) then
                start_record(self)
            end
        elseif recorder:get_status() == "recording" then
            if imgui.ImGui.Button("停止录像" ..label) then
                end_record(self)
            end
            imgui.ImGui.SameLine()
            imgui.ImGui.Text(string.format("%d / %d", recorder:get_recorded_frame_count(), recorder:get_max_frame()))
        else
            imgui.ImGui.TextColored(imgui.ImVec4(1, 0, 0, 1), "未初始化无法使用")
        end

        if self.last_record_info then
            if self.last_record_info.success then
                imgui.ImGui.TextColored(imgui.ImVec4(0, 1, 0, 1), "GIF保存成功")
                imgui.ImGui.TextColored(imgui.ImVec4(0, 1, 0, 1), string.format("帧数 %d 文件大小 %.2f %s", self.last_record_info.frame, self.last_record_info.size, self.last_record_info.unit))
                if imgui.ImGui.Button("在文件夹中显示" .. label) then
                    os.execute("explorer /select, " .. '"' .. self.last_record_info.path .. '"')
                end
            else
                imgui.ImGui.TextColored(imgui.ImVec4(1, 0, 0, 1), "GIF保存失败")
            end
        end
        
        if recorder:get_status() ~= "initialized" then
            imgui.ImGui.BeginDisabled()
        end
        local changed = false
        local ret
        ret, self.framerate_list_pos = imgui.ImGui.SliderInt("录像帧率" .. label, self.framerate_list_pos, 1, #framerate_list, tostring(framerate_list[self.framerate_list_pos]), slider_flag)
        changed = ret or changed
        ret, self.scale_list_pos = imgui.ImGui.SliderInt("缩放比例" .. label, self.scale_list_pos, 1, #scale_list, tostring(scale_list[self.scale_list_pos]), slider_flag)
        changed = ret or changed
        ret, self.maxframe_list_pos = imgui.ImGui.SliderInt("录制帧数上限" .. label, self.maxframe_list_pos, 1, #maxframe_list, tostring(maxframe_list[self.maxframe_list_pos]), slider_flag)
        changed = ret or changed
        ret, self.current_encoder = imgui.ImGui.Combo("编码器" .. label, self.current_encoder, self.encoder_list)
        changed = ret or changed
        if imgui.ImGui.Button("重新加载编码器配置" .. label) then
            recorder:load_config()
            self.encoder_list = recorder:enum_encoders()
            self.current_encoder = recorder:get_current_encoder()
        end

        imgui.ImGui.Text("设置录制区域为")
        imgui.ImGui.SameLine()
        local set_capture_area_ui_flag = imgui.ImGui.Button("UI" .. label)
        imgui.ImGui.SameLine()
        local set_capture_area_world_flag = imgui.ImGui.Button("World" .. label)
        if set_capture_area_ui_flag then recorder:set_capture_area_ui() end
        if set_capture_area_world_flag then recorder:set_capture_area_world() end

        if self.set_capture_status == "null" then
            local ret = imgui.ImGui.Button("使用鼠标设置录制区域" ..label)
            if ret then
                self.fallback_capture_area = recorder:get_capture_area()
                self.set_capture_status = "wait"
            end
        elseif self.set_capture_status == "wait" then
            local ret = imgui.ImGui.Button("按下左键开始选择 右键或按按钮取消" ..label)
            if ret then
                self:cancel_cursor_capture()
            end
        elseif self.set_capture_status == "capturing" then
            imgui.ImGui.BeginDisabled()
            imgui.ImGui.Button("按下左键完成选择 右键取消" ..label)
            imgui.ImGui.EndDisabled()
        end
        if recorder:get_status() ~= "initialized" then
            imgui.ImGui.EndDisabled()
        end
        _, self.show_capture = imgui.ImGui.Checkbox("显示录制区域", self.show_capture)
        _, self.highlight_color = imgui.ImGui.ColorEdit4("高亮颜色" .. label, self.highlight_color, color_flag)
        imgui.ImGui.Text(string.format("Danmaku Recorder UI ver %d.%d.%d", recorder_imgui.ver.major, recorder_imgui.ver.minor, recorder_imgui.ver.patch))
        imgui.ImGui.Text(string.format("Danmaku Recorder Core ver %d.%d.%d", recorder.ver.major, recorder.ver.minor, recorder.ver.patch))

        if changed and self.save_config then
            local cfg = {
                framerate_list_pos = self.framerate_list_pos,
                scale_list_pos = self.scale_list_pos,
                maxframe_list_pos = self.maxframe_list_pos,
                encoder = self.current_encoder
            }
            local success, encoded_cfg = pcall(cjson.encode, cfg)
            if success then
                local formated_cfg = cjson_util.format_json(encoded_cfg)
                local fhandle = io.open(self.save_config_path, "w")
                if fhandle then
                    fhandle:write(formated_cfg)
                    fhandle:close()
                else
                    lstg.Log(3, "[danmaku_recorder] 写入配置失败")
                end
            else
                lstg.Log(3, "[danmaku_recorder] 编码配置json失败")
            end
        end
    end
end

return recorder_imgui