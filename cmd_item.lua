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

local NODE_IO = minetest.global_exists("node_io")

local RegisteredInventories = {
	}
--
-- Move from/to inventories
--
-- From chest to robot
function signs_bot.robot_take(base_pos, robot_pos, param2, want_count, slot)
	local target_pos = lib.next_pos(robot_pos, param2)
	local node = lib.get_node_lvm(target_pos)
	local def = RegisteredInventories[node.name]	
	local owner = M(base_pos):get_string("owner")
	local taken
	if def and (not def.allow_take or def.allow_take(target_pos, nil, owner)) then
		local src_inv = minetest.get_inventory({type="node", pos=target_pos})
		taken = lib.get_inv_items(src_inv, def.take_listname, 1, want_count)
	elseif NODE_IO then
		local side = node_io.get_target_side(robot_pos, target_pos)
		local fake_player = lib.fake_player(owner)
		taken = node_io.take_item(target_pos, node, side, fake_player, nil, want_count)
	else
		return
	end
	if taken then
		local dst_inv = minetest.get_inventory({type="node", pos=base_pos})
		if not lib.put_inv_items(dst_inv, "main", slot, taken) then
			lib.drop_items(robot_pos, taken)
		end
	end
end

-- From robot to chest
function signs_bot.robot_put(base_pos, robot_pos, param2, num, slot)
	local src_inv = minetest.get_inventory({type="node", pos=base_pos})
	local taken = lib.get_inv_items(src_inv, "main", slot, num)
	if taken then
		local target_pos = lib.next_pos(robot_pos, param2)
		local node = lib.get_node_lvm(target_pos)
		local def = RegisteredInventories[node.name]
		local owner = M(base_pos):get_string("owner")
		
		if def and (not def.allow_put or def.allow_put(target_pos, taken, owner)) then
			local dst_inv = minetest.get_inventory({type="node", pos=target_pos})
			if not lib.put_inv_items(dst_inv, def.put_listname, 1, taken) then
				lib.drop_items(robot_pos, taken)
			end
		elseif NODE_IO then
			local side = node_io.get_target_side(robot_pos, target_pos)
			local fake_player = lib.fake_player(owner)
			local left_over = node_io.put_item(target_pos, node, side, fake_player, taken)
			if left_over:get_count() > 0 then
				lib.drop_items(robot_pos, left_over)
			end
		end
	end
end

-- From robot to furnace
function signs_bot.robot_put_fuel(base_pos, robot_pos, param2, num, slot)
	local src_inv = minetest.get_inventory({type="node", pos=base_pos})
	local taken = lib.get_inv_items(src_inv, "main", slot, num)
	if taken then
		local target_pos = lib.next_pos(robot_pos, param2)
		local node = lib.get_node_lvm(target_pos)
		local def = RegisteredInventories[node.name]
		local owner = M(base_pos):get_string("owner")
		
		if def and (not def.allow_fuel or def.allow_fuel(target_pos, taken, owner)) then
			local dst_inv = minetest.get_inventory({type="node", pos=target_pos})
			if not lib.put_inv_items(dst_inv, def.fuel_listname, 1, taken) then
				lib.drop_items(robot_pos, taken)
			end
		elseif NODE_IO then
			local side = node_io.get_target_side(robot_pos, target_pos)
			local fake_player = lib.fake_player(owner)
			local left_over = node_io.put_item(target_pos, node, side, fake_player, taken)
			if left_over:get_count() > 0 then
				lib.drop_items(robot_pos, left_over)
			end
		end
	end
end

function signs_bot.robot_take_cond(base_pos, robot_pos, param2, want_count, slot)
	local target_pos = lib.next_pos(robot_pos, param2)
	local node = lib.get_node_lvm(target_pos)
	local def = RegisteredInventories[node.name]	
	local owner = M(base_pos):get_string("owner")
	local taken
	if def and (not def.allow_take or def.allow_take(target_pos, nil, owner)) then
		local src_inv = minetest.get_inventory({type="node", pos=target_pos})
		taken = lib.get_inv_items_cond(src_inv, def.take_listname, 1, want_count)
	else
		return
	end
	if taken then
		local dst_inv = minetest.get_inventory({type="node", pos=base_pos})
		if not lib.put_inv_items(dst_inv, "main", slot, taken) then
			lib.drop_items(robot_pos, taken)
		end
	end
end

-- From robot to chest
function signs_bot.robot_put_cond(base_pos, robot_pos, param2, num, slot)
	local src_inv = minetest.get_inventory({type="node", pos=base_pos})
	local taken = lib.get_inv_items(src_inv, "main", slot, num)
	if taken then
		local target_pos = lib.next_pos(robot_pos, param2)
		local node = lib.get_node_lvm(target_pos)
		local def = RegisteredInventories[node.name]
		local owner = M(base_pos):get_string("owner")
		
		if def and (not def.allow_put or def.allow_put(target_pos, taken, owner)) then
			local dst_inv = minetest.get_inventory({type="node", pos=target_pos})
			if not lib.put_inv_items_cond(dst_inv, def.put_listname, 1, taken) then
				 lib.put_inv_items(src_inv, "main", slot, taken)
			end
		else
			lib.put_inv_items(src_inv, "main", slot, taken)
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
	
signs_bot.register_botcommand("cond_take_item", {
	mod = "item",
	params = "<num> <slot>",	
	description = I("Take <num> items from a chest like node\nand put it into the item inventory.\n"..
		"Take care that at least one more\nitem of this type is available.\n"..
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
		signs_bot.robot_take_cond(base_pos, mem.robot_pos, mem.robot_param2, num, slot)
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
		signs_bot.robot_put(base_pos, mem.robot_pos, mem.robot_param2, num, slot)
		return lib.DONE
	end,
})
	
signs_bot.register_botcommand("cond_add_item", {
	mod = "item",
	params = "<num> <slot>",	
	description = I("Add <num> items to a chest like node\ntaken from the item inventory,\n"..
		"but only if at least one item\nof this type is already available.\n"..
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
		signs_bot.robot_put_cond(base_pos, mem.robot_pos, mem.robot_param2, num, slot)
		return lib.DONE
	end,
})

signs_bot.register_botcommand("add_fuel", {
	mod = "item",
	params = "<num> <slot>",	
	description = I("Add <num> fuel to a furnace like node\ntaken from the item inventory.\n"..
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
		signs_bot.robot_put_fuel(base_pos, mem.robot_pos, mem.robot_param2, num, slot)
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
			if object:get_entity_name() == "minecart:cart" then
				object:punch(object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = {fleshy = 1},
				}, minetest.facedir_to_dir(mem.robot_param2))
				break -- start only one cart
			end
		end
		return lib.DONE
	end,
})

-- def is a table with following data:
--	{
--		put = {
--			allow_inventory_put = func(pos, stack, player_name), 
--			listname = "src",
--		},
--		take = {
--			allow_inventory_take = func(pos, stack, player_name),
--			listname = "dst",
		
--		fuel = {
--			allow_inventory_put = func(pos, stack, player_name), 
--			listname = "fuel",
--		},
--	}
function signs_bot.register_inventory(node_names, def)
	for _, name in ipairs(node_names) do
		RegisteredInventories[name] = {
			allow_put = def.put and def.put.allow_inventory_put,
			put_listname = def.put and def.put.listname,
			allow_take = def.take and def.take.allow_inventory_take,
			take_listname = def.take and def.take.listname,
			allow_fuel = def.fuel and def.fuel.allow_inventory_put,
			fuel_listname = def.fuel and def.fuel.listname,
		}
	end
end
