--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Farming
]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local function planting(base_pos, pos, stack)
	if lib.not_protected(base_pos, pos) and lib.is_air_like(pos) then
		local item = signs_bot.FarmingSeed[stack:get_name()]
		print("planting", stack:get_name(), dump(signs_bot.FarmingSeed[stack:get_name()]))
		if item and item.seed then
			minetest.set_node(pos, {name = item.seed, paramtype2 = "wallmounted", param2 = 1})
			if item.t1 ~= nil then 
				-- We have to simulate "on_place" and start the timer by hand
				-- because the after_place_node function checks player rights and can't therefore
				-- be used.
				minetest.get_node_timer(pos):start(math.random(item.t1, item.t2))
			end			
			return true
		end
	end
	return false
end	

local function harvesting(base_pos, pos, inv, slot)
	if lib.not_protected(base_pos, pos) then
		local node = minetest.get_node_or_nil(pos)
		local item = signs_bot.FarmingCrop[node.name]
		if item and item.inv_crop then
			minetest.remove_node(pos)
			lib.put_inv_items(inv, "main", slot, ItemStack(item.inv_crop))
			if item.inv_seed then
				lib.put_inv_items(inv, "main", slot, ItemStack(item.inv_seed))
			end
		end
	end
end
			
signs_bot.register_botcommand("plant_seed", {
	mod = "core",
	params = "<slot>",	
	description = I("Plant farming seeds\nin front of the robot"),
	check = function(slot)
		slot = tonumber(slot)
		return slot and slot > 0 and slot < 9
	end,
	cmnd = function(base_pos, mem, slot)
		slot = tonumber(slot)
		local pos = lib.dest_pos(mem.robot_pos, mem.robot_param2, {0})
		local inv = minetest.get_inventory({type="node", pos=base_pos})
		local item = lib.get_inv_items(inv, "main", slot, 1)
		if item then
			if not planting(base_pos, pos, item) then
				lib.put_inv_items(inv, "main", slot, item)
			end
		end
		return true
	end,
})

signs_bot.register_botcommand("harvest", {
	mod = "core",
	params = "<slot>",	
	description = I("Harvest farming products\nin front of the robot"),
	check = function(slot)
		slot = tonumber(slot)
		return slot and slot > 0 and slot < 9
	end,
	cmnd = function(base_pos, mem, slot)
		slot = tonumber(slot)
		local pos = lib.dest_pos(mem.robot_pos, mem.robot_param2, {0})
		local inv = minetest.get_inventory({type="node", pos=base_pos})
		harvesting(base_pos, pos, inv, slot)
		return true
	end,
})

