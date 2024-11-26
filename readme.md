# Danmaku Recorder 介绍与使用教程
这是一个通过RenderTarget捕获画面并调用FFmpeg来生成GIF的插件。

下面将介绍如何安装并使用该插件。
## Step1 FFmpeg下载和配置
1. 去[这里](https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip)下载FFmpeg。
2. 把压缩包里的bin文件夹解压出来，放到一个相对稳定的目录里面。
3. （可选）在环境变量Path中添加你刚才解压的bin文件夹的路径。在终端里输入ffmpeg，出现ffmpeg version XXX即成功。
4. （可选）如果没有将FFmpeg添加到path，你需要在调用`recorder:init`的时候指定FFmpeg的路径。
## Step2 安装插件
### LuaSTG aex+ 0.9.0以上的版本
把recorder_plugin文件夹复制到LuaSTG的plugins文件夹下，在设置里启用danmaku_recorder插件。

如果要指定FFmpeg的路径，请打开register_event.lua，找到`recorder:init()`，在括号中添加FFmpeg路径（字符串）。

例如`recorder:init("D:\\FFmpeg_bin\\ffmpeg.exe")`
### LuaSTG aex+ 0.8.x的版本
把recorder_plugin文件夹复制到LuaSTG的plugins文件夹下，在设置里启用danmaku_recorder插件。

此外还需要手动修改thlib-scripts/THlib/ext.lua。在ext.lua开头加入以下部分
```lua
local recorder_exist, recorder = pcall(require, "danmaku_recorder.recorder")
if recorder_exist then recorder:init() end
local recorder_ui_exist, recorder_ui = pcall(require, "danmaku_recorder.recorder_ui")
if recorder_ui_exist then recorder_ui:init() end
```
如果要指定FFmpeg的路径，请在调用`recorder:init`时传入路径，与上述方法相同

在GameScene:onUpdate中添加以下内容
```lua
if recorder_ui_exist then recorder_ui:frame() end
```
在GameScene:onRender的BeforeRender()后面添加以下内容
```lua
if recorder_exist then recorder:start_capture() end
```
在GameScene:onRender的ObjRender()后面添加以下内容
```lua
if recorder_exist then recorder:end_capture() end
SetViewMode("ui")
if recorder_exist then recorder:draw_capture_content() end
```
在GameScene:onRender的AfterRender()后面添加以下内容
```lua
SetViewMode("ui")
if recorder_ui_exist then recorder_ui:render() end
```
## Step3 插件使用说明
按Q启动菜单，可以用Danmaku Recorder UI控制Danmaku Recorder。

按O键可以拖动鼠标框选录制区域，按下O键以后按住鼠标不放，拖动到直到框出希望截取的区域再松开。在未按下或未松开鼠标时再按O会取消。

录制完成以后，你可以在danmaku_recorder\output文件夹下找到输出文件。

你也可以通过`require("danmaku_recorder.recorder")`来获取recorder对象并使用其成员函数控制。请阅读其代码了解详情。
## Change Log
### Danmaku Recorder
+ 1.0.1 
    1. 优化了调用ffmpeg的命令行，修复生成gif的帧数和速度异常的问题。
    2. 修复了从编辑器或者重定向输出以后卡死的问题。
    3. 增加了手动指定ffmpeg路径的功能。
+ 1.0.2
    1. 把忘记删掉的print删掉了。
### Danmaku Recorder UI
+ 1.0.1
    1. 调整了默认选项。
    2. 增加了在UI里显示Recorder版本号。
### 其他
+ Bundle 1.0.1
    1. 调整目录结构。
    2. readme写得稍微详细了一点。
+ Bundle 1.0.2
    1. 调整目录结构，便于推送到GitHub。
    2. 补充开源许可相关信息。
## 开源许可相关
1. recorder_ui_font.otf 使用的是Adobe开发的[思源黑体](https://github.com/adobe-fonts/source-han-sans)，遵守SIL Open Font License Version 1.1开源许可。
2. CoordTransfer.lua 是由Xiliusha编写的坐标系映射工具，有一定修改。

<br><br><br>
祝使用愉快

By TNW