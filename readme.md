# Danmaku Recorder 介绍与使用教程

这是一个用于 LuaSTG aex+ 的录制插件，可以将游戏画面输出为 GIF 等动图，方便弹幕制作者分享和展示给他人。

下面介绍如何安装并使用该插件。

## 第一步：编码库下载和配置

Danmaku Recorder 插件只负责录制游戏画面，要将录制的内容编码为 GIF 等动图文件格式，**必须额外安装编码库**。

Danmaku Recorder 插件目前支持以下编码库：

* [FFmpeg](https://ffmpeg.org/)
    1. 下载[编译好的Windows 64位版本](https://github.com/GyanD/codexffmpeg/releases/download/7.1/ffmpeg-7.1-full_build-shared.zip)
    2. 将所有内容解压到一个单独的文件夹中，并记下`bin`文件夹的路径
        > 提醒：最好放到不会被随便移动或删除的文件夹中，不建议放到桌面，不建议放到U盘、移动硬盘等可插拔存储器中
    3. （可选）配置环境变量
        1. 在系统或当前用户的环境变量Path中添加`bin`文件夹的路径
        2. 关掉所有命令行窗口，打开一个新的命令行窗口，输入`ffmpeg -version`，出现以下内容说明添加成功
            ```
            ffmpeg version 7.1-full_build-www.gyan.dev Copyright (c) 2000-2024 the FFmpeg developers
            （省略后续内容）
            ```
    4. （可选，**如果跳过第3步，那么这一步必须要做**）在插件的`config.json`中指定`ffmpeg.exe`可执行文件的完整路径
        > 注意：修改的是插件的`config.json`，不是`LuaSTGSub.exe`旁边的`config.json`
* [SimpleGifEncoder](https://github.com/BAKAOLC/SimpleGifEncoder)
    1. [项目地址](https://github.com/BAKAOLC/SimpleGifEncoder)。
    2. 可能需要[自行编译](https://learn.microsoft.com/zh-cn/dotnet/core/tutorials/publishing-with-visual-studio)。
    3. 与上述配置FFmpeg方法相同配置SimpleGifEncoder的路径。

## 第二步：安装插件

1. 把此文件夹复制到LuaSTG aex+的plugins文件夹下
    > 提示：如果从GitHub下载zip压缩包，请将压缩包中的`LuaSTG_danmaku_recorder-main`文件夹解压到plugins文件夹下
2. 在启动器插件设置页面启用danmaku_recorder插件
    > 提示：通常情况下这步可以省略，LuaSTG aex+ 会自动启用新增的插件
3. （可选）如果要使用FFmpeg来编码GIF，则需要指定FFmpeg的路径，请打开`config.json`，在`encoder_path`中，修改键`ffmpeg`的值。指定SimpleGifEncoder的路径同理。
    > 注意：修改的是插件的`config.json`，不是`LuaSTGSub.exe`旁边的`config.json`
4. 【不推荐】（可选）如果要启用原先的UI，请打开register_event.lua，找到`config`，修改键`use_native_ui`的值为`true`。

## 第三步：适配插件

**如果你正在使用 LuaSTG aex+ 0.9.0 或之后的版本，这一步可以跳过。**

**如果你正在使用 LuaSTG aex+ 0.8.22 或更早的版本，需要按照本节的说明一步步操作。**

推荐使用 Visual Studio Code 编辑 lua 文件，避免出现乱码等问题。

1. 手动修改 `thlib-scripts/THlib/ext.lua`，在文件开头插入以下代码
    ```lua
    local recorder_exist, recorder = pcall(require, "danmaku_recorder.recorder")
    if recorder_exist then recorder:init() end
    local recorder_imgui_exist, recorder_imgui = pcall(require, "danmaku_recorder.recorder_imgui")
    if recorder_imgui_exist then
        recorder_imgui:init()
        local debugger = require('lib.Ldebug')
        debugger.addView("Danmaku Recorder Plugin", recorder_imgui)
    end
2. 手动修改 `thlib-scripts/THlib/ext.lua`，在文件中插入以下代码
    * 在`GameScene:onRender`的`BeforeRender()`后面插入以下代码
        ```lua
        if recorder_exist then recorder:start_capture() end
        ```
    * 在`GameScene:onRender`的`ObjRender()`后面插入以下代码
        ```lua
        if recorder_exist then
            recorder:end_capture()
            recorder:draw_capture_content()
        end
        ```
    * 在`GameScene:onRender`的`AfterRender()`后面插入以下代码
        ```lua
        if recorder_imgui_exist then recorder_imgui:render() end
        ```
3. （可选）如果要使用原生UI，还需要手动修改 `thlib-scripts/THlib/ext.lua`，插入以下代码
    * 在文件开头插入以下代码
        ```lua
        local recorder_ui_exist, recorder_ui = pcall(require, "danmaku_recorder.recorder_ui")
        if recorder_ui_exist then
            recorder_ui:init()
        end
        ```
    * 在`GameScene:onUpdate`中插入以下代码
        ```lua
        if recorder_ui_exist then recorder_ui:frame() end
        ```
    * 在`GameScene:onRender`的`AfterRender()`后面插入以下代码
        ```lua
        SetViewMode("ui")
        if recorder_ui_exist then recorder_ui:render() end
        ```

## 插件使用说明

### 配置文件说明

* `encoder_path` 用于指定编码器可执行路径。
* `preferred_encoder` 用于指定优先使用的编码器。
* `load_sound` 在插件初始化时加载音效。<br>
eg.
    ```json
    "load_sound" : [
        {
            "name" : "sename",
            "path" : "sepath"
        }
    ],
    ```
* `hint->se` 使用音效提示录制状态相关的设置。
    * `enable` 是否启用。
    * `volume` 音量大小。
    * `on_start` `on_stop` 开始与结束时播放的音效，填空字符串则不播放音效。

以下功能**只对**ImGui UI有效

* `hotkeys` 用于指定开始录制和停止录制的快捷键。参考`Lkeycode.lua`。<br>
eg.
    ```json
    "hotkeys": {
        "start_record" : ["Q", "W"],
        "end_record" : ["1", "Q", "F1"]
    },
    ```
* `auto_enable` 为`true`则会自动启用插件，`false`则需要手动打开。
* `save_config` 用于指定自动保存配置。`enable`为`true`即启用，`false`为禁用，`path`用于指定保存文件的路径。
* `default_config` 用于指定默认配置。只在禁用自动保存或未从文件中读取配置时生效。
* `load_ttf` 在UI初始化时加载字体。<br>
eg.
    ```json
    "load_ttf" : [
        {
            "name" : "recorder_ui_font",
            "path" : "danmaku_recorder/recorder_ui_font.otf",
            "size" : 20
        }
    ],
    ```
* `hint->text` 在录制时渲染文字提示。
    * `enable` 是否启用。
    * `content` 显示的内容。
    * `font` 渲染用的字体名。
    * `position` 渲染中心的坐标（对应xy）。
    * `scale` 缩放比例。
    * `color` 渲染颜色（对应argb）。

### ImGui UI

按下F3打开debug菜单，在Tool里面找到`Danmaku Recorder Plugin`，打开即可使用。

### 原生 UI

按Q启动菜单，可以用Danmaku Recorder UI控制Danmaku Recorder。

按O键可以拖动鼠标框选录制区域，按下O键以后按住鼠标不放，拖动到直到框出希望截取的区域再松开。在未按下或未松开鼠标时再按O会取消。

录制完成以后，你可以在danmaku_recorder\output文件夹下找到输出文件。

### 通过代码调用

你也可以通过`require("danmaku_recorder.recorder")`获取recorder对象并调用成员函数。

请阅读源代码了解具体使用方法。

## 更新日志

请阅读[CHANGELOG.md](./CHANGELOG.md)。

## 贡献者

* [TNW](https://github.com/TonyWu1201)
* [璀境石](https://github.com/Demonese)

## 第三方文件许可说明

| 文件 | 来源 | 开源协议 |
|---|---|---|
| recorder_ui_font.otf | [Adobe 思源黑体](https://github.com/adobe-fonts/source-han-sans) | SIL Open Font License Version 1.1 |
| CoordTransfer.lua | [Xiliusha](https://github.com/Xiliusha) 编写的坐标系映射工具（有一定修改） | MIT |

---

祝使用愉快
