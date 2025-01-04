local recorder = {}

recorder.ver = {}
recorder.ver.major = 1
recorder.ver.minor = 1
recorder.ver.patch = 0

---@class danmaku_recorder.encoder_info
local _ = {
    name = "",
    encoder_path = "",
    target_format = "",
    ---@param info danmaku_recorder.gen_info
    gen_command = function (info) end
}

local CT = require('danmaku_recorder.CoordTransfer')

---@type danmaku_recorder.encoder_info[]
local encoder_info = {}
local current_encoder = -1

local status = 'uninitialized'
local initialized = false
local task_name = ''
local index = 0
local frame_counter = 0

local max_frame = 125
local framerate = 20
local scale = 0.4

local capture_l = 0
local capture_t = 0
local capture_r = 0
local capture_b = 0

local last_record_info = {}

local function call_command(cmd)
    return os.execute(cmd)
end

function recorder:init()
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
    self:load_config()
    self:set_capture_area_ui()
end

function recorder:load_config()
    encoder_info = lstg.DoFile("danmaku_recorder/encoder.lua")
    local config = {encoder_path = {}}
    local flag1, raw_config = pcall(lstg.LoadTextFile, "danmaku_recorder/config.json")
    if flag1 then
        local flag2, e = pcall(cjson.decode, raw_config)
        if flag2 then
            config = e 
        else
            lstg.Log(3, "[danmaku_recorder] 解析config.json失败")
        end
    else
        lstg.Log(3, "[danmaku_recorder] 读取config.json失败")
    end
    for idx, v in ipairs(encoder_info) do
        if current_encoder == -1 and v.name == config.preferred_encoder then
            current_encoder = idx
        end
        if config.encoder_path[v.name] then
            v.encoder_path = config.encoder_path[v.name]
        else
            v.encoder_path = v.name
        end
    end
    current_encoder = min(max(current_encoder, 1), #encoder_info)
end

function recorder.get_status()
    return status
end

function recorder:set_max_frame(s_max_frame)
    if status == "initialized" then
        max_frame = max(min(s_max_frame, 1000), 1)
    end
end

function recorder:get_max_frame()
    return max_frame
end

function recorder:set_interval(s_interval)
    if status == "initialized" then
        framerate = max(min(int(60 / s_interval), 60), 1)
    end
end

function recorder:set_framerate(s_framerate)
    if status == "initialized" then
        s_framerate = int(60 / (60 / s_framerate))
        framerate = max(min(s_framerate, 60), 1)
    end
end

function recorder:get_interval()
    return 60 / framerate
end

function recorder:get_framerate()
    return framerate
end

function recorder:set_scale(s_scale)
    if status == "initialized" then
        scale = s_scale
    end
end

function recorder:get_scale()
    return scale
end

function recorder:set_capture_area(l, t, r, b)
    if status == "initialized" then
        capture_l = l
        capture_t = t
        capture_r = r
        capture_b = b
    end
end

function recorder:get_capture_area()
    return {l = capture_l, t = capture_t, r = capture_r, b = capture_b}
end

function recorder:set_capture_area_world()
    if status == "initialized" then
        capture_l, capture_t = CT.CoordTransfer("world", "ui", lstg.world.l, lstg.world.t)
        capture_r, capture_b = CT.CoordTransfer("world", "ui", lstg.world.r, lstg.world.b)
    end
end

function recorder:set_capture_area_ui()
    if status == "initialized" then
        capture_l, capture_t = 0, screen.height
        capture_r, capture_b = screen.width, 0
    end
end

function recorder:start_capture()
    if initialized and status == "recording" then
        lstg.PushRenderTarget("danmaku_recorder_screen_capture")
        lstg.RenderClear(Color(0, 0, 0, 0))
    end
end

local function process_capture(self)
    if frame_counter % (60 / framerate) == 0 then
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

function recorder:end_capture()
    if initialized and status == "recording" then
        lstg.PopRenderTarget()
        process_capture(self)
    end
end

function recorder:draw_capture_content()
    if initialized and status == "recording" then
        SetViewMode("ui")
        local width, height = lstg.GetTextureSize("danmaku_recorder_screen_capture")
        lstg.RenderTexture("danmaku_recorder_screen_capture", "",
            {0, screen.height, 0.5, 0, 0, Color(255, 255, 255, 255)},--左上
            {screen.width, screen.height, 0.5, width, 0, Color(255, 255, 255, 255)},--右上
            {screen.width, 0, 0.5, width, height, Color(255, 255, 255, 255)},--右下
            {0, 0, 0.5, 0, height, Color(255, 255, 255, 255)}--左下
        )
    end
end

function recorder:start_record()
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

function recorder:get_recorded_frame_count()
    return index
end

function recorder:end_record()
    if status == "recording" then
        status = "initialized"
        local width, height = lstg.GetTextureSize(self.capture_tex)
        local tmp = 'danmaku_recorder\\tmp\\' .. task_name .. '\\'
        local encoder = encoder_info[current_encoder]
        local output_path = 'danmaku_recorder\\output\\' .. task_name .. "." .. encoder.target_format
        local gen_command_info = {
            encoder_path = encoder.encoder_path,
            temp_dir = tmp,
            output_path = output_path,
            width = width,
            height = height,
            framerate = framerate
        }
        local encode_cmd = encoder.gen_command(gen_command_info)
        local ret = call_command(encode_cmd)
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

function recorder:enum_encoders()
    local ret = {}
    for _, v in ipairs(encoder_info) do
        table.insert(ret, v.name)
    end
    return ret
end

function recorder:set_encoder(encoder_index)
    if initialized then
        current_encoder = min(max(1, encoder_index), #encoder_info)
    end
end

function recorder:get_current_encoder()
    return current_encoder
end

function recorder:get_last_record_info()
    local n_last_record_info = {}
    for i, v in pairs(last_record_info) do
        n_last_record_info[i] = v
    end
    return n_last_record_info
end

return recorder