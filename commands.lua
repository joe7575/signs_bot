--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signs Bot: Robot command interpreter

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local function no_cmnd_block(pos, mem)
	local pos1 = lib.next_pos(mem.robot_pos, mem.robot_param2)
	local cmnd = M(pos1):get_string("signs_bot_cmnd")
	
	if cmnd ~= "" then
		mem.lCmnd = {}
		for s in cmnd:gmatch("[^\r\n]+") do
			table.insert(mem.lCmnd, s)
		end
		return false
	end
	
	cmnd = M({x=pos1.x, y=pos1.y+1, z=pos1.z}):get_string("signs_bot_cmnd")
	if cmnd ~= "" then
		mem.lCmnd = {}
		for s in cmnd:gmatch("[^\r\n]+") do
			table.insert(mem.lCmnd, s)
		end
		return false
	end
	
	return true
end

local Commands = {
	move = function(base_pos, mem, steps)
		if no_cmnd_block(base_pos, mem) then
			local new_pos = signs_bot.move_robot(mem.robot_pos, mem.robot_param2, steps)
			if new_pos then  -- not blocked?
				mem.robot_pos = new_pos
			end
			-- more than one move step?
			steps = tonumber(steps)
			if steps and steps > 1 then
				steps = steps - 1
				-- add to the command table again
				table.insert(mem.lCmnd, 1, "move "..steps)
			end
		end
		return true
	end,
	turn_left = function(base_pos, mem)
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "L")
		return true
	end,
	turn_right = function(base_pos, mem)
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "R")
		return true
	end,
	turn_back = function(base_pos, mem)
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "R")
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "R")
		return true
	end,
	backward = function(base_pos, mem)
		local new_pos = signs_bot.backward_robot(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
	turn_off = function(pos, mem)
		signs_bot.stop_robot(pos)
		return false
	end,
	pause = function(base_pos, mem, steps)
		-- more than one move step?
		steps = tonumber(steps)
		if steps and steps > 1 then
			steps = steps - 1
			-- add to the command table again
			table.insert(mem.lCmnd, 1, "pause "..steps)
		end
		return true
	end,
	move_up = function(base_pos, mem)
		local new_pos = signs_bot.robot_up(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
	move_down = function(base_pos, mem)
		local new_pos = signs_bot.robot_down(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
	take_item = function(base_pos, mem, pos, slot)
		signs_bot.robot_take(base_pos, mem.robot_pos, mem.robot_param2, pos, slot)
		return true
	end,
	add_item = function(base_pos, mem, pos, slot)
		signs_bot.robot_add(base_pos, mem.robot_pos, mem.robot_param2, pos, slot)
		return true
	end,
	place_item = function(base_pos, mem, pos, slot, level)
		signs_bot.place_item(base_pos, mem.robot_pos, mem.robot_param2, pos, slot, level)
		return true
	end,
	dig_item = function(base_pos, mem, pos, slot, level)
		signs_bot.dig_item(base_pos, mem.robot_pos, mem.robot_param2, pos, slot, level)
		return true
	end,
	place_sign = function(base_pos, mem, slot)
		signs_bot.place_sign(base_pos, mem.robot_pos, mem.robot_param2, slot)
		return true
	end,
	dig_sign = function(base_pos, mem, slot)
		signs_bot.dig_sign(base_pos, mem.robot_pos, mem.robot_param2, slot)
		return true
	end,
	trash_sign = function(base_pos, mem, slot)
		signs_bot.trash_sign(base_pos, mem.robot_pos, mem.robot_param2, slot)
		return true
	end,
	stop_robot = function(base_pos, mem, pos, slot)
		return true
	end, 
	rotate_item = function(base_pos, mem, pos, level, steps)
		signs_bot.rotate_item(base_pos, mem.robot_pos, mem.robot_param2, pos, level, steps)
		return true
	end, 
}

function signs_bot.command(pos, mem, s)
	local cmnd, param1, param2, param3 = unpack(string.split(s, " "))
	if cmnd == "--" then -- comment
		return true
	elseif Commands[cmnd] then
		return Commands[cmnd](pos, mem, param1, param2, param3)
	else
		return false, I("Syntax error in command '")..cmnd.."'"
	end
end
	