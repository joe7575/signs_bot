--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signs Bot: Robot inventory related functions

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local lib = signs_bot.lib

local NUM_ITEMS = 8

-- Convert command pos into internal dirs
local tPos2Dir = {l = "l", r = "r", L = "l", R = "l", f = "f", F = "f"}
local tPos2Dirs = {["2"] = {"l","r"}, ["3"] = {"l","f","r"}, l = {"l"}, r = {"r"}, L = {"l"}, R = {"l"}, f = {"f"}, F = {"f"}}
local tValidLevels = {["-1"] = -1, ["0"] = 0, ["+1"] = 1}
local tValidSlots = {["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7, ["8"] = 8}
local tValidSteps = {["1"] = 1, ["2"] = 2, ["3"] = 3}

local tRotations = {
	[0] = {8,20,4},
	[1] = {16,20,12},
	[2] = {4,20,8},
	[3] = {12,20,16},
}

local Inventories = {
	["tubelib:distributor"] = {take = "src", add = "src"},
	["tubelib_addons1:harvester_base"] = {take = "main", add = "fuel"},
	["tubelib_addons1:quarry"] = {take = "main", add = "fuel"},
	["tubelib_addons1:quarry_active"] = {take = "main", add = "fuel"},
	["default:chest_locked"] = {},
	["default:chest_locked_open"] = {},
	
--	[""] = {take = "", add = ""},
--	[""] = {take = "", add = ""},
--	[""] = {take = "", add = ""},
}

--
-- Determine inventory slot number of not predefined
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
-- Get/put one item from/to the robot inventory
-- 
local function get_inv_item(base_pos, slot)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	local stack = inv:get_stack("main", slot or get_not_empty_slot(inv, "main"))
	local taken = stack:take_item(1)
	if taken:get_count() == 1 then
		inv:set_stack("main", slot, stack)
		return taken
	end
end
			
local function put_inv_item(base_pos, slot, item)
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
	return false
end

--
-- Try to get/put a number of items from/to any kind of inventory
--
local function get_inv_items(src_inv, src_list, slot)
	slot = slot or get_not_empty_slot(src_inv, src_list)
	if slot then
		local stack = src_inv:get_stack(src_list, slot)
		local taken = stack:take_item(NUM_ITEMS)
		return taken, stack, slot
	end
end	

local function put_inv_items(dst_inv, dst_list, slot, taken)
	slot = slot or get_not_full_slot(dst_inv, dst_list, taken)
	if slot then
		local stack = dst_inv:get_stack(dst_list, slot)
		stack:add_item(taken)
		dst_inv:set_stack(dst_list, slot, stack)
		return true
	end
	return false
end

local function release_inv_items(src_inv, src_list, slot, stack)
	src_inv:set_stack(src_list, slot, stack)
end

--
-- Protection, inventory helper functions
--
local function not_protected(base_pos, pos)
	local owner = M(base_pos):get_string("owner")
	return not minetest.is_protected(pos, owner)
end

local function get_other_inv(pos, take)
	local inv = minetest.get_inventory({type="node", pos=pos})
	if take and inv:get_list("dst") then
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


--
-- Move from/to inventories
--
-- From chest to robot
function signs_bot.robot_take(base_pos, robot_pos, param2, slot)
	local pos1 = lib.next_pos(robot_pos, param2)
	slot = tValidSlots[slot]
	if not_protected(base_pos, pos1) then
		local src_inv, src_list = get_other_inv(pos1)
		local dst_inv, dst_list = get_own_inv(base_pos)
		local taken, rest, src_slot = get_inv_items(src_inv, src_list, slot)
		if taken then
			if put_inv_items(dst_inv, dst_list, slot, taken) then
				release_inv_items(src_inv, src_list, src_slot, rest)
			end
		end
	end
end

-- From robot to chest
function signs_bot.robot_add(base_pos, robot_pos, param2, slot)
	local pos1 = lib.next_pos(robot_pos, param2)
	slot = tValidSlots[slot]
	if not_protected(base_pos, pos1) then
		local src_inv, src_list = get_own_inv(base_pos)
		local dst_inv, dst_list = get_other_inv(pos1)
		local taken, rest, src_slot = get_inv_items(src_inv, src_list, slot)
		if taken then
			if put_inv_items(dst_inv, dst_list, slot, taken) then
				release_inv_items(src_inv, src_list, src_slot, rest)
			end
		end
	end
end
	

--
-- Place/dig items
--
function signs_bot.place_item(base_pos, robot_pos, param2, slot, item_pos, level)
	local owner = M(base_pos):get_string("owner")
	local dirs = tPos2Dirs[item_pos or 'f']
	local lvl = tValidLevels[level or "0"]
	slot = tValidSlots[slot]
	if dirs and lvl then
		for _,dir in ipairs(dirs) do
			local pos1, p2 = lib.work_pos(robot_pos, param2, dir)
			pos1.y = pos1.y + lvl
			print("pos1", S(pos1))
			if not minetest.is_protected(pos1, owner) and lib.is_air_like(pos1) then
				local taken = get_inv_item(base_pos, slot)
				if taken then
					lib.after_set_node(robot_pos, pos1, taken, owner, p2)
				end
			end
		end
	end
end

function signs_bot.dig_item(base_pos, robot_pos, param2, slot, item_pos, level)
	local owner = M(base_pos):get_string("owner")
	local dirs = tPos2Dirs[item_pos or 'f']
	local lvl = tValidLevels[level or "0"]
	slot = tValidSlots[slot]
	if dirs and lvl then
		for _,dir in ipairs(dirs) do
			local pos1 = lib.work_pos(robot_pos, param2, dir)
			pos1.y = pos1.y + lvl
			local node = lib.get_node_lvm(pos1)
			if not minetest.is_protected(pos1, owner) and lib.is_simple_node(node) then
				minetest.remove_node(pos1)
				put_inv_item(base_pos, slot, ItemStack(node.name))
			end
		end
	end
end

function signs_bot.rotate_item(base_pos, robot_pos, param2, item_pos, level, steps)
	local owner = M(base_pos):get_string("owner")
	local lvl = tValidLevels[level or "0"]
	local dir = tPos2Dir[item_pos or 'f']
	steps = tValidSteps[steps or '1']
	if lvl and steps and dir then
		local pos1 = lib.work_pos(robot_pos, param2, dir)
		pos1.y = pos1.y + lvl
		local node = lib.get_node_lvm(pos1)
		if not minetest.is_protected(pos1, owner) and lib.is_simple_node(node) then
			local p2 = tRotations[node.param2] and tRotations[node.param2][steps]
			if p2 then
				minetest.swap_node(pos1, {name=node.name, param2=p2})
			end
		end
	end
end
