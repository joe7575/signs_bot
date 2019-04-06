--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Bot move commands

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib


-- Positions to check:
--     3
--  [R]1  
--   4 2
--   5 
function signs_bot.move_robot(pos, param2)
	local pos1 = lib.next_pos(pos, param2)
	local pos2 = {x=pos1.x, y=pos1.y-1, z=pos1.z}
	local pos3 = {x=pos1.x, y=pos1.y+1, z=pos1.z}
	local pos4 = {x=pos.x, y=pos.y-1, z=pos.z}
	local pos5 = {x=pos.x, y=pos.y-2, z=pos.z}
	local new_pos = nil
	
	if lib.check_pos(pos1, pos2) then  -- one step forward
		new_pos = pos1
	elseif lib.check_pos(pos3, pos1) then  -- one step up
		local node = lib.get_node_lvm(pos4)
		if node.name == "signs_bot:robot_leg" then 
			return nil
		end
		new_pos = {x=pos.x, y=pos.y+1, z=pos.z}
		minetest.swap_node(pos, {name="signs_bot:robot_foot"})
		minetest.set_node(new_pos, {name="signs_bot:robot", param2=param2})
		minetest.sound_play('signs_bot_step', {pos = new_pos})
		return new_pos
	elseif lib.check_pos(pos1, pos4) then  -- one step forward
		new_pos = pos1		
	elseif lib.check_pos(pos4, pos5) then  -- one step down
		new_pos = pos4		
	else
		return nil -- blocked
	end
	local node4 = lib.get_node_lvm(pos4)
	if node4.name == "signs_bot:robot_foot" or node4.name == "signs_bot:robot_leg" then
		minetest.remove_node(pos4)
		local node5 = lib.get_node_lvm(pos5)
		if node5.name == "signs_bot:robot_foot" then
			minetest.remove_node(pos5)
		end
	end
	minetest.remove_node(pos)
	minetest.set_node(new_pos, {name="signs_bot:robot", param2=param2})
	minetest.sound_play('signs_bot_step', {pos = new_pos})
	return new_pos
end	
	
local function backward_robot(pos, param2)
	local pos1 = lib.next_pos(pos, (param2 + 2) % 4)
	local pos2 = {x=pos1.x, y=pos1.y-1, z=pos1.z}
	local pos4 = {x=pos.x, y=pos.y-1, z=pos.z}
	local pos5 = {x=pos.x, y=pos.y-2, z=pos.z}
	local new_pos = nil
	
	if lib.check_pos(pos1, pos2) then  -- one step forward
		new_pos = pos1
	else
		return nil -- blocked
	end
	local node4 = lib.get_node_lvm(pos4)
	if node4.name == "signs_bot:robot_foot" or node4.name == "signs_bot:robot_leg" then
		minetest.remove_node(pos4)
		local node5 = lib.get_node_lvm(pos5)
		if node5.name == "signs_bot:robot_foot" then
			minetest.remove_node(pos5)
		end
	end
	minetest.remove_node(pos)
	minetest.set_node(new_pos, {name="signs_bot:robot", param2=param2})
	minetest.sound_play('signs_bot_step', {pos = new_pos})
	return new_pos
end	

signs_bot.register_botcommand("backward", {
	mod = "core",
	params = "",	
	description = I("Move the robot one step back"),
	cmnd = function(base_pos, mem)
		local new_pos = backward_robot(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
})

local function turn_robot(pos, param2, dir)
	if dir == "R" then
		param2 = (param2 + 1) % 4
	else
		param2 = (param2 + 3) % 4
	end
	minetest.swap_node(pos, {name="signs_bot:robot", param2=param2})
	minetest.sound_play('signs_bot_step', {pos = pos, gain = 0.6})
	return param2
end	

signs_bot.register_botcommand("turn_left", {
	mod = "core",
	params = "",	
	description = I("Turn the robot to the left"),
	cmnd = function(base_pos, mem)
		mem.robot_param2 = turn_robot(mem.robot_pos, mem.robot_param2, "L")
		return true
	end,
})

signs_bot.register_botcommand("turn_right", {
	mod = "core",
	params = "",	
	description = I("Turn the robot to the right"),
	cmnd = function(base_pos, mem)
		mem.robot_param2 = turn_robot(mem.robot_pos, mem.robot_param2, "R")
		return true
	end,
})

signs_bot.register_botcommand("turn_around", {
	mod = "core",
	params = "",	
	description = I("Turn the robot around"),
	cmnd = function(base_pos, mem)
		mem.robot_param2 = turn_robot(mem.robot_pos, mem.robot_param2, "R")
		mem.robot_param2 = turn_robot(mem.robot_pos, mem.robot_param2, "R")
		return true
	end,
})


-- Positions to check:
--   1
--  [R]  
--   2
local function robot_up(pos, param2)
	local pos1 = {x=pos.x, y=pos.y+1, z=pos.z}
	local pos2 = {x=pos.x, y=pos.y-1, z=pos.z}
	if lib.check_pos(pos1, pos2) then
		local node = lib.get_node_lvm(pos2)
		if node.name == "signs_bot:robot_leg" then 
			return nil
		elseif node.name == "signs_bot:robot_foot" then 
			minetest.swap_node(pos, {name="signs_bot:robot_leg"})
		else
			minetest.swap_node(pos, {name="signs_bot:robot_foot"})
		end
		minetest.set_node(pos1, {name="signs_bot:robot", param2=param2})
		minetest.sound_play('signs_bot_step', {pos = pos1})
		return pos1
	end
	return nil
end	

signs_bot.register_botcommand("move_up", {
	mod = "core",
	params = "",	
	description = I("Move the robot upwards"),
	cmnd = function(base_pos, mem)
		local new_pos = robot_up(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
})

-- Positions to check:
--  [R]  
--   1
--   2
--   3
local function robot_down(pos, param2)
	local pos1 = {x=pos.x, y=pos.y-1, z=pos.z}
	local pos2 = {x=pos.x, y=pos.y-2, z=pos.z}
	local pos3 = {x=pos.x, y=pos.y-3, z=pos.z}
	local node1 = lib.get_node_lvm(pos1)
	if lib.check_pos(pos1, pos2) 
	or (node1.name == "air" and lib.check_pos(pos2, pos3))
	or (node1.name == "signs_bot:robot_leg" or node1.name == "signs_bot:robot_foot") then
		minetest.remove_node(pos)
		minetest.set_node(pos1, {name="signs_bot:robot", param2=param2})
		minetest.sound_play('signs_bot_step', {pos = pos1})
		return pos1
	end
	return nil
end	

signs_bot.register_botcommand("move_down", {
	mod = "core",
	params = "",	
	description = I("Move the robot down"),
	cmnd = function(base_pos, mem)
		local new_pos = robot_down(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
})

signs_bot.register_botcommand("pause", {
	mod = "core",
	params = "<sec>",	
	description = I("Stop the robot for <sec> seconds\n(1..9999)"),
	check = function(sec)
		sec = tonumber(sec or 1)
		return sec and sec > 0 and sec < 10000
	end,
	cmnd = function(base_pos, mem, sec)
		if not mem.steps then
			mem.steps = tonumber(sec or 1)
		end
		mem.steps = mem.steps - 1
		if mem.steps == 0 then
			mem.steps = nil
			return true
		end
	end,
})

signs_bot.register_botcommand("stop", {
	mod = "core",
	params = "",	
	description = I("Stop the robot."),
	cmnd = function(base_pos, mem, slot)
		return nil
	end,
})

signs_bot.register_botcommand("turn_off", {
	mod = "core",
	params = "",	
	description = I("Turn the robot off\n"..
		"and put it back in the box."),
	cmnd = function(base_pos, mem)
		signs_bot.stop_robot(base_pos, mem)
		return false
	end,
})

	
	
