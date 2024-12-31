local recorder = {}

recorder.ver = {}
recorder.ver.major = 1
recorder.ver.minor = 0
recorder.ver.patch = 3

local ffmpeg_path = "ffmpeg.exe"

local CT = require('danmaku_recorder.CoordTransfer')

local status = 'uninitialized'
local initialized = false
local task_name = ''
local index = 0
local frame_counter = 0

local max_frame = 200
local interval = 3
local scale = 0.5

local capture_l = 0
local capture_t = 0
local capture_r = 0
local capture_b = 0

local last_record_info = {}

local draw_capture_area = false

local function call_command(cmd)
    return os.execute(cmd)
end

recorder.init = function (self, s_ffmpeg_path)
    if status == 'uninitialized' then
        lstg.CreateRenderTarget("danmaku_recorder_screen_capture")
        status = 'initialized'
        initialized = true
        if not lstg.FileManager.DirectoryExist('danmaku_recorder') then
            lstg.FileManager.CreateDirectory('danmaku_recorder')
            lstg.FileManager.CreateDirectory('danmaku_recorder/output')
        end
        if lstg.FileManager.DirectoryExist('danmaku_recorder/tmp') then
            lstg.FileManager.RemoveDirectory('danmaku_recorder/tmp')
        end
        lstg.FileManager.CreateDirectory('danmaku_recorder/tmp')
    end
    if s_ffmpeg_path then
        ffmpeg_path = s_ffmpeg_path
    end
    self:set_capture_area_ui()
end

recorder.get_status = function (self)
    return status
end

recorder.set_max_frame = function (self, s_max_frame)
    if status == "initialized" then
        max_frame = max(min(s_max_frame, 1000), 1)
    end
end

recorder.get_max_frame = function (self)
    return max_frame
end

recorder.set_interval = function (self, s_interval)
    if status == "initialized" then
        interval = int(60 / int(60 / interval))
        interval = max(min(s_interval, 60), 1)
    end
end

recorder.get_interval = function (self)
    return interval
end

recorder.set_scale = function (self, s_scale)
    if status == "initialized" then
        scale = s_scale
    end
end

recorder.get_scale = function (self)
    return scale
end

recorder.set_capture_area = function (self, l, t, r, b)
    if status == "initialized" then
        capture_l = l
        capture_t = t
        capture_r = r
        capture_b = b
    end
end

recorder.get_capture_area = function (self)
    return {l = capture_l, t = capture_t, r = capture_r, b = capture_b}
end

--To be deprecated
recorder.set_draw_capture_area = function (self, flag)
    if initialized then
        draw_capture_area = flag
    end
end

recorder.get_draw_capture_area = function (self)
    return draw_capture_area
end

recorder.set_capture_area_world = function (self)
    if status == "initialized" then
        capture_l, capture_t = CT.CoordTransfer("world", "ui", lstg.world.l, lstg.world.t)
        capture_r, capture_b = CT.CoordTransfer("world", "ui", lstg.world.r, lstg.world.b)
    end
end

recorder.set_capture_area_ui = function (self)
    if status == "initialized" then
        capture_l, capture_t = 0, screen.height
        capture_r, capture_b = screen.width, 0
    end
end

recorder.start_capture = function (self)
    if initialized then
        lstg.PushRenderTarget("danmaku_recorder_screen_capture")
        lstg.RenderClear(Color(0, 0, 0, 0))
    end
end

recorder.end_capture = function (self)
    if initialized then
        lstg.PopRenderTarget()

        if status == "recording" then
            if frame_counter % interval == 0 then
                lstg.PushRenderTarget(self.capture_tex)
                local width, height = lstg.GetTextureSize(self.capture_tex)
                width = width / screen.scale
                height = height / screen.scale
                RenderClear(Color(0, 0, 0, 0))
                local tex_l, tex_t = CT.CoordTransfer("ui", "shader", capture_l, capture_t)
                local tex_r, tex_b = CT.CoordTransfer("ui", "shader", capture_r, capture_b)
                SetViewMode("ui")
                lstg.RenderTexture("danmaku_recorder_screen_capture", "",
                    {0, height, 0.5, tex_l, tex_t, Color(255, 255, 255, 255)},--左上
                    {width, height, 0.5, tex_r, tex_t, Color(255, 255, 255, 255)},--右上
                    {width, 0, 0.5, tex_r, tex_b, Color(255, 255, 255, 255)},--右下
                    {0, 0, 0.5, tex_l, tex_b, Color(255, 255, 255, 255)}--左下
                )
                lstg.PopRenderTarget()
                lstg.SaveTexture(self.capture_tex, 'danmaku_recorder/tmp/' .. task_name .. "/" .. string.format("%03d", index) .. ".jpg")
                index = index + 1
                if index >= max_frame then
                    self:end_record()
                end
            end
            frame_counter = frame_counter + 1
        end
    end
end

recorder.draw_capture_content = function ()
    if initialized then
        SetViewMode("ui")
        local width, height = lstg.GetTextureSize("danmaku_recorder_screen_capture")
        lstg.RenderTexture("danmaku_recorder_screen_capture", "",
            {0, screen.height, 0.5, 0, 0, Color(255, 255, 255, 255)},--左上
            {screen.width, screen.height, 0.5, width, 0, Color(255, 255, 255, 255)},--右上
            {screen.width, 0, 0.5, width, height, Color(255, 255, 255, 255)},--右下
            {0, 0, 0.5, 0, height, Color(255, 255, 255, 255)}--左下
        )
        -- if draw_capture_area then
        --     SetImageState("white", "", Color(100, 255, 0, 255))
        --     Render4V("white",
        --         capture_l, capture_b, 0.5,
        --         capture_l, capture_t, 0.5,
        --         capture_r, capture_t, 0.5,
        --         capture_r, capture_b, 0.5
        --     )
        -- end
    end
end

recorder.start_record = function (self)
    if status == "initialized" then
        status = "recording"
        task_name = tostring(os.time())
        index = 0
        frame_counter = 0
        lstg.FileManager.CreateDirectory('danmaku_recorder/tmp/' .. task_name)
        self.capture_tex = "danmaku_recorder_capture_" .. task_name
        local last_pool_state = lstg.GetResourceStatus()
        lstg.SetResourceStatus("global")
        lstg.CreateRenderTarget(self.capture_tex, (capture_r - capture_l) * screen.scale * scale, (capture_t - capture_b) * screen.scale * scale)
        lstg.SetResourceStatus(last_pool_state)
    end
end

recorder.get_recorded_frame_count = function (self)
    return index
end

recorder.end_record = function (self)
    if status == "recording" then
        status = "initialized"
        local width, height = lstg.GetTextureSize(self.capture_tex)
        local tmp_path = 'danmaku_recorder\\tmp\\' .. task_name
        local jpg_path = tmp_path .. "\\%03d.jpg"
        local output_path = 'danmaku_recorder\\output\\' .. task_name .. ".gif"
        local create_gif_cmd = string.format("%s -framerate %d -s %d*%d -i %s -vf \"split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse\" %s", ffmpeg_path, 60 / interval, width, height, jpg_path, output_path)
        local ret = call_command(create_gif_cmd)
        if ret ~= 0 then
            last_record_info.success = false
            last_record_info.size = -1
        else
            lstg.FileManager.RemoveDirectory('danmaku_recorder/tmp/' .. task_name)
            lstg.RemoveResource("global", 1, self.capture_tex)
    
            last_record_info.task_name = task_name
            last_record_info.frame = index
            local fhandle = io.open(output_path, "r")
            last_record_info.path = output_path
            if fhandle then
                last_record_info.success = true
                last_record_info.size = fhandle:seek("end")
            else
                last_record_info.success = false
                last_record_info.size = -1
            end
        end

        task_name = ""
        index = 0
        frame_counter = 0
        self.capture_tex = nil
    end
end

recorder.get_last_record_info = function ()
    local n_last_record_info = {}
    for i, v in pairs(last_record_info) do
        n_last_record_info[i] = v
    end
    return n_last_record_info
end

return recorder