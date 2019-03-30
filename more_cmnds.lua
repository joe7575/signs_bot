--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signs Bot: More commands

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib


signs_bot.register_botcommand("pickup_items", {
	mod = "core",
	params = "<slot>",	
	description = I("Pick up all objects\n"..
		"in a 3x3 field.\n"..
		"<slot> is the inventory slot (1..8)"),
	check = function(slot)
		slot = tonumber(slot)
		return slot and slot > 0 and slot < 9
	end,
	cmnd = function(base_pos, mem, slot)
		slot = tonumber(slot)
		local pos = lib.dest_pos(mem.robot_pos, mem.robot_param2, {0,0})
		for _, object in pairs(minetest.get_objects_inside_radius(pos, 1.5)) do
			local lua_entity = object:get_luaentity()
			if not object:is_player() and lua_entity and lua_entity.name == "__builtin:item" then
				local item = ItemStack(lua_entity.itemstring)
				local inv = minetest.get_inventory({type="node", pos=base_pos})
				if lib.put_inv_items(inv, "main", slot, item) then
					object:remove()
				end
			end
		end
		return true
	end,
})
	
signs_bot.register_botcommand("drop_items", {
	mod = "core",
	params = "<num> <slot>",	
	description = I("Drop items in front of the bot.\n"..
		"<slot> is the inventory slot (1..8)"),
	check = function(num, slot)
		num = tonumber(num or 1)
		if not num or num < 1 or num > 99 then 
			return false 
		end
		slot = tonumber(slot)
		return slot and slot > 0 and slot < 9
	end,
	cmnd = function(base_pos, mem, num, slot)
		num = tonumber(num or 1)
		slot = tonumber(slot)
		local pos = lib.dest_pos(mem.robot_pos, mem.robot_param2, {0})
		local items = lib.get_inv_items("", "main", slot, num)
		minetest.add_item(pos, items)
		return true
	end,
})

