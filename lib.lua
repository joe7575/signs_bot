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

signs_bot.lib = {}

local Face2Dir = {[0]=
	{x=0,  y=0,  z=1},
	{x=1,  y=0,  z=0},
	{x=0,  y=0, z=-1},
	{x=-1, y=0,  z=0},
	{x=0,  y=-1, z=0},
	{x=0,  y=1,  z=0}
}

-- Determine the next robot position based on the robot position, 
-- the robot param2.
function signs_bot.lib.next_pos(pos, param2)
	return vector.add(pos, Face2Dir[param2])
end

-- Determine the destination position based on the robot position, 
-- the robot param2, and a route table like : [0,0,3]
-- 0 = forward, 1 = right, 2 = backward, 3 = left
function signs_bot.lib.dest_pos(pos, param2, route)
	for _,dir in ipairs(route) do
		param2 = (param2 + dir) % 4
		pos = vector.add(pos, Face2Dir[param2])
	end
	return pos, param2
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

local get_node_lvm = signs_bot.lib.get_node_lvm

-- check if posA == air-like and posB == solid and no player around
function signs_bot.lib.check_pos(posA, posB)
	local nodeA = get_node_lvm(posA)
	local nodeB = get_node_lvm(posB)
	if not minetest.registered_nodes[nodeA.name].walkable and 
			minetest.registered_nodes[nodeB.name].walkable then
		local objects = minetest.get_objects_inside_radius(posA, 0.7)
		if #objects ~= 0 then
			minetest.sound_play('signs_bot_go_away', {pos = posA})
			return false
		else
			return true
		end
	end
	return false
end

-- Has to be checked before a node is placed
function signs_bot.lib.is_air_like(pos)
	local node = minetest.get_node(pos)
	if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].buildable_to then
		return true
	end
	return false
end

-- Has to be checked before a node is dug
function signs_bot.lib.is_simple_node(node)
	-- don't remove nodes with some intelligence
	return node.name ~= "air" and not minetest.registered_nodes[node.name].after_dig_node
end	

-- Check rights before node is dug or inventory is used
function signs_bot.lib.not_protected(base_pos, pos)
	local me = M(base_pos):get_string("owner")
	if minetest.is_protected(pos, me) then
		return false
	end
	local you = M(pos):get_string("owner")
	if you ~= "" and me ~= you then
		return false
	end
	return true
end

--
-- Try to get/put a number of items from/to any kind of inventory.
-- If slot is provided, start searching at that position, otherwise
-- start at slot 1.
function signs_bot.lib.get_inv_items(src_inv, src_list, slot, num)
	for idx = (slot or 1),src_inv:get_size(src_list) do
		local stack = src_inv:get_stack(src_list, idx)
		if stack:get_count() > 0 then
			local taken = stack:take_item(num or 1)
			src_inv:set_stack(src_list, idx, stack)
			return taken
		end
	end
end	

function signs_bot.lib.put_inv_items(dst_inv, dst_list, slot, items)
	for idx = (slot or 1),dst_inv:get_size(dst_list) do
		local stack = dst_inv:get_stack(dst_list, idx)
		if stack:item_fits(items) then
			stack:add_item(items)
			dst_inv:set_stack(dst_list, idx, stack)
			return true
		end
	end
	return false
end

-- In the case an inventory is full
function signs_bot.lib.drop_items(robot_pos, items)
	local pos = minetest.find_node_near(robot_pos, 1, {"air"})
	if pos then
		minetest.add_item(pos, items)
	end
end


--
--  Place/dig signs
--
function signs_bot.lib.place_sign(pos, sign, param2)				
	if sign:get_name() then
		minetest.set_node(pos, {name=sign:get_name(), param2=param2})
		minetest.registered_nodes[sign:get_name()].after_place_node(pos, nil, sign)
	end
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

local function activate_extender_node(pos)
	local node = get_node_lvm(pos)
	if node.name == "signs_bot:sensor_extender" then
		node.name = "signs_bot:sensor_extender_on"
		minetest.swap_node(pos, node)
		minetest.registered_nodes["signs_bot:sensor_extender_on"].after_place_node(pos)
	end
end

local NestedCounter = 0
function signs_bot.lib.activate_extender_nodes(pos, is_sensor)
	if is_sensor then 
		NestedCounter = 0 
	else
		NestedCounter = NestedCounter + 1
		if NestedCounter >= 5 then
			return
		end
	end
	activate_extender_node({x=pos.x-1, y=pos.y, z=pos.z})
	activate_extender_node({x=pos.x+1, y=pos.y, z=pos.z})
	activate_extender_node({x=pos.x, y=pos.y, z=pos.z-1})
	activate_extender_node({x=pos.x, y=pos.y, z=pos.z+1})
end
