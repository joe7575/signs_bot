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
-- Move from/to inventories
--
-- From chest to robot
function signs_bot.robot_take(base_pos, robot_pos, param2, want_count, slot)
	local target_pos = lib.next_pos(robot_pos, param2)
	local side = node_io.get_target_side(robot_pos, target_pos)
	local node = lib.get_node_lvm(target_pos)
	local owner = M(base_pos):get_string("owner")
	local fake_player = lib.fake_player(owner)
	local taken = node_io.take_item(target_pos, node, side, fake_player, nil, want_count)
	if taken then
		local dst_inv = minetest.get_inventory({type="node", pos=base_pos})
		if not lib.put_inv_items(dst_inv, "main", slot, taken) then
			lib.drop_items(robot_pos, taken)
		end
	end
end

-- From robot to chest
function signs_bot.robot_add(base_pos, robot_pos, param2, num, slot)
	local target_pos = lib.next_pos(robot_pos, param2)
	local side = node_io.get_target_side(robot_pos, target_pos)
	local src_inv = minetest.get_inventory({type="node", pos=base_pos})
	local taken = lib.get_inv_items(src_inv, "main", slot, num)
	if taken then
		local node = lib.get_node_lvm(target_pos)
		local owner = M(base_pos):get_string("owner")
		local fake_player = lib.fake_player(owner)
		local left_over = node_io.put_item(target_pos, node, side, fake_player, taken)	
		if left_over:get_count() > 0 then
			lib.drop_items(robot_pos, left_over)
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
		return lib.DONE
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
		return lib.DONE
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
		for _, object in pairs(minetest.get_objects_inside_radius(pos, 2)) do
			local lua_entity = object:get_luaentity()
			if not object:is_player() and lua_entity and lua_entity.name == "__builtin:item" then
				local item = ItemStack(lua_entity.itemstring)
				local inv = minetest.get_inventory({type="node", pos=base_pos})
				if lib.put_inv_items(inv, "main", slot, item) then
					object:remove()
				end
			end
		end
		return lib.DONE
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
		return lib.DONE
	end,
})

signs_bot.register_botcommand("punch_cart", {
	mod = "item",
	params = "",	
	description = I("Punch a rail cart to start it"),
	cmnd = function(base_pos, mem)
		local pos = lib.dest_pos(mem.robot_pos, mem.robot_param2, {0})
		for _, object in pairs(minetest.get_objects_inside_radius(pos, 2)) do
			if object:get_entity_name() == "carts:cart" then
				local owner = M(base_pos):get_string("owner")
				local player = minetest.get_player_by_name(owner)
				if player then
					object:punch(player, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = {fleshy = 1},
					}, nil)
				end
			end
		end
		return lib.DONE
	end,
})

