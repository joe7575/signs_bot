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

local tPos2Dir = {l = "l", r = "r", L = "l", R = "l", f = "f", F = "f"}


local tCommands = {}
local SortedKeys = {}
local SortedMods = {}

--
-- Command register API function
--

function signs_bot.register_botcommand(name, def)
	tCommands[name] = def
	tCommands[name].name = name
	if not SortedKeys[def.mod] then
		SortedKeys[def.mod] = {}
		SortedMods[#SortedMods+1] = def.mod
	end
	local idx = #SortedKeys[def.mod] + 1
	SortedKeys[def.mod][idx] = name
end


local function check_cmnd_block(pos, mem, meta)
	local cmnd = meta:get_string("signs_bot_cmnd")
	if cmnd ~= "" then  -- command block?
		if meta:get_int("err_code") ~= 0 then -- code not valid?
			return false
		end
		local node = lib.get_node_lvm(pos)
		
		if node.name ~= "signs_bot:box" and mem.robot_param2 ~= node.param2 then -- wrong sign direction?
			return false
		end
		-- read code
		mem.lCmnd = {}
		for _,s in ipairs(string.split(cmnd, "\n")) do
			table.insert(mem.lCmnd, s)
		end
		return true
	end
	return false
end


local function activate_sensor(pos, param2)
	local pos1 = lib.next_pos(pos, param2)
	local node = lib.get_node_lvm(pos1)
	if node.name == "signs_bot:bot_sensor" then
		node.name = "signs_bot:bot_sensor_on"
		minetest.swap_node(pos1, node)
		minetest.registered_nodes[node.name].after_place_node(pos1)
	end
end

local function no_sign_around(mem)
	if minetest.find_node_near(mem.robot_pos, 1, {
			"signs_bot:box", "signs_bot:bot_sensor", "group:sign_bot_sign"}) then  -- something around?
		local pos1 = lib.next_pos(mem.robot_pos, mem.robot_param2)
		local meta = M(pos1)
		if check_cmnd_block(pos1, mem, meta) then
			return false, true
		end
		local pos2 = {x=pos1.x, y=pos1.y+1, z=pos1.z}
		meta = M(pos2)
		if check_cmnd_block(pos2, mem, meta) then
			return false, true
		end
		return true, true
	end
	return true, false
end


local function move(base_pos, mem)
	local no_sign, has_sensor = no_sign_around(mem)
	if no_sign then
		local new_pos = signs_bot.move_robot(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
			if has_sensor then
				activate_sensor(mem.robot_pos, (mem.robot_param2 + 1) % 4)
				activate_sensor(mem.robot_pos, (mem.robot_param2 + 3) % 4)
			end
		end
		mem.steps = mem.steps - 1
	else
		mem.steps = nil
	end
end	

signs_bot.register_botcommand("move", {
	mod = "core",
	params = "<steps>",	
	description = I("Move the robot 1..99 steps forward."),
	check = function(steps)
		steps = tonumber(steps or "1")
		return steps ~= nil and steps > 0 and steps < 100
	end,
	cmnd = function(base_pos, mem, steps)
		if not mem.steps then
			mem.steps = tonumber(steps or 1)
		end
		move(base_pos, mem)
		if mem.steps == 0 then
			mem.steps = nil
			return true
		end
	end,
})

	
function signs_bot.check_commands(pos, text)
	--local idx = 1
	for idx,line in ipairs(string.split(text, "\n", true)) do
		local cmnd, param1, param2, param3 = unpack(string.split(line, " "))
		if cmnd ~= "--" and cmnd ~= nil then -- No comment or empty line?
			if tCommands[cmnd] then
				if tCommands[cmnd].check and not tCommands[cmnd].check(param1, param2, param3) then
					return false, I("Parameter error in line ")..idx..":\n"..
					cmnd.." "..tCommands[cmnd].params
				end
			else
				return false, I("Command error in line ")..idx..":\n"..line
			end
		end
		--idx = idx + 1
	end
	return true, I("Checked and approved")
end

function signs_bot.run_next_command(base_pos, mem)
	mem.lCmnd = mem.lCmnd or {}
	local res = nil
	local sts
	while res == nil do
		local line = mem.lCmnd[1]
		if line then
			local cmnd, param1, param2 = unpack(string.split(line, " "))
			if cmnd ~= "--" and tCommands[cmnd] then -- Valid command?
				sts,res = true, tCommands[cmnd].cmnd(base_pos, mem, param1, param2)
				--sts, res = pcall(tCommands[cmnd].cmnd, base_pos, mem, param1, param2)
				if not sts then
					minetest.sound_play('signs_bot_error', {pos = base_pos})
					minetest.sound_play('signs_bot_error', {pos = mem.robot_pos})
					signs_bot.infotext(base_pos, I("error"))
					return false  -- finished
				elseif res == nil then -- need more time slices?
					return true  -- busy
				end
			else
				res = true
			end
			table.remove(mem.lCmnd, 1)
		else
			res = tCommands["move"].cmnd(base_pos, mem)
		end
	end
	return res -- true if ok, false if error or finished
end	

function signs_bot.get_help_text()
	local tbl = {}
	for _,mod in ipairs(SortedMods) do
		for _,cmnd in ipairs(SortedKeys[mod]) do
			local item = tCommands[cmnd]
			tbl[#tbl+1] = item.name.." "..item.params
			local text = string.gsub(item.description, "\n", "\n  -- ")
			tbl[#tbl+1] = "  -- "..text
		end
	end
	return table.concat(tbl, "\n")
end	
	
	