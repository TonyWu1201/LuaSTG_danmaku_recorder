---@class danmaku_recorder.gen_info
local _ = {
    encoder_path = "",
    temp_dir = "",
    output_path = "",
    width = 1,
    height = 1,
    framerate = 20
}

return {
    {
        name = "ffmpeg",
        target_format = "gif",
        ---@param info danmaku_recorder.gen_info
        gen_command = function (info)
            local command = string.format(
                "%s -framerate %d -s %d*%d -i %s -vf \"split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse\" %s",
                info.encoder_path,
                info.framerate,
                info.width,
                info.height,
                info.temp_dir .. '%03d.jpg',
                info.output_path
            )
            return command
        end
    },
    {
        name = "SimpleGifEncoder",
        target_format = "gif",
        ---@param info danmaku_recorder.gen_info
        gen_command = function (info)
            local command = string.format(
                "%s -f %d -s %d*%d -i %s -o %s",
                info.encoder_path,
                info.framerate,
                info.width,
                info.height,
                info.temp_dir .. '*.jpg',
                info.output_path
            )
            return command
        end
    }
}