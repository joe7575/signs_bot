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

local next_pos = signs_bot.lib.next_pos
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
	local node = minetest.get_node(pos)
	if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].buildable_to then
		return true
	end
	return false
end
local is_air_like = signs_bot.lib.is_air_like

function signs_bot.lib.is_simple_node(node)
	-- don't remove nodes with some intelligence
	return node.name ~= "air" and not minetest.registered_nodes[node.name].after_dig_node
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


--
--  Place/dig signs
--
function signs_bot.lib.place_sign(pos, sign, param2)				
	minetest.set_node(pos, {name=sign:get_name(), param2=param2})
	minetest.registered_nodes[sign:get_name()].after_place_node(pos, nil, sign)
end

function signs_bot.lib.dig_sign(pos, node)
	node = node or get_node_lvm(pos)
	local nmeta = minetest.get_meta(pos)
	local cmnd = nmeta:get_string("signs_bot_cmnd")
	local sign
	if cmnd ~= "" then
		if node.name == "signs_bot:sign_cmnd" then
			local err_code = nmeta:get_int("err_code")
			local err_msg = nmeta:get_string("err_msg")
			local name = nmeta:get_string("sign_name")
			sign = ItemStack("signs_bot:sign_cmnd")
			local smeta = sign:get_meta()
			smeta:set_string("cmnd", cmnd)
			smeta:set_int("err_code", err_code)
			smeta:set_string("err_msg", err_msg)
			smeta:set_string("description", name)
		else
			sign = ItemStack(node.name)
		end
		minetest.remove_node(pos)
		return sign
	end
end
