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

local tCommands = {}
local SortedKeys = {}
local SortedMods = {}
local tMods = {}

--
-- Command register API function
--
function signs_bot.register_botcommand(name, def)
	tCommands[name] = def
	tCommands[name].name = name
	if not SortedKeys[def.mod] then
		SortedKeys[def.mod] = {}
		SortedMods[#SortedMods+1] = def.mod
		tMods[#tMods+1] = def.mod
	end
	local idx = #SortedKeys[def.mod] + 1
	SortedKeys[def.mod][idx] = name
end

function signs_bot.get_commands()
	local tbl = {}
	for _,mod in ipairs(SortedMods) do
		tbl[#tbl+1] = mod..I(" commands:")
		for _,cmnd in ipairs(SortedKeys[mod]) do
			local item = tCommands[cmnd]
			tbl[#tbl+1] = "    "..item.name.." "..item.params
		end
	end
	return tbl
end	

function signs_bot.get_help_text(cmnd)
	if cmnd then
		cmnd = unpack(string.split(cmnd, " "))
		local item = tCommands[cmnd]
		if item then
			return item.description
		end
	end
	return I("unknown command")
end	
	
function signs_bot.check_commands(pos, text)
	for idx,line in ipairs(string.split(text, "\n", true)) do
		local b = line:byte(1)
		if b and b ~= 45 and b ~= 32 then -- no blank or comment line?
			local cmnd, param1, param2, param3 = unpack(string.split(line, " "))
			if tCommands[cmnd] then
				if tCommands[cmnd].check and not tCommands[cmnd].check(param1, param2) then
					return false, I("Parameter error in line ")..idx..":\n"..
					cmnd.." "..tCommands[cmnd].params, idx
				end
			else
				return false, I("Command error in line ")..idx..":\n"..line, idx
			end
		end
	end
	return true, I("Checked and approved"), 0
end

function signs_bot.get_comment_text(title, text)
	local tbl = {title, " "}
	for idx,line in ipairs(string.split(text, "\n", true)) do
		local b = line:byte(1)
		if b and b == 45 then -- comment line?
			local _,comment = unpack(string.split(line, " ", false, 1))
			tbl[#tbl+1] = comment
		end
	end
	return table.concat(tbl, "\n")
end

--
-- Command interpreter
--
local function debug(mem, cmnd)
	print("\nDebug: cmnd = "..cmnd)
	if next(mem.lCmnd1) then
		print("lCmnd1 = "..table.concat(mem.lCmnd1, ","))
	else
		print("lCmnd1 = {}")
	end
	if next(mem.lCmnd2) then
		print("lCmnd2 = "..table.concat(mem.lCmnd2, ","))
	else
		print("lCmnd2 = {}")
	end
end

local function check_sign(pos, mem)
	local meta = M(pos)
	local cmnd = meta:get_string("signs_bot_cmnd")
	if cmnd ~= "" then  -- command block?
		if meta:get_int("err_code") ~= 0 then -- code not valid?
			return false
		end
		
		local node = lib.get_node_lvm(pos)
		-- correct sign direction?
		if mem.robot_param2 == node.param2 then
			return true
		end
		-- special sign node?
		if node.name == "signs_bot:bot_flap" or node.name == "signs_bot:box" then
			return true
		end
	end
	return false
end

-- Function returns 2 values:
--  - true if a sensor could be available, else false
--  - the sign pos or nil
local function scan_surrounding(mem)
	if minetest.find_node_near(mem.robot_pos, 1, {
			"signs_bot:box", "signs_bot:bot_sensor", "group:sign_bot_sign"}) then  -- something around?
		local pos1 = lib.next_pos(mem.robot_pos, mem.robot_param2)
		if check_sign(pos1, mem) then
			return true, pos1
		end
		local pos2 = {x=pos1.x, y=pos1.y+1, z=pos1.z}
		if check_sign(pos2, mem) then
			return true, pos2
		end
		return true
	end
	return false
end

local function load_sign_code(meta, mem)
	local cmnd = meta:get_string("signs_bot_cmnd")
	-- read code
	local tbl = {}
	for _,s in ipairs(string.split(cmnd, "\n")) do
		local b = s:byte(1)
		if b ~= 45 and b ~= 32 then -- no blank or comment line?
			tbl[#tbl+1] = s
		end
	end
	-- "forground" or "background" job?
	if next(mem.lCmnd1) then
		mem.lCmnd2 = tbl
		-- remove the "cond_move"
		table.remove(mem.lCmnd1, 1)
	else
		mem.lCmnd1 = tbl
	end
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

local function cond_move(base_pos, mem)
	local any_sensor, sign_pos = scan_surrounding(mem)
	if not sign_pos then
		local new_pos = signs_bot.move_robot(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
			if any_sensor then
				activate_sensor(mem.robot_pos, (mem.robot_param2 + 1) % 4)
				activate_sensor(mem.robot_pos, (mem.robot_param2 + 3) % 4)
			end
		end
		return lib.BUSY
	else
		load_sign_code(M(sign_pos), mem)
		return lib.BUSY  -- don't remove the currently added first cmnd
	end
end	

local function uncond_move(base_pos, mem)
	local any_sensor = scan_surrounding(mem)
	local new_pos = signs_bot.move_robot(mem.robot_pos, mem.robot_param2)
	if new_pos then  -- not blocked?
		mem.robot_pos = new_pos
		if any_sensor then
			activate_sensor(mem.robot_pos, (mem.robot_param2 + 1) % 4)
			activate_sensor(mem.robot_pos, (mem.robot_param2 + 3) % 4)
		end
		mem.steps = mem.steps - 1
	end
end	

local function bot_error(base_pos, mem, err)
	minetest.sound_play('signs_bot_error', {pos = base_pos})
	minetest.sound_play('signs_bot_error', {pos = mem.robot_pos})
	signs_bot.infotext(base_pos, err)
	return false
end

function signs_bot.run_next_command(base_pos, mem)
	mem.lCmnd1 = mem.lCmnd1 or {} -- forground job
	mem.lCmnd2 = mem.lCmnd2 or {} -- background job
	local sts,res,err
	local line = mem.lCmnd2[1] or mem.lCmnd1[1] or "cond_move"
	local cmnd, param1, param2 = unpack(string.split(line, " "))
	if not tCommands[cmnd] then
		return bot_error(base_pos, mem, "Error: Invalid command")
	end
	--debug(mem, cmnd)
	--sts,res,err = true, tCommands[cmnd].cmnd(base_pos, mem, param1, param2)
	sts,res,err = pcall(tCommands[cmnd].cmnd, base_pos, mem, param1, param2)
	if not sts then
		return bot_error(base_pos, mem, err)
	end
	if res == lib.ERROR and err then
		return bot_error(base_pos, mem, err)
	elseif res ~= lib.BUSY then
		local _ = table.remove(mem.lCmnd2, 1) or table.remove(mem.lCmnd1, 1)
	end
	return res ~= lib.TURN_OFF
end


local DESCR1 = I([[Move the robot 1..99 steps forward
without paying attention to any signs.
Up and down movements also become
counted as steps.]])

signs_bot.register_botcommand("move", {
	mod = "move",
	params = "<steps>",	
	description = DESCR1,
	check = function(steps)
		steps = tonumber(steps or "1")
		return steps ~= nil and steps > 0 and steps < 100
	end,
	cmnd = function(base_pos, mem, steps)
		if not mem.steps then
			mem.steps = tonumber(steps or 1)
		end
		uncond_move(base_pos, mem)
		if mem.steps == 0 then
			mem.steps = nil
			return lib.DONE
		end
		return lib.BUSY
	end,
})

local DESCR2 = I([[Go to the next sign
to be executed as a sub-process.
After that it will go on with the next command
on this sign.]])

signs_bot.register_botcommand("cond_move", {
	mod = "move",
	params = "",	
	description = DESCR2,
	cmnd = function(base_pos, mem)
		return cond_move(base_pos, mem)
	end,
})

	