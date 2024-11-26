local recorder = require('danmaku_recorder.recorder')
local CT = require('danmaku_recorder.CoordTransfer')

local recorder_ui = {}
recorder_ui.ver = {}
recorder_ui.ver.major = 1
recorder_ui.ver.minor = 0
recorder_ui.ver.patch = 1

recorder_ui.init = function (self)
    self.func = {
        {text = "[Q]关闭菜单", capture_key = KEY.Q, func = function (_self, ui_obj)
            if ui_obj.mouse_capture then
                _self.flag = "unselectable"
            end
            _self.flag = "selectable"
        end},
        {text = "[W]开始/结束录制", capture_key = KEY.W, func = function (_self, ui_obj)
            if ui_obj.mouse_capture then
                _self.flag = "unselectable"
            else
                if recorder:get_status() == "initialized" then
                    _self.flag = "selectable"
                    if ui_obj:key_press(_self.capture_key) then
                        recorder:set_interval(ui_obj.interval_list[ui_obj.interval_list_pos])
                        recorder:set_scale(ui_obj.scale_list[ui_obj.scale_list_pos])
                        recorder:set_max_frame(ui_obj.maxframe_list[ui_obj.maxframe_list_pos])
                        recorder:start_record()
                    end
                elseif recorder:get_status() == "recording" then
                    _self.flag = "selected"
                    if ui_obj:key_press(_self.capture_key) then
                        _self.flag = "selected"
                        recorder:end_record()
                    end
                else
                    _self.flag = "unselectable"
                end
            end
        end},
        {text = "[E]调节采样FPS", capture_key = KEY.E, func = function (_self, ui_obj)
            if recorder:get_status() == "recording" then
                _self.flag = "unselectable"
            else
                if ui_obj:key_press(_self.capture_key) then
                    ui_obj.interval_list_pos = ui_obj.interval_list_pos % #ui_obj.interval_list + 1
                    recorder:set_interval(ui_obj.interval_list[ui_obj.interval_list_pos])
                end
                if ui_obj:key_down(_self.capture_key) then
                    _self.flag = "selected"
                else
                    _self.flag = "selectable"
                end
            end
            
        end},
        {text = "[T]调节缩放比例", capture_key = KEY.T, func = function (_self, ui_obj)
            if recorder:get_status() == "recording" then
                _self.flag = "unselectable"
            else
                if ui_obj:key_press(_self.capture_key) then
                    ui_obj.scale_list_pos = ui_obj.scale_list_pos % #ui_obj.scale_list + 1
                    recorder:set_scale(ui_obj.scale_list[ui_obj.scale_list_pos])
                end
                if ui_obj:key_down(_self.capture_key) then
                    _self.flag = "selected"
                else
                    _self.flag = "selectable"
                end
            end
        end},
        {text = "[Y]设置最大录制帧数", capture_key = KEY.Y, func = function (_self, ui_obj)
            if recorder:get_status() == "recording" then
                _self.flag = "unselectable"
            else
                if ui_obj:key_press(_self.capture_key) then
                    ui_obj.maxframe_list_pos = ui_obj.maxframe_list_pos % #ui_obj.maxframe_list + 1
                    recorder:set_max_frame(ui_obj.maxframe_list[ui_obj.maxframe_list_pos])
                end
                if ui_obj:key_down(_self.capture_key) then
                    _self.flag = "selected"
                else
                    _self.flag = "selectable"
                end
            end
        end},
        {text = "[U]设置录制区域为world", capture_key = KEY.U, func = function (_self, ui_obj)
            if recorder:get_status() == "recording" or ui_obj.mouse_capture then
                _self.flag = "unselectable"
            else
                if ui_obj:key_press(_self.capture_key) then
                    recorder:set_capture_area_world()
                end
                if ui_obj:key_down(_self.capture_key) then
                    _self.flag = "selected"
                else
                    _self.flag = "selectable"
                end
            end
        end},
        {text = "[I]设置录制区域为ui", capture_key = KEY.I, func = function (_self, ui_obj)
            if recorder:get_status() == "recording" or ui_obj.mouse_capture then
                _self.flag = "unselectable"
            else
                if ui_obj:key_press(_self.capture_key) then
                    recorder:set_capture_area_ui()
                end
                if ui_obj:key_down(_self.capture_key) then
                    _self.flag = "selected"
                else
                    _self.flag = "selectable"
                end
            end
        end},
        {text = "[O]使用鼠标设置录制区域", capture_key = KEY.O, func = function (_self, ui_obj)
            if recorder:get_status() == "recording" then
                _self.flag = "unselectable"
            else
                if _self.capture_flag == nil then
                    _self.capture_flag = false
                    _self.capture_status = 0 -- 0 等待按下 1 等待放开
                    _self.point1x, _self.point1y, _self.point2x, _self.point2y = 0, 0, 0, 0
                end
                if ui_obj:key_press(_self.capture_key) then
                    if _self.capture_flag == false then
                        _self.capture_flag = true
                        ui_obj.mouse_capture = true
                        _self.fallback = recorder:get_capture_area()
                        lstg.SetSplash(true)
                    else
                        _self.capture_flag = false
                        ui_obj.mouse_capture = nil
                        _self.capture_status = 0
                        _self.point1x, _self.point1y, _self.point2x, _self.point2y = 0, 0, 0, 0
                        recorder:set_capture_area(_self.fallback.l, _self.fallback.t, _self.fallback.r, _self.fallback.b)
                        recorder:set_draw_capture_area(false)
                        ui_obj.draw_capture_area = false
                        lstg.SetSplash(false)
                        _self.fallback = nil
                    end
                end
                if _self.capture_flag then
                    if _self.capture_status == 0 then
                        if ui_obj:mouse_press() then
                            _self.point1x, _self.point1y = CT.CoordTransfer("window", "ui", lstg.Input.Mouse.GetPosition())
                            _self.capture_status = 1
                            recorder:set_draw_capture_area(true)
                            ui_obj.draw_capture_area = true
                        end
                    end
                    if _self.capture_status == 1 then
                        _self.point2x, _self.point2y = CT.CoordTransfer("window", "ui", lstg.Input.Mouse.GetPosition())
                        local l = min(_self.point1x, _self.point2x)
                        local r = max(_self.point1x, _self.point2x)
                        local b = min(_self.point1y, _self.point2y)
                        local t = max(_self.point1y, _self.point2y)
                        recorder:set_capture_area(l, t, r, b)
                        if ui_obj:mouse_release() then
                            _self.capture_flag = false
                            ui_obj.mouse_capture = nil
                            _self.capture_status = 0
                            _self.point1x, _self.point1y, _self.point2x, _self.point2y = 0, 0, 0, 0
                            recorder:set_draw_capture_area(false)
                            ui_obj.draw_capture_area = false
                            lstg.SetSplash(false)
                        end
                    end
                end
                if _self.capture_flag then
                    _self.flag = "selected"
                else
                    _self.flag = "selectable"
                end
            end
        end},
        {text = "[P]显示录制区域", capture_key = KEY.P, func = function (_self, ui_obj)
            if ui_obj:key_down(_self.capture_key) then
                _self.flag = "selected"
                recorder:set_draw_capture_area(true)
            else
                _self.flag = "selectable"
                recorder:set_draw_capture_area(false or ui_obj.draw_capture_area)
            end
        end},
    }
    self.activate = false
    self.keystates = {}
    self.pre_keystates = {}
    self.mouse_left_state = false
    self.mouse_left_prestate = false
    self.pre_recorder_status = ""
    self.recorder_status = ""
    self.last_record_info = nil
    self.interval_list = {1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60}
    self.interval_list_pos = 3
    self.scale_list = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0}
    self.scale_list_pos = 4
    self.maxframe_list = {50, 75, 100, 125, 150, 175, 200, 225, 250, 275, 300, 400, 500, 600, 700, 800, 900, 1000}
    self.maxframe_list_pos = 4
    self.draw_capture_area = false
    self.alpha = 1
    LoadTTF('recorder_ui_font', 'danmaku_recorder/recorder_ui_font.otf', 20)
end

recorder_ui.key_press = function (self, keycode)
    return (not self.pre_keystates[keycode]) and (self.keystates[keycode])
end

recorder_ui.key_down = function (self, keycode)
    return (self.keystates[keycode])
end

recorder_ui.mouse_press = function (self)
    return (not self.mouse_left_prestate) and (self.mouse_left_state)
end

recorder_ui.mouse_release = function (self)
    return (self.mouse_left_prestate) and (not self.mouse_left_state)
end

recorder_ui.frame = function (self)
    self.pre_recorder_status = self.recorder_status
    self.recorder_status = recorder:get_status()
    self.mouse_left_prestate = self.mouse_left_state
    self.mouse_left_state = lstg.Input.Mouse.GetKeyState(lstg.Input.Mouse.Left)
    for i, v in pairs(self.keystates) do
        self.pre_keystates[i] = v
    end
    for _, v in ipairs(self.func) do
        if v.capture_key then
            self.keystates[v.capture_key] = GetKeyState(v.capture_key)
        end
    end
    if self:key_press(KEY.Q) and not self.mouse_capture then
        self.activate = not self.activate
        recorder:set_draw_capture_area(false)
    end
    if self.recorder_status ~= "uninitialized" and self.activate then
        for _, v in ipairs(self.func) do
            if v.func then
                v.func(v, self)
            end
        end
        if self.pre_recorder_status == "initialized" and self.recorder_status == "recording" then
            self.last_record_info = nil
        end
        if self.pre_recorder_status == "recording" and self.recorder_status == "initialized" then
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
    else
        for _, v in ipairs(self.func) do
            v.flag = "unselectable"
        end
    end
    if self.activate then
        if IsValid(player) and ext.pause_menu:IsKilled() then
            local top = 200 + 40
            if not self.activate then
                top = 50 + 40
            end
            local bottom = 10 - 40
            local left = 400 - 40
            local right = 620 + 40
            local px, py = WorldToUI(player.x, player.y)
            if left <= px and px <= right and bottom <= py and py <= top then
                self.alpha = max(self.alpha - 0.15, 0.25)
            else
                self.alpha = min(self.alpha + 0.1, 1)
            end
        else
            self.alpha = min(self.alpha + 0.1, 1)
        end
    else
        self.alpha = 0.25
    end
end

recorder_ui.render = function (self)
    SetViewMode 'ui'
    local top = 200
    if not self.activate then
        top = 50
    end
    local bottom = 10
    local left = 400
    local right = 620
    local r_color

    SetImageState('white', '', Color(180 * self.alpha, 20, 20, 20))
    RenderRect('white', left, right, top, bottom)
    local font_tp = top
    r_color = Color(220 * self.alpha, 255, 255, 255)
    RenderTTF('recorder_ui_font', string.format("Danmaku Recorder UI ver %d.%d.%d", self.ver.major, self.ver.minor, self.ver.patch), left + 5, right - 5, font_tp - 12, font_tp, r_color, "left", "top")
    font_tp = font_tp - 15
    if self.activate then
        if self.recorder_status == "uninitialized" then
            r_color = Color(220 * self.alpha, 255, 0, 0)
            RenderTTF('recorder_ui_font', "未初始化无法使用", left + 5, right - 5, font_tp - 12, font_tp, r_color, "left", "top")
            font_tp = font_tp - 15
        end
        for _, v in pairs(self.func) do
            if v.flag then
                if v.flag == "selectable" then
                    r_color = Color(200 * self.alpha, 255, 255, 255)
                elseif v.flag == "selected" then
                    r_color = Color(200 * self.alpha, 200, 0, 200)
                else
                    r_color = Color(200 * self.alpha, 100, 100, 100)
                end
            else
                r_color = Color(200 * self.alpha, 100, 100, 100)
            end
            RenderTTF('recorder_ui_font', v.text, left + 5, right - 5, font_tp - 12, font_tp, r_color, "left", "top")
            font_tp = font_tp - 12
        end
        r_color = Color(200 * self.alpha, 255, 255, 255)
        font_tp = font_tp - 6
        RenderTTF('recorder_ui_font', string.format("当前FPS %2d 放缩比%.1f 最大录制帧数 %4d", 60 / self.interval_list[self.interval_list_pos], self.scale_list[self.scale_list_pos], self.maxframe_list[self.maxframe_list_pos]), left + 5, right - 5, font_tp, font_tp - 12, r_color, "left", "vcenter")
        if self.recorder_status == "recording" then
            font_tp = font_tp - 12
            RenderTTF('recorder_ui_font', string.format("正在录制 已录制 %d 帧", recorder:get_recorded_frame_count()), left + 5, right - 5, font_tp, font_tp - 12, r_color, "left", "vcenter")
        end
        if self.last_record_info then
            font_tp = font_tp - 12
            if self.last_record_info.success then
                RenderTTF('recorder_ui_font', string.format("GIF保存成功  帧数 %d  文件大小 %.2f %s", self.last_record_info.frame, self.last_record_info.size, self.last_record_info.unit), left + 5, right - 5, font_tp, font_tp - 12, r_color, "left", "vcenter")
                font_tp = font_tp - 12
                RenderTTF('recorder_ui_font', self.last_record_info.path, left + 5, right - 5, font_tp, font_tp - 12, r_color, "left", "vcenter")
            else
                r_color = Color(200 * self.alpha, 255, 0, 0)
                RenderTTF('recorder_ui_font', string.format("GIF生成失败"), left + 5, right - 5, font_tp, font_tp - 12, r_color, "left", "vcenter")
            end
        end
        font_tp = font_tp - 12
        r_color = Color(200 * self.alpha, 255, 255, 255)
        RenderTTF('recorder_ui_font', string.format("Recorder Core ver %d.%d.%d", recorder.ver.major, recorder.ver.minor, recorder.ver.patch), left + 5, right - 5, font_tp, font_tp - 12, r_color, "left", "vcenter")
    else
        r_color = Color(220 * self.alpha, 255, 255, 255)
        RenderTTF('recorder_ui_font', "[Q]打开菜单", left + 5, right - 5, font_tp - 12, font_tp, r_color, "left", "top")
    end
end

return recorder_ui