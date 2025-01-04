# Danmaku Recorder 介绍与使用教程
这是一个通过RenderTarget捕获画面并调用FFmpeg或其他编码器来生成动图的插件。

下面将介绍如何安装并使用该插件。
## Step1 编码器下载和配置
### FFmpeg
1. 去[这里](https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip)下载FFmpeg。
2. 把压缩包里的bin文件夹解压出来，放到一个相对稳定的目录里面。
3. （可选）在环境变量Path中添加你刚才解压的bin文件夹的路径。在终端里输入ffmpeg，出现ffmpeg version XXX即成功。
4. （可选）如果没有将FFmpeg添加到path，你需要在插件目录下的danmaku_recorder/config.json中指定ffmpeg可执行程序的路径。
### SimpleGifEncoder
1. [项目地址](https://github.com/BAKAOLC/SimpleGifEncoder)。
2. 可能需要[自行编译](https://learn.microsoft.com/zh-cn/dotnet/core/tutorials/publishing-with-visual-studio)。
3. 与上述配置FFmpeg方法相同配置SimpleGifEncoder的路径。
## Step2 安装插件
### LuaSTG aex+ 0.9.0以上的版本
把此文件夹复制到LuaSTG的plugins文件夹下，在设置里启用danmaku_recorder插件。

（不推荐）如果要启用原先的UI，请打开register_event.lua，找到`config`，修改键`use_native_ui`的值为`true`。

如果要指定FFmpeg的路径，请打开danmaku_recorder/config.json，在`encoder_path`中，修改键`ffmpeg`的值。指定SimpleGifEncoder的路径同理。
### LuaSTG aex+ 0.8.x的版本
把recorder_plugin文件夹复制到LuaSTG的plugins文件夹下，在设置里启用danmaku_recorder插件。

此外还需要手动修改thlib-scripts/THlib/ext.lua。在ext.lua开头加入以下部分
```lua
local recorder_exist, recorder = pcall(require, "danmaku_recorder.recorder")
if recorder_exist then recorder:init() end
local recorder_imgui_exist, recorder_imgui = pcall(require, "danmaku_recorder.recorder_imgui")
if recorder_imgui_exist then
    recorder_imgui:init()
    local debugger = require('lib.Ldebug')
    debugger.addView("Danmaku Recorder Plugin", recorder_imgui)
end
```
如果要使用原生UI，再添加以下内容
```lua
local recorder_ui_exist, recorder_ui = pcall(require, "danmaku_recorder.recorder_ui")
if recorder_ui_exist then recorder_ui:init() end
```
如果要指定编码器可执行程序的路径，请修改danmaku_recorder/config.json中的相关信息。

如果要使用原生UI，在`GameScene:onUpdate`中添加以下内容
```lua
if recorder_ui_exist then recorder_ui:frame() end
```
在`GameScene:onRender`的`BeforeRender()`后面添加以下内容
```lua
if recorder_exist then recorder:start_capture() end
```
在`GameScene:onRender`的`ObjRender()`后面添加以下内容
```lua
if recorder_exist then recorder:end_capture() end
SetViewMode("ui")
if recorder_exist then recorder:draw_capture_content() end
```
在`GameScene:onRender`的`AfterRender()`后面添加以下内容
```lua
SetViewMode("ui")
if recorder_imgui_exist then recorder_imgui:render() end
```
如果要使用原生UI，在`GameScene:onRender`的`AfterRender()`后面添加以下内容
```lua
SetViewMode("ui")
if recorder_ui_exist then recorder_ui:render() end
```
## Step3 插件使用说明
### 配置文件说明
+ `encoder_path` 用于指定编码器可执行路径。
+ `preferred_encoder` 用于指定优先使用的编码器。

以下功能**只对**ImGui UI有效

+ `hotkeys` 用于指定开始录制和停止录制的快捷键。参考`Lkeycode.lua`。<br>
eg.
    ```json
    "hotkeys": {
        "start_record" : ["Q", "W"],
        "end_record" : ["1", "Q", "F1"]
    },
    ```
+ `auto_enable` 为`true`则会自动启用插件，`false`则需要手动打开。
+ `save_config` 用于指定自动保存配置。`enable`为`true`即启用，`false`为禁用，`path`用于指定保存文件的路径。
+ `default_config` 用于指定默认配置。只在禁用自动保存或未从文件中读取配置时生效。

### ImGui UI
按下F3打开debug菜单，在Tool里面找到`Danmaku Recorder Plugin`，打开即可使用。
### 原生UI
按Q启动菜单，可以用Danmaku Recorder UI控制Danmaku Recorder。

按O键可以拖动鼠标框选录制区域，按下O键以后按住鼠标不放，拖动到直到框出希望截取的区域再松开。在未按下或未松开鼠标时再按O会取消。

录制完成以后，你可以在danmaku_recorder\output文件夹下找到输出文件。
### 非UI使用
你也可以通过`require("danmaku_recorder.recorder")`来获取recorder对象并使用其成员函数控制。请阅读其代码了解详情。
## Change Log
### Danmaku Recorder
+ 1.0.1 
    1. 优化了调用ffmpeg的命令行，修复生成gif的帧数和速度异常的问题。
    2. 修复了从编辑器或者重定向输出以后卡死的问题。
    3. 增加了手动指定ffmpeg路径的功能。
+ 1.0.2
    1. 把忘记删掉的print删掉了。
+ 1.0.3
    1. 将显示录制区域的功能移除，改为在UI中渲染。
    2. 生成调色板的命令合并。
+ 1.1.0
    1. 加入了指定编码器的功能。
    2. 将采集间隔改为了采集帧率。
    3. 删除显示录制区域的API。
### Danmaku Recorder UI
+ 1.0.1
    1. 调整了默认选项。
    2. 增加了在UI里显示Recorder版本号。
+ 1.0.2
    1. 显示录制区域改为在UI中渲染。
+ 1.0.3
    1. 添加停止维护提示。
### Danmaku Recorder UI (ImGui)
+ 1.1.0
    1. 用ImGui重写了原本的UI。
+ 1.2.0
    1. 把忘记删掉的print删掉了。
    2. 添加了自动保存配置和默认配置的功能。
    3. 添加了选择编码器的功能。
    4. 将采集间隔改为了采集帧率。
### 其他
+ Bundle 1.0.1
    1. 调整目录结构。
    2. readme写得稍微详细了一点。
+ Bundle 1.0.2
    1. 调整目录结构，便于推送到GitHub。
    2. 补充开源许可相关信息。
+ Bundle 1.0.3
    1. 添加并默认使用ImGuiUI。
+ Bundle 1.1.0
    1. 添加指定编码器的功能。
    2. 添加config.json用于配置更多功能。
## 开源许可相关
1. recorder_ui_font.otf 使用的是Adobe开发的[思源黑体](https://github.com/adobe-fonts/source-han-sans)，遵守SIL Open Font License Version 1.1开源许可。
2. CoordTransfer.lua 是由Xiliusha编写的坐标系映射工具，有一定修改。

<br><br><br>
祝使用愉快

By TNW