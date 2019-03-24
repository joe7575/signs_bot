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
-- Inventory helper functions
--

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
function signs_bot.robot_take(base_pos, robot_pos, param2, num, slot)
	local pos1 = lib.next_pos(robot_pos, param2)
	if lib.not_protected(base_pos, pos1) then
		local src_inv, src_list = get_other_inv(pos1)
		local dst_inv, dst_list = get_own_inv(base_pos)
		local taken, rest, src_slot = lib.get_inv_items(src_inv, src_list, slot, num)
		if taken then
			if lib.put_inv_items(dst_inv, dst_list, slot, taken) then
				lib.release_inv_items(src_inv, src_list, src_slot, rest)
			end
		end
	end
end

-- From robot to chest
function signs_bot.robot_add(base_pos, robot_pos, param2, num, slot)
	local pos1 = lib.next_pos(robot_pos, param2)
	if lib.not_protected(base_pos, pos1) and not lib.is_air_like(base_pos, pos1) then
		local src_inv, src_list = get_own_inv(base_pos)
		local dst_inv, dst_list = get_other_inv(pos1)
		local taken, rest, src_slot = lib.get_inv_items(src_inv, src_list, slot, num)
		if taken then
			if lib.put_inv_items(dst_inv, dst_list, slot, taken) then
				lib.release_inv_items(src_inv, src_list, src_slot, rest)
			end
		end
	end
end
	

--
-- Place/dig items
--
function signs_bot.place_item(base_pos, robot_pos, param2, slot, dirs, level)
	for _,dir in ipairs(dirs) do
		local pos1, p2 = lib.work_pos(robot_pos, param2, dir)
		pos1.y = pos1.y + level
		if lib.not_protected(base_pos, pos1) and lib.is_air_like(base_pos, pos1) then
			local taken = lib.get_inv_item(base_pos, slot)
			if taken then
				lib.after_set_node(robot_pos, pos1, taken, M(base_pos):get_string("owner"), p2)
			end
		end
	end
end

function signs_bot.dig_item(base_pos, robot_pos, param2, slot, dirs, level)
	for _,dir in ipairs(dirs) do
		local pos1 = lib.work_pos(robot_pos, param2, dir)
		pos1.y = pos1.y + level
		local node = lib.get_node_lvm(pos1)
		if lib.not_protected(base_pos, pos1) and lib.is_simple_node(node) then
			minetest.remove_node(pos1)
			lib.put_inv_item(base_pos, slot, ItemStack(node.name))
		end
	end
end

function signs_bot.rotate_item(base_pos, robot_pos, param2, pos, level, steps)
	local pos1 = lib.work_pos(robot_pos, param2, pos)
	pos1.y = pos1.y + level
	local node = lib.get_node_lvm(pos1)
	if lib.not_protected(base_pos, pos1) and lib.is_simple_node(node) then
		local p2 = tRotations[node.param2] and tRotations[node.param2][steps]
		if p2 then
			minetest.swap_node(pos1, {name=node.name, param2=p2})
		end
	end
end
