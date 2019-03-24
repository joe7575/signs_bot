--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signs Bot: Library with helper functions

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

signs_bot.lib = {}

local Face2Dir = {[0]=
	{x=0,  y=0,  z=1},
	{x=1,  y=0,  z=0},
	{x=0,  y=0, z=-1},
	{x=-1, y=0,  z=0},
	{x=0,  y=-1, z=0},
	{x=0,  y=1,  z=0}
}

local Dir2Offs = {r=1, f=0, l=3, b=2}


-- Determine the next robot position based on the robot position, 
-- the robot param2.
function signs_bot.lib.next_pos(pos, param2)
	return vector.add(pos, Face2Dir[param2])
end

-- Determine the work position based on the robot position, 
-- the robot param2, and the dir: l(eft), r(ight), f(ront)
function signs_bot.lib.work_pos(pos, param2, dir)
	if dir == "r" or dir == "l" then
		pos = vector.add(pos, Face2Dir[param2])
	end
	param2 = (param2 + Dir2Offs[dir]) % 4
	return vector.add(pos, Face2Dir[param2]), param2
end

function signs_bot.lib.get_node_lvm(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then
		return node
	end
	local vm = minetest.get_voxel_manip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()
	local area = VoxelArea:new({MinEdge = MinEdge, MaxEdge = MaxEdge})
	local idx = area:index(pos.x, pos.y, pos.z)
	node = {
		name = minetest.get_name_from_content_id(data[idx]),
		param2 = param2_data[idx]
	}
	return node
end

function signs_bot.lib.fake_player(pos, name)
	return {
		get_player_name = function() return name end,
		is_player = function() return false end,
		get_player_control = function() return {jump=false, right=false, left=false, 
				LMB=false, RMB=false, sneak=false, aux1=false, down=false, up=false} end,
		get_pos = function() return pos end,
	}
end

local next_pos = signs_bot.lib.next_pos
local fake_player = signs_bot.lib.fake_player
local get_node_lvm = signs_bot.lib.get_node_lvm

-- check if posA == air-like and posB == solid and no player around
function signs_bot.lib.check_pos(posA, posB)
	local nodeA = get_node_lvm(posA)
	local nodeB = get_node_lvm(posB)
	if not minetest.registered_nodes[nodeA.name].walkable and 
			minetest.registered_nodes[nodeB.name].walkable then
		local objects = minetest.get_objects_inside_radius(posA, 1)
		if #objects ~= 0 then
			minetest.sound_play('signs_bot_go_away', {pos = posA})
			return false
		else
			return true
		end
	end
	return false
end

function signs_bot.lib.is_air_like(pos)
	local node = get_node_lvm(pos)
	if minetest.registered_nodes[node.name].walkable then
		return false
	end
	return true
end
local is_air_like = signs_bot.lib.is_air_like

function signs_bot.lib.is_simple_node(node)
	-- don't remove nodes with some intelligence
	return node.name ~= "air" and not minetest.registered_nodes[node.name].after_dig_node
end	

function signs_bot.lib.place_node(robot_pos, pos, itemstack, owner, param2)
	local name = itemstack:get_name()
	print("place_node", name)
	local def = minetest.registered_nodes[name]
	if not def then
		return false
	end
--	if def.on_place then
--		local under = next_pos(pos, param2)
--		if is_air_like(under) then
--			under = {x=pos.x, y=pos.y-1, z=pos.z}
--		end
--		local pointed_thing = {type="node", under=under, above=pos}
--		local fake_player = fake_player(pos, owner)
--		--def.on_place(itemstack, fake_player, pointed_thing)
--		if pcall(def.on_place, itemstack, fake_player, pointed_thing) then return end
--	end
	if def and def.paramtype2 == "wallmounted" then
		local dir = minetest.facedir_to_dir(param2)
		local wdir = minetest.dir_to_wallmounted(dir)
		minetest.set_node(pos, {name=name, param2=wdir})
	else
		minetest.set_node(pos, {name=name, param2=param2})
	end
end

function signs_bot.lib.not_protected(base_pos, pos)
	local owner = M(base_pos):get_string("owner")
	if minetest.is_protected(pos, owner) then
		signs_bot.output(base_pos, I("Error: Protected or invalid position"))
		return false
	end
	return true
end

--
-- Determine inventory slot number if not predefined
--
local function get_not_empty_slot(inv, listname)
	for idx,stack in ipairs(inv:get_list(listname)) do
		if stack:get_count() > 0 then
			return idx
		end
	end
end

-- Determine next not-full inventory list number
local function get_not_full_slot(inv, listname, item)
	for idx,stack in ipairs(inv:get_list(listname)) do
		if stack:item_fits(item) then
			return idx
		end
	end
end


--
-- Get/put exactly one item from/to the robot inventory and
-- generate an error if not possible.
-- 
function signs_bot.lib.get_inv_item(base_pos, slot)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	local stack = inv:get_stack("main", slot or get_not_empty_slot(inv, "main"))
	local taken = stack:take_item(1)
	if taken:get_count() == 1 then
		inv:set_stack("main", slot, stack)
		return taken
	end
	signs_bot.output(base_pos, I("Error: Item inventory is empty"))
end
			
function signs_bot.lib.put_inv_item(base_pos, slot, item)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	slot = slot or get_not_full_slot(inv, "main", item)
	if slot then
		local stack = inv:get_stack("main", slot)
		local leftovers = stack:add_item(item)
		if leftovers:get_count() == 0 then
			inv:set_stack("main", slot, stack)
			return true
		end
	end
	signs_bot.output(base_pos, I("Error: Item inventory is full"))
	return false
end

--
-- Try to get/put a number of items from/to any kind of inventory.
--
function signs_bot.lib.get_inv_items(src_inv, src_list, slot, num)
	slot = slot or get_not_empty_slot(src_inv, src_list)
	if slot then
		local stack = src_inv:get_stack(src_list, slot)
		local taken = stack:take_item(num)
		return taken, stack, slot
	end
end	

function signs_bot.lib.put_inv_items(dst_inv, dst_list, slot, taken)
	slot = slot or get_not_full_slot(dst_inv, dst_list, taken)
	if slot then
		local stack = dst_inv:get_stack(dst_list, slot)
		stack:add_item(taken)
		dst_inv:set_stack(dst_list, slot, stack)
		return true
	end
	return false
end

function signs_bot.lib.release_inv_items(src_inv, src_list, slot, stack)
	src_inv:set_stack(src_list, slot, stack)
end
