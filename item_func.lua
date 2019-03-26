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
		--minetest.global_exists("node_io")
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
	if lib.not_protected(base_pos, pos1) and not lib.is_air_like(pos1) then
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
		if lib.not_protected(base_pos, pos1) and lib.is_air_like(pos1) then
			local src_inv, src_list = get_own_inv(base_pos)
			local taken, rest, src_slot = lib.get_inv_items(src_inv, src_list, slot, 1)
			if taken then
				local name = taken:get_name()
				if name == "default:torch" then  
					name = "signs_bot:torch" 
				end
				local def = minetest.registered_nodes[name]
				if not def then return end
				if def.paramtype2 == "wallmounted" then
					local dir = minetest.facedir_to_dir(p2)
					local wdir = minetest.dir_to_wallmounted(dir)
					minetest.set_node(pos1, {name=name, param2=wdir})
				else
					minetest.set_node(pos1, {name=name, param2=p2})
				end
				lib.release_inv_items(src_inv, src_list, src_slot, rest)
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
			local dst_inv, dst_list = get_own_inv(base_pos)
			if lib.put_inv_items(dst_inv, dst_list, slot, ItemStack(node.name)) then
				minetest.remove_node(pos1)
			end
		end
	end
end

function signs_bot.rotate_item(base_pos, robot_pos, param2, dir, level, steps)
	local pos1 = lib.work_pos(robot_pos, param2, dir)
	pos1.y = pos1.y + level
	local node = lib.get_node_lvm(pos1)
	if lib.not_protected(base_pos, pos1) and lib.is_simple_node(node) then
		local p2 = tRotations[node.param2] and tRotations[node.param2][steps]
		if p2 then
			minetest.swap_node(pos1, {name=node.name, param2=p2})
		end
	end
end

minetest.register_node("signs_bot:torch", {
	description = "Bot torch",
	inventory_image = "default_torch_on_floor.png",
	wield_image = "default_torch_on_floor.png",
	drawtype = "nodebox",
	node_box = {
		type = "connected",
		fixed = {
			{-1/16, -3/16, -1/16, 1/16, 7/16, 1/16},
			--{-2/16,  4/16, -2/16, 2/16, 8/16, 2/16},
		},
		connect_bottom = {{-1/16, -8/16, -1/16, 1/16, 1/16, 1/16}},
		connect_front = {{-1/16, -1/16, -8/16, 1/16, 1/16, 1/16}},
		connect_left = {{-8/16, -1/16, -1/16, 1/16, 1/16, 1/16}},
		connect_back = {{-1/16, -1/16, -1/16, 1/16, 1/16, 8/16}},
		connect_right = {{-1/16, -1/16, -1/16, 8/16, 1/16, 1/16}},
	},
	tiles = { 
		-- up, down, right, left, back, front
		"signs_bot_torch_top.png", 
		"signs_bot_torch_bottom.png", 
		{
			image = "signs_bot_torch_animated.png", 
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 4.0,
			},
		},
		
	},
	connects_to = {
		"group:pane", "group:stone", "group:glass", "group:wood", "group:tree", 
		"group:bakedclay", "group:soil"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	liquids_pointable = false,
	light_source = 12,
	groups = {choppy=2, dig_immediate=3, flammable=1, attached_node=1, torch=1, not_in_creative_inventory=1},
	drop = "default:torch",
	sounds = default.node_sound_wood_defaults(),
})


