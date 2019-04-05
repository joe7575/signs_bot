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
local tValidLevels = {["-1"] = -1, ["0"] = 0, ["+1"] = 1}


local tCommands = {}
local SortedKeys = {}
local SortedMods = {}

--
-- Command register API function
--

-- def = {
--     mod = "my_mod",
--     params = "<lvl> <slot>",
--     description = "...",
--     check = function(param1 param2) ... return true/false end,
--     cmnd = function(base_pos, mem, param1, param2) ... return true/false end,
-- }
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

signs_bot.register_botcommand("turn_left", {
	mod = "core",
	params = "",	
	description = I("Turn the robot to the left"),
	cmnd = function(base_pos, mem)
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "L")
		return true
	end,
})

signs_bot.register_botcommand("turn_right", {
	mod = "core",
	params = "",	
	description = I("Turn the robot to the right"),
	cmnd = function(base_pos, mem)
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "R")
		return true
	end,
})

signs_bot.register_botcommand("turn_around", {
	mod = "core",
	params = "",	
	description = I("Turn the robot around"),
	cmnd = function(base_pos, mem)
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "R")
		mem.robot_param2 = signs_bot.turn_robot(mem.robot_pos, mem.robot_param2, "R")
		return true
	end,
})

signs_bot.register_botcommand("backward", {
	mod = "core",
	params = "",	
	description = I("Move the robot one step back"),
	cmnd = function(base_pos, mem)
		local new_pos = signs_bot.backward_robot(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
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
	
signs_bot.register_botcommand("move_up", {
	mod = "core",
	params = "",	
	description = I("Move the robot upwards"),
	cmnd = function(base_pos, mem)
		local new_pos = signs_bot.robot_up(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
})
	
signs_bot.register_botcommand("move_down", {
	mod = "core",
	params = "",	
	description = I("Move the robot down"),
	cmnd = function(base_pos, mem)
		local new_pos = signs_bot.robot_down(mem.robot_pos, mem.robot_param2)
		if new_pos then  -- not blocked?
			mem.robot_pos = new_pos
		end
		return true
	end,
})
	
signs_bot.register_botcommand("take_item", {
	mod = "core",
	params = "<num> <slot>",	
	description = I("Take <num> items from a chest like node\nand put it into the item inventory.\n"..
		"<slot> is the inventory slot (1..8)"),
	check = function(num, slot)
		num = tonumber(num or 1)
		if not num or num < 1 or num > 99 then 
			return false 
		end
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return true
	end,
	cmnd = function(base_pos, mem, num, slot)
		num = tonumber(num or 1)
		slot = tonumber(slot or 1)
		signs_bot.robot_take(base_pos, mem.robot_pos, mem.robot_param2, num, slot)
		return true
	end,
})
	
signs_bot.register_botcommand("add_item", {
	mod = "core",
	params = "<num> <slot>",	
	description = I("Add <num> items to a chest like node\ntaken from the item inventory.\n"..
		"<slot> is the inventory slot (1..8)"),
	check = function(num, slot)
		num = tonumber(num or 1)
		if not num or num < 1 or num > 99 then 
			return false 
		end
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return true
	end,
	cmnd = function(base_pos, mem, num, slot)
		num = tonumber(num or 1)
		slot = tonumber(slot or 1)
		signs_bot.robot_add(base_pos, mem.robot_pos, mem.robot_param2, num, slot)
		return true
	end,
})
	
signs_bot.register_botcommand("add_fuel", {
	mod = "core",
	params = "<num> <slot>",	
	description = I("Add <num> fuel items to a furnace like node\ntaken from the item inventory.\n"..
		"<slot> is the inventory slot (1..8)"),
	check = function(num, slot)
		num = tonumber(num or 1)
		if not num or num < 1 or num > 99 then 
			return false 
		end
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return true
	end,
	cmnd = function(base_pos, mem, num, slot)
		num = tonumber(num or 1)
		slot = tonumber(slot or 1)
		signs_bot.robot_add(base_pos, mem.robot_pos, mem.robot_param2, num, slot)
		return true
	end,
})

signs_bot.register_botcommand("place_front", {
	mod = "core",
	params = "<slot> <lvl>",	
	description = I("Place an item in front of the robot\n"..
		"<slot> is the inventory slot (1..8)\n"..
		"<lvl> is one of: -1   0   +1"),
	check = function(slot, lvl)
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return tValidLevels[lvl] ~= nil
	end,
	cmnd = function(base_pos, mem, slot, lvl)
		slot = tonumber(slot or 1)
		local level = tValidLevels[lvl]
		signs_bot.place_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "f", level)
		return true
	end,
})
	
signs_bot.register_botcommand("place_left", {
	mod = "core",
	params = "<slot> <lvl>",	
	description = I("Place an item on the left side\n"..
		"<slot> is the inventory slot (1..8)\n"..
		"<lvl> is one of: -1   0   +1"),
	check = function(slot, lvl)
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return tValidLevels[lvl] ~= nil
	end,
	cmnd = function(base_pos, mem, slot, lvl)
		slot = tonumber(slot or 1)
		local level = tValidLevels[lvl]
		signs_bot.place_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "l", level)
		return true
	end,
})
	
signs_bot.register_botcommand("place_right", {
	mod = "core",
	params = "<slot> <lvl>",	
	description = I("Place an item on the right side\n"..
		"<slot> is the inventory slot (1..8)\n"..
		"<lvl> is one of: -1   0   +1"),
	check = function(slot, lvl)
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return tValidLevels[lvl] ~= nil
	end,
	cmnd = function(base_pos, mem, slot, lvl)
		slot = tonumber(slot or 1)
		local level = tValidLevels[lvl]
		signs_bot.place_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "r", level)
		return true
	end,
})
	
signs_bot.register_botcommand("dig_front", {
	mod = "core",
	params = "<slot> <lvl>",	
	description = I("Dig an item in front of the robot\n"..
		"<slot> is the inventory slot (1..8)\n"..
		"<lvl> is one of: -1   0   +1"),
	check = function(slot, lvl)
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return tValidLevels[lvl] ~= nil
	end,
	cmnd = function(base_pos, mem, slot, lvl)
		slot = tonumber(slot or 1)
		local level = tValidLevels[lvl]
		signs_bot.dig_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "f", level)
		return true
	end,
})

signs_bot.register_botcommand("dig_left", {
	mod = "core",
	params = "<slot> <lvl>",	
	description = I("Dig an item on the left side\n"..
		"<slot> is the inventory slot (1..8)\n"..
		"<lvl> is one of: -1   0   +1"),
	check = function(slot, lvl)
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return tValidLevels[lvl] ~= nil
	end,
	cmnd = function(base_pos, mem, slot, lvl)
		slot = tonumber(slot or 1)
		local level = tValidLevels[lvl]
		signs_bot.dig_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "l", level)
		return true
	end,
})

signs_bot.register_botcommand("dig_right", {
	mod = "core",
	params = "<slot> <lvl>",	
	description = I("Dig an item on the right side\n"..
		"<slot> is the inventory slot (1..8)\n"..
		"<lvl> is one of: -1   0   +1"),
	check = function(slot, lvl)
		slot = tonumber(slot or 1)
		if not slot or slot < 1 or slot > 8 then 
			return false 
		end
		return tValidLevels[lvl] ~= nil
	end,
	cmnd = function(base_pos, mem, slot, lvl)
		slot = tonumber(slot or 1)
		local level = tValidLevels[lvl]
		signs_bot.dig_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "r", level)
		return true
	end,
})

signs_bot.register_botcommand("rotate_item", {
	mod = "core",
	params = "<lvl> <steps>",	
	description = I("Rotate an item in front of the robot\n"..
		"<lvl> is one of:  -1   0   +1\n"..
		"<steps> is one of:  1   2   3"),
	check = function(lvl, steps)
		steps = tonumber(steps or 1)
		if not steps or steps < 1 or steps > 4 then
			return false
		end
		return tValidLevels[lvl] ~= nil
	end,
	cmnd = function(base_pos, mem, lvl, steps)
		local level = tValidLevels[lvl]
		steps = tonumber(steps or 1)
		signs_bot.rotate_item(base_pos, mem.robot_pos, mem.robot_param2, "f", level, steps)
		return true
	end,
})
	
signs_bot.register_botcommand("place_sign", {
	mod = "core",
	params = "<slot>",	
	description = I("Place a sign in front of the robot\ntaken from the signs inventory\n"..
		"<slot> is the inventory slot (1..6)"),
	check = function(slot)
		slot = tonumber(slot or 1)
		return slot and slot > 0 and slot < 7
	end,
	cmnd = function(base_pos, mem, slot)
		slot = tonumber(slot or 1)
		signs_bot.place_sign(base_pos, mem.robot_pos, mem.robot_param2, slot)
		return true
	end,
})
	
signs_bot.register_botcommand("place_sign_behind", {
	mod = "core",
	params = "<slot>",	
	description = I("Place a sign behind the robot\ntaken from the signs inventory\n"..
		"<slot> is the inventory slot (1..6)"),
	check = function(slot)
		slot = tonumber(slot or 1)
		return slot and slot > 0 and slot < 7
	end,
	cmnd = function(base_pos, mem, slot)
		slot = tonumber(slot or 1)
		signs_bot.place_sign_behind(base_pos, mem.robot_pos, mem.robot_param2, slot)
		return true
	end,
})
	
signs_bot.register_botcommand("dig_sign", {
	mod = "core",
	params = "<slot>",	
	description = I("Dig the sign in front of the robot\n"..
		"and add it to the signs inventory.\n"..
		"<slot> is the inventory slot (1..6)"),
	check = function(slot)
		slot = tonumber(slot or 1)
		return slot and slot > 0 and slot < 7
	end,
	cmnd = function(base_pos, mem, slot)
		slot = tonumber(slot or 1)
		signs_bot.dig_sign(base_pos, mem.robot_pos, mem.robot_param2, slot)
		return true
	end,
})
	
signs_bot.register_botcommand("trash_sign", {
	mod = "core",
	params = "<slot>",	
	description = I("Dig the sign in front of the robot\n"..
		"and add the cleared sign to\nthe item iventory.\n"..
		"<slot> is the inventory slot (1..8)"),
	check = function(slot)
		slot = tonumber(slot or 1)
		return slot and slot > 0 and slot < 9
	end,
	cmnd = function(base_pos, mem, slot)
		slot = tonumber(slot or 1)
		signs_bot.trash_sign(base_pos, mem.robot_pos, mem.robot_param2, slot)
		return true
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
	
	