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


--
-- Inventory helper functions
--

local function get_other_inv(pos, take, is_fuel)
	local inv = minetest.get_inventory({type="node", pos=pos})
	if is_fuel and inv:get_list("fuel") then
		return inv, "fuel"
	elseif take and inv:get_list("dst") then
		return inv, "dst"
	elseif inv:get_list("src") then
		return inv, "src"
	elseif inv:get_list("main") then
		return inv, "main"
	end
end

local function get_own_inv(pos, take)
	return minetest.get_inventory({type="node", pos=pos}), "main"
end

-- Get the given number of items from the inv. The position within the list
-- is random so that different item stacks will be considered.
-- Returns nil if ItemList is empty.
local function get_items(inv, listname, num)
	if inv:is_empty(listname) then
		return nil
	end
	local size = inv:get_size(listname)
	local startpos = math.random(1, size)
	for idx = startpos, startpos+size do
		idx = (idx % size) + 1
		local items = inv:get_stack(listname, idx)
		if items:get_count() > 0 then
			local taken = items:take_item(num)
			inv:set_stack(listname, idx, items)
			return taken
		end
	end
	return nil
end

-- Put the given stack into the given ItemList.
-- Function returns false if ItemList is full.
local function put_items(inv, listname, stack)
	if inv:room_for_item(listname, stack) then
		inv:add_item(listname, stack)
		return true
	end
	return false
end

--
-- Move from/to inventories
--
-- From chest to robot
function signs_bot.robot_take(base_pos, robot_pos, param2, num, slot)
	local pos1 = lib.next_pos(robot_pos, param2)
	if lib.not_protected(base_pos, pos1) then
		local me = M(base_pos):get_string("owner")
		local you = M(pos1):get_string("owner")
		if you == "" or me == you then
			--minetest.global_exists("node_io")
			local src_inv, src_list = get_other_inv(pos1, true)
			local dst_inv, dst_list = get_own_inv(base_pos)
			local taken = get_items(src_inv, src_list, num)
			if taken then
				if not lib.put_inv_items(dst_inv, dst_list, slot, taken) then
					lib.drop_items(robot_pos, taken)
				end
			end
		end
	end
end

-- From robot to chest
function signs_bot.robot_add(base_pos, robot_pos, param2, num, slot, is_fuel)
	local pos1 = lib.next_pos(robot_pos, param2)
	if lib.not_protected(base_pos, pos1) and not lib.is_air_like(pos1) then
		local me = M(base_pos):get_string("owner")
		local you = M(pos1):get_string("owner")
		if you == "" or me == you then
			local src_inv, src_list = get_own_inv(base_pos)
			local dst_inv, dst_list = get_other_inv(pos1, false, is_fuel)
			local taken = lib.get_inv_items(src_inv, src_list, slot, num)
			if taken then
				if not put_items(dst_inv, dst_list, taken) then
					lib.drop_items(robot_pos, taken)
				end
			end
		end
	end
end

signs_bot.register_botcommand("take_item", {
	mod = "item",
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
	mod = "item",
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
	mod = "item",
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

signs_bot.register_botcommand("pickup_items", {
	mod = "item",
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
	mod = "item",
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
		local inv = minetest.get_inventory({type="node", pos=base_pos})
		local items = lib.get_inv_items(inv, "main", slot, num)
		minetest.add_item(pos, items)
		return true
	end,
})

