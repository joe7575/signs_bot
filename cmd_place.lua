--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Bot place/remove commands

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local tValidLevels = {["-1"] = -1, ["0"] = 0, ["+1"] = 1}

-- for items with paramtype2 = "facedir"
local tRotations = {
	[0] = {8,20,4},
	[1] = {16,20,12},
	[2] = {4,20,8},
	[3] = {12,20,16},
}

local Dir2Route = {r={0,1}, f={0}, l={0,3}, b={2}}

local function get_own_inv(pos)
	return minetest.get_inventory({type="node", pos=pos}), "main"
end
	
--
-- Place/dig items
--
local function place_item(base_pos, robot_pos, param2, slot, dir, level)
	local pos1, p2 = lib.dest_pos(robot_pos, param2, Dir2Route[dir])
	pos1.y = pos1.y + level
	if lib.not_protected(base_pos, pos1) and lib.is_air_like(pos1) then
		local src_inv, src_list = get_own_inv(base_pos)
		local taken = lib.get_inv_items(src_inv, src_list, slot, 1)
		if taken then
			local name = taken:get_name()
			if name == "default:torch" then  
				name = "signs_bot:torch" 
			end
			local def = minetest.registered_nodes[name]
			if not def then return end
			if def.paramtype2 == "wallmounted" then
				local dir = minetest.facedir_to_dir(p2)
				local wdir = minetest.dir_to_wallmounted(dir)
				minetest.set_node(pos1, {name=name, param2=wdir})
			elseif dir == "b" then
				minetest.set_node(pos1, {name=name, param2=param2})
			else
				minetest.set_node(pos1, {name=name, param2=p2})
				minetest.check_single_for_falling(pos1)
			end
		end
	end
end

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
		place_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "f", level)
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
		place_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "l", level)
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
		place_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "r", level)
		return true
	end,
})

local function dig_item(base_pos, robot_pos, param2, slot, dir, level)
	local pos1 = lib.dest_pos(robot_pos, param2, Dir2Route[dir])
	pos1.y = pos1.y + level
	local node = lib.get_node_lvm(pos1)
	if lib.not_protected(base_pos, pos1) and lib.is_simple_node(node) then
		local dst_inv, dst_list = get_own_inv(base_pos)
		if lib.put_inv_items(dst_inv, dst_list, slot, ItemStack(node.name)) then
			minetest.remove_node(pos1)
		end
	end
end

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
		dig_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "f", level)
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
		dig_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "l", level)
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
		dig_item(base_pos, mem.robot_pos, mem.robot_param2, slot, "r", level)
		return true
	end,
})

local function rotate_item(base_pos, robot_pos, param2, dir, level, steps)
	local pos1 = lib.dest_pos(robot_pos, param2, Dir2Route[dir])
	pos1.y = pos1.y + level
	local node = lib.get_node_lvm(pos1)
	if lib.not_protected(base_pos, pos1) and lib.is_simple_node(node) then
		local p2 = tRotations[node.param2] and tRotations[node.param2][steps]
		if p2 then
			minetest.swap_node(pos1, {name=node.name, param2=p2})
		end
	end
end

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
		rotate_item(base_pos, mem.robot_pos, mem.robot_param2, "f", level, steps)
		return true
	end,
})
	
-- Simplified torch which can be placed w/o a fake player
minetest.register_node("signs_bot:torch", {
	description = "Bot torch",
	inventory_image = "default_torch_on_floor.png",
	wield_image = "default_torch_on_floor.png",
	drawtype = "nodebox",
	node_box = {
		type = "connected",
		fixed = {
			{-1/16, -3/16, -1/16, 1/16, 7/16, 1/16},
			--{-2/16,  4/16, -2/16, 2/16, 8/16, 2/16},
		},
		connect_bottom = {{-1/16, -8/16, -1/16, 1/16, 1/16, 1/16}},
		connect_front = {{-1/16, -1/16, -8/16, 1/16, 1/16, 1/16}},
		connect_left = {{-8/16, -1/16, -1/16, 1/16, 1/16, 1/16}},
		connect_back = {{-1/16, -1/16, -1/16, 1/16, 1/16, 8/16}},
		connect_right = {{-1/16, -1/16, -1/16, 8/16, 1/16, 1/16}},
	},
	tiles = { 
		-- up, down, right, left, back, front
		"signs_bot_torch_top.png", 
		"signs_bot_torch_bottom.png", 
		{
			image = "signs_bot_torch_animated.png", 
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 4.0,
			},
		},
		
	},
	connects_to = {
		"group:pane", "group:stone", "group:glass", "group:wood", "group:tree", 
		"group:bakedclay", "group:soil"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	liquids_pointable = false,
	light_source = 12,
	groups = {choppy=2, dig_immediate=3, flammable=1, attached_node=1, torch=1, not_in_creative_inventory=1},
	drop = "default:torch",
	sounds = default.node_sound_wood_defaults(),
})


