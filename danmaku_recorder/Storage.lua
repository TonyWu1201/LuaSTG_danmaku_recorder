local succeed, LocalFileStorage = pcall(require, "foundation.LocalFileStorage")
local LocalUserData = lstg.LocalUserData

---@class danmaku_recorder.Storage
local Storage = {}

---@param path string
function Storage.toWindowsPathStyle(path)
    return string.gsub(path, "[/\\]+", "\\")
end

function Storage.getRootDirectory()
    if succeed then
        return LocalFileStorage.getRootDirectory() .. "/danmaku_recorder"
    elseif LocalUserData then
        ---@diagnostic disable-next-line: deprecated
        return LocalUserData.GetRootDirectory() .. "/danmaku_recorder"
    else
        return "danmaku_recorder"
    end
end

function Storage.getTempDirectory()
    return Storage.getRootDirectory() .. "/tmp"
end

function Storage.clearTempDirectory()
    lstg.FileManager.RemoveDirectory(Storage.getTempDirectory())
    lstg.FileManager.CreateDirectory(Storage.getTempDirectory()) -- 还需要创建回来
end

function Storage.getOutputDirectory()
    return Storage.getRootDirectory() .. "/output"
end

function Storage.createDirectories()
    lstg.FileManager.CreateDirectory(Storage.getRootDirectory())
    lstg.FileManager.CreateDirectory(Storage.getTempDirectory())
    lstg.FileManager.CreateDirectory(Storage.getOutputDirectory())
end

---@param task_name string
function Storage.getTempTaskDirectory(task_name)
    assert(type(task_name) == "string")
    return Storage.getTempDirectory() .. "/" .. task_name
end

---@param task_name string
function Storage.createTempTaskDirectory(task_name)
    lstg.FileManager.CreateDirectory(Storage.getTempTaskDirectory(task_name))
end

---@param task_name string
function Storage.clearTempTaskDirectory(task_name)
    lstg.FileManager.RemoveDirectory(Storage.getTempTaskDirectory(task_name))
end

---@param task_name string
---@param file_name string
function Storage.generateTempTaskFilePath(task_name, file_name)
    assert(type(task_name) == "string")
    assert(type(file_name) == "string")
    return Storage.getTempTaskDirectory(task_name) .. "/" .. file_name
end

---@param file_name string
function Storage.generateOutputFilePath(file_name)
    assert(type(file_name) == "string")
    return Storage.getOutputDirectory() .. "/" .. file_name
end

return Storage
