---=====================================
---坐标映射
---author:Xiliusha
---email:Xiliusha@outlook.com
---=====================================

----------------------------------------
---坐标映射

local M = {}
local CoordTransfer

---@type table<string, table<string, fun(x:number, y:number):number, number>>
local CoordTransfer_switch = {
	["world"] = {
		["ui"] = function(x, y)
			local w = lstg.world
			return
				w.scrl + (w.scrr - w.scrl) * (x - w.l) / (w.r - w.l),
				w.scrb + (w.scrt - w.scrb) * (y - w.b) / (w.t - w.b)
		end,
		["window"] = function(x, y)
			return CoordTransfer("ui", "window", CoordTransfer("world", "ui", x, y))
		end,
		["shader"] = function(x, y)
			return CoordTransfer("window", "shader", CoordTransfer("world", "window", x, y))
		end,
	},
	["ui"] = {
		["world"] = function(x, y)
			local w = lstg.world
			return
				((x - w.scrl) / (w.scrr - w.scrl)) * (w.r - w.l) + w.l,
				((y - w.scrb) / (w.scrt - w.scrb)) * (w.t - w.b) + w.b
		end,
		["window"] = function(x, y)
			local s = screen
			return
				s.dx + x * s.scale,
				s.dy + y * s.scale
		end,
		["shader"] = function(x, y)
			return CoordTransfer("window", "shader", CoordTransfer("ui", "window", x, y))
		end,
	},
	["window"] = {
		["world"] = function(x, y)
			return CoordTransfer("ui", "world", CoordTransfer("window", "ui", x, y))
		end,
		["ui"] = function(x, y)
			local s = screen
			return
				(x - s.dx) / s.scale,
				(y - s.dy) / s.scale
		end,
		["shader"] = function(x, y)
			return
				x,
				setting.resy - y
		end,
	},
	["shader"] = {
		["world"] = function(x, y)
			return CoordTransfer("window", "world", CoordTransfer("shader", "window", x, y))
		end,
		["ui"] = function(x, y)
			return CoordTransfer("window", "ui", CoordTransfer("shader", "window", x, y))
		end,
		["window"] = function(x, y)
			return
			x,
			setting.resy - y
		end,
	},
}
---@param from string | '"world"' | '"ui"' | '"window"' | '"shader"'
---@param to string
---@param x number
---@param y number
---@return number, number
function CoordTransfer(from, to, x, y)
	local f = CoordTransfer_switch[from][to]
	if f then
		return f(x, y)
	else
		error("Invalid arguement.", 2)
	end
end

M.CoordTransfer = CoordTransfer

return M